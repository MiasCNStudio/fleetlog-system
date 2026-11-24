<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class PlaceController extends Controller
{
    public function config(): JsonResponse
    {
        $googleKey = (string) config('services.google_maps.key', '');

        return response()->json([
            'provider' => $googleKey !== '' ? 'google' : 'osm',
            'has_google_key' => $googleKey !== '',
        ]);
    }

    public function search(Request $request): JsonResponse
    {
        $q = trim((string) $request->query('q', ''));
        if (mb_strlen($q) < 2) {
            return response()->json(['data' => [], 'provider' => 'none']);
        }

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
                        ->take(6)
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
                /* fallback a OSM */
            }
        }

        try {
            $response = Http::timeout(8)
                ->withHeaders([
                    'User-Agent' => 'FleetlogSystem/1.0 (https://fleetlog.miascn.org)',
                    'Accept-Language' => 'es',
                ])
                ->get('https://nominatim.openstreetmap.org/search', [
                    'q' => $q,
                    'format' => 'jsonv2',
                    'addressdetails' => 1,
                    'limit' => 6,
                ]);

            if (! $response->ok()) {
                return response()->json(['data' => [], 'provider' => 'osm']);
            }

            $items = collect($response->json() ?? [])
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
                ->values();

            return response()->json(['data' => $items, 'provider' => 'osm']);
        } catch (\Throwable) {
            return response()->json(['data' => [], 'provider' => 'osm']);
        }
    }

    public function reverse(Request $request): JsonResponse
    {
        $lat = $request->query('lat');
        $lng = $request->query('lng');

        if (! is_numeric($lat) || ! is_numeric($lng)) {
            return response()->json(['data' => null], 422);
        }

        $latF = (float) $lat;
        $lngF = (float) $lng;

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

                        return response()->json([
                            'data' => [
                                'name' => $shortName ?: $formatted,
                                'address' => $formatted,
                                'latitude' => $latF,
                                'longitude' => $lngF,
                                'place_id' => $first['place_id'] ?? null,
                                'provider' => 'google',
                            ],
                        ]);
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
                return response()->json(['data' => null]);
            }

            $row = $response->json() ?? [];
            $display = (string) ($row['display_name'] ?? '');
            $shortName = trim((string) ($row['name'] ?? ''));
            if ($shortName === '' && $display !== '') {
                $shortName = trim(explode(',', $display)[0]);
            }

            return response()->json([
                'data' => [
                    'name' => $shortName ?: 'Ubicación seleccionada',
                    'address' => $display,
                    'latitude' => $latF,
                    'longitude' => $lngF,
                    'place_id' => isset($row['place_id']) ? 'osm:'.$row['place_id'] : null,
                    'provider' => 'osm',
                ],
            ]);
        } catch (\Throwable) {
            return response()->json(['data' => null]);
        }
    }
}
