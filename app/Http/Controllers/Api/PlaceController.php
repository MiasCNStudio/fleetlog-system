<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Http;

class PlaceController extends Controller
{
    public function config(): JsonResponse
    {
        $googleKey = (string) config('services.google_maps.key', '');

        return response()->json([
            'provider' => $googleKey !== '' ? 'google' : 'hybrid',
            'has_google_key' => $googleKey !== '',
        ]);
    }

    public function search(Request $request): JsonResponse
    {
        $q = trim((string) $request->query('q', ''));
        if (mb_strlen($q) < 2) {
            return response()->json(['data' => [], 'provider' => 'none']);
        }

        // 1. Coordenadas directas ("13.6616, -89.2527") o enlace compartido de Google Maps
        $direct = $this->resolveDirectLocationInput($q);
        if ($direct !== null) {
            return response()->json(['data' => [$direct], 'provider' => $direct['provider'] ?? 'direct']);
        }

        // 2. Si hay clave oficial de Google Maps configurada, usar Places Text Search
        $googleKey = (string) config('services.google_maps.key', '');
        if ($googleKey !== '') {
            try {
                $response = Http::timeout(6)->get('https://maps.googleapis.com/maps/api/place/textsearch/json', [
                    'query' => $q,
                    'language' => 'es',
                    'key' => $googleKey,
                ]);

                if ($response->ok() && in_array($response->json('status'), ['OK', 'ZERO_RESULTS'], true)) {
                    $items = collect($response->json('results', []))
                        ->take(8)
                        ->map(fn (array $row) => [
                            'name' => $row['name'] ?? $q,
                            'address' => $row['formatted_address'] ?? ($row['name'] ?? ''),
                            'latitude' => (float) ($row['geometry']['location']['lat'] ?? 0),
                            'longitude' => (float) ($row['geometry']['location']['lng'] ?? 0),
                            'place_id' => $row['place_id'] ?? null,
                            'provider' => 'google',
                        ])
                        ->filter(fn (array $item) => $item['latitude'] !== 0.0 || $item['longitude'] !== 0.0)
                        ->values();

                    return response()->json(['data' => $items, 'provider' => 'google']);
                }
            } catch (\Throwable) {
                /* fallback a proveedores híbridos */
            }
        }

        // 3. Sin Google API key: combinar ArcGIS World Geocoder (excelente para hoteles, comercios y POI en SV)
        // + OpenStreetMap Nominatim (excelente para direcciones, instituciones públicas y centros comerciales)
        $arcgisItems = $this->searchArcGis($q);
        $osmItems = $this->searchNominatim($q);

        $merged = $this->mergeAndDeduplicatePlaces($arcgisItems, $osmItems)->take(8)->values();

        return response()->json([
            'data' => $merged,
            'provider' => $arcgisItems->isNotEmpty() ? 'arcgis+osm' : 'osm',
        ]);
    }

    public function reverse(Request $request): JsonResponse
    {
        $lat = $request->query('lat');
        $lng = $request->query('lng');

        if (! is_numeric($lat) || ! is_numeric($lng)) {
            return response()->json(['data' => null], 422);
        }

        $resolved = $this->reverseLookup((float) $lat, (float) $lng);

        return response()->json(['data' => $resolved]);
    }

    private function reverseLookup(float $latF, float $lngF): ?array
    {
        $googleKey = (string) config('services.google_maps.key', '');
        if ($googleKey !== '') {
            try {
                $response = Http::timeout(6)->get('https://maps.googleapis.com/maps/api/geocode/json', [
                    'latlng' => "{$latF},{$lngF}",
                    'language' => 'es',
                    'key' => $googleKey,
                ]);

                if ($response->ok() && $response->json('status') === 'OK') {
                    $first = $response->json('results.0');
                    if ($first) {
                        $formatted = (string) ($first['formatted_address'] ?? '');
                        $shortName = trim(explode(',', $formatted)[0]);

                        return [
                            'name' => $shortName ?: $formatted,
                            'address' => $formatted,
                            'latitude' => $latF,
                            'longitude' => $lngF,
                            'place_id' => $first['place_id'] ?? null,
                            'provider' => 'google',
                        ];
                    }
                }
            } catch (\Throwable) {
                /* fallback a OSM */
            }
        }

        try {
            $response = Http::timeout(8)
                ->withHeaders([
                    'User-Agent' => 'FleetlogSystem/1.0 (https://fleetlog.miascn.org)',
                    'Accept-Language' => 'es',
                ])
                ->get('https://nominatim.openstreetmap.org/reverse', [
                    'lat' => $latF,
                    'lon' => $lngF,
                    'format' => 'jsonv2',
                ]);

            if (! $response->ok()) {
                return null;
            }

            $row = $response->json() ?? [];
            $display = (string) ($row['display_name'] ?? '');
            $shortName = trim((string) ($row['name'] ?? ''));
            if ($shortName === '' && $display !== '') {
                $shortName = trim(explode(',', $display)[0]);
            }

            return [
                'name' => $shortName ?: 'Ubicación seleccionada',
                'address' => $display,
                'latitude' => $latF,
                'longitude' => $lngF,
                'place_id' => isset($row['place_id']) ? 'osm:'.$row['place_id'] : null,
                'provider' => 'osm',
            ];
        } catch (\Throwable) {
            return null;
        }
    }

    private function resolveDirectLocationInput(string $q): ?array
    {
        // A) Coordenadas escritas directamente: "13.6615996, -89.2527309"
        if (preg_match('/^\s*(-?\d{1,2}\.\d{3,})\s*[,;\s]\s*(-?\d{1,3}\.\d{3,})\s*$/', $q, $m)) {
            $lat = (float) $m[1];
            $lng = (float) $m[2];
            if ($lat >= -90 && $lat <= 90 && $lng >= -180 && $lng <= 180) {
                $rev = $this->reverseLookup($lat, $lng);

                return $rev ?? [
                    'name' => sprintf('Punto %.5f, %.5f', $lat, $lng),
                    'address' => sprintf('%.6f, %.6f', $lat, $lng),
                    'latitude' => $lat,
                    'longitude' => $lng,
                    'place_id' => null,
                    'provider' => 'coords',
                ];
            }
        }

        // B) URL compartida de Google Maps (completa o acortada)
        if (preg_match('/https?:\/\/[^\s]+/i', $q, $urlMatch)) {
            $rawUrl = $urlMatch[0];
            $host = strtolower((string) parse_url($rawUrl, PHP_URL_HOST));
            $allowedHosts = [
                'maps.app.goo.gl',
                'goo.gl',
                'maps.google.com',
                'www.google.com',
                'google.com',
            ];

            if (! in_array($host, $allowedHosts, true)) {
                return null;
            }

            $finalUrl = $rawUrl;
            $shortName = '';

            if (in_array($host, ['maps.app.goo.gl', 'goo.gl'], true)) {
                try {
                    $res = Http::timeout(6)
                        ->withOptions(['allow_redirects' => ['track_redirects' => true]])
                        ->withHeaders(['User-Agent' => 'FleetlogSystem/1.0'])
                        ->get($rawUrl);
                    $redirects = $res->header('X-Guzzle-Redirect-History');
                    if (is_array($redirects) && ! empty($redirects)) {
                        $finalUrl = (string) end($redirects);
                    } elseif (is_string($redirects) && $redirects !== '') {
                        $finalUrl = $redirects;
                    }
                    $effective = (string) ($res->effectiveUri() ?? '');
                    if ($effective !== '') {
                        $finalUrl = $effective;
                    }
                } catch (\Throwable) {
                    /* usar rawUrl si no resolvió redirect */
                }
            }

            if (preg_match('/\/maps\/place\/([^\/@]+)/', $finalUrl, $pm)) {
                $shortName = trim(urldecode(str_replace('+', ' ', $pm[1])));
            } elseif (preg_match('/[?&]q=([^&]+)/', $finalUrl, $qm)) {
                $candidateQ = trim(urldecode(str_replace('+', ' ', $qm[1])));
                if (! preg_match('/^-?\d+\.\d+\s*,\s*-?\d+\.\d+$/', $candidateQ)) {
                    $shortName = $candidateQ;
                }
            }

            $lat = null;
            $lng = null;
            if (preg_match('/!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)/', $finalUrl, $cm)) {
                $lat = (float) $cm[1];
                $lng = (float) $cm[2];
            } elseif (preg_match('/@(-?\d+\.\d+),(-?\d+\.\d+)/', $finalUrl, $cm)) {
                $lat = (float) $cm[1];
                $lng = (float) $cm[2];
            } elseif (preg_match('/[?&](?:q|ll)=(-?\d+\.\d+)(?:%2C|,)(-?\d+\.\d+)/i', $finalUrl, $cm)) {
                $lat = (float) $cm[1];
                $lng = (float) $cm[2];
            }

            if ($lat !== null && $lng !== null && $lat >= -90 && $lat <= 90 && $lng >= -180 && $lng <= 180) {
                $rev = $this->reverseLookup($lat, $lng);

                return [
                    'name' => $shortName !== '' ? $shortName : ($rev['name'] ?? sprintf('Google Maps %.5f, %.5f', $lat, $lng)),
                    'address' => $rev['address'] ?? ($shortName !== '' ? $shortName : sprintf('%.6f, %.6f', $lat, $lng)),
                    'latitude' => $lat,
                    'longitude' => $lng,
                    'place_id' => $rev['place_id'] ?? null,
                    'provider' => 'google_link',
                ];
            }
        }

        return null;
    }

    private function searchArcGis(string $q): Collection
    {
        try {
            $response = Http::timeout(6)->get(
                'https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/findAddressCandidates',
                [
                    'SingleLine' => $q,
                    'location' => '-89.2182,13.6929',
                    'countryCode' => 'SLV',
                    'outFields' => 'PlaceName,Place_addr,Type,City',
                    'maxLocations' => 6,
                    'f' => 'json',
                ],
            );

            if (! $response->ok()) {
                return collect();
            }

            return collect($response->json('candidates', []))
                ->filter(fn (array $row) => (float) ($row['score'] ?? 0) >= 82)
                ->map(function (array $row) {
                    $attrs = $row['attributes'] ?? [];
                    $loc = $row['location'] ?? [];
                    $lat = (float) ($loc['y'] ?? 0);
                    $lng = (float) ($loc['x'] ?? 0);
                    $placeName = trim((string) ($attrs['PlaceName'] ?? ($row['address'] ?? '')));
                    $placeAddr = trim((string) ($attrs['Place_addr'] ?? ''));
                    $type = trim((string) ($attrs['Type'] ?? ''));

                    $addressParts = array_filter([
                        $placeAddr !== '' ? $placeAddr : (string) ($row['address'] ?? ''),
                        $type !== '' ? $type : null,
                    ]);

                    return [
                        'name' => $placeName ?: (string) ($row['address'] ?? ''),
                        'address' => implode(' · ', $addressParts),
                        'latitude' => $lat,
                        'longitude' => $lng,
                        'place_id' => 'arcgis:'.round($lat, 5).','.round($lng, 5),
                        'provider' => 'arcgis',
                        '_score' => (float) ($row['score'] ?? 0),
                    ];
                })
                ->filter(fn (array $item) => ($item['latitude'] !== 0.0 || $item['longitude'] !== 0.0) && $item['name'] !== '')
                ->values();
        } catch (\Throwable) {
            return collect();
        }
    }

    private function searchNominatim(string $q): Collection
    {
        try {
            // Priorizar El Salvador primero; si no devuelve coincidencias, ampliar globalmente
            $response = Http::timeout(7)
                ->withHeaders([
                    'User-Agent' => 'FleetlogSystem/1.0 (https://fleetlog.miascn.org)',
                    'Accept-Language' => 'es',
                ])
                ->get('https://nominatim.openstreetmap.org/search', [
                    'q' => $q,
                    'format' => 'jsonv2',
                    'addressdetails' => 1,
                    'countrycodes' => 'sv',
                    'limit' => 6,
                ]);

            $rows = $response->ok() ? ($response->json() ?? []) : [];

            if (empty($rows)) {
                $fallback = Http::timeout(6)
                    ->withHeaders([
                        'User-Agent' => 'FleetlogSystem/1.0 (https://fleetlog.miascn.org)',
                        'Accept-Language' => 'es',
                    ])
                    ->get('https://nominatim.openstreetmap.org/search', [
                        'q' => $q,
                        'format' => 'jsonv2',
                        'addressdetails' => 1,
                        'limit' => 5,
                    ]);
                $rows = $fallback->ok() ? ($fallback->json() ?? []) : [];
            }

            return collect($rows)
                ->map(function (array $row) {
                    $display = (string) ($row['display_name'] ?? '');
                    $shortName = trim((string) ($row['name'] ?? ''));
                    if ($shortName === '' && $display !== '') {
                        $shortName = trim(explode(',', $display)[0]);
                    }

                    return [
                        'name' => $shortName ?: $display,
                        'address' => $display,
                        'latitude' => (float) ($row['lat'] ?? 0),
                        'longitude' => (float) ($row['lon'] ?? 0),
                        'place_id' => isset($row['place_id']) ? 'osm:'.$row['place_id'] : null,
                        'provider' => 'osm',
                    ];
                })
                ->filter(fn (array $item) => $item['latitude'] !== 0.0 || $item['longitude'] !== 0.0)
                ->values();
        } catch (\Throwable) {
            return collect();
        }
    }

    private function mergeAndDeduplicatePlaces(Collection $arcgisItems, Collection $osmItems): Collection
    {
        $combined = collect();
        $pushUnique = function (array $candidate) use ($combined) {
            unset($candidate['_score']);
            $dup = $combined->contains(function (array $existing) use ($candidate) {
                $sameCoords = abs($existing['latitude'] - $candidate['latitude']) < 0.0008
                    && abs($existing['longitude'] - $candidate['longitude']) < 0.0008;
                $similarName = mb_strtolower($existing['name']) === mb_strtolower($candidate['name']);

                return $sameCoords && ($similarName || mb_strlen($candidate['name']) > 3);
            });

            if (! $dup) {
                $combined->push($candidate);
            }
        };

        foreach ($arcgisItems->sortByDesc('_score') as $item) {
            $pushUnique($item);
        }
        foreach ($osmItems as $item) {
            $pushUnique($item);
        }

        return $combined;
    }
}
