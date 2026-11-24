<?php

namespace App\Services;

use App\Models\Bitacora;
use App\Models\Incident;
use App\Models\TripLocationPoint;
use App\Models\TripTrackingSession;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Validation\ValidationException;
use Laravel\Sanctum\PersonalAccessToken;

class TripTrackingService
{
    private const EARTH_RADIUS_M = 6371000.0;

    private const MIN_MOVE_METERS = 12.0;

    private const STOP_RADIUS_METERS = 65.0;

    private const STOP_MIN_SECONDS = 180;

    public function haversineMeters(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $lat1Rad = deg2rad($lat1);
        $lat2Rad = deg2rad($lat2);
        $deltaLat = deg2rad($lat2 - $lat1);
        $deltaLng = deg2rad($lng2 - $lng1);

        $a = sin($deltaLat / 2) ** 2
            + cos($lat1Rad) * cos($lat2Rad) * (sin($deltaLng / 2) ** 2);

        $c = 2 * atan2(sqrt($a), sqrt(max(0.0, 1.0 - $a)));

        return self::EARTH_RADIUS_M * $c;
    }

    public function resolveDeviceContext(User $authUser, array $payload = [], ?Request $request = null): array
    {
        $req = $request ?? request();
        $token = $authUser->currentAccessToken();
        $personalToken = $token instanceof PersonalAccessToken ? $token : null;

        $rawUuid = trim((string) ($payload['device_uuid'] ?? $req?->header('X-Device-UUID') ?? ''));
        $rawName = trim((string) ($payload['device_name'] ?? $req?->header('X-Device-Name') ?? ($personalToken?->name ?: 'web-dashboard')));
        $rawPlatform = trim((string) ($payload['device_platform'] ?? $req?->header('X-Device-Platform') ?? ''));

        if ($rawUuid === '') {
            if ($personalToken) {
                $rawUuid = 'token:'.$personalToken->id;
            } else {
                $ua = substr(sha1((string) ($req?->userAgent() ?? 'web')), 0, 12);
                $rawUuid = 'web:'.$authUser->id.':'.$ua;
            }
        }

        if ($rawPlatform === '') {
            $rawPlatform = str_starts_with($rawUuid, 'web:') ? 'web' : 'mobile';
        }

        return [
            'device_uuid' => mb_substr($rawUuid, 0, 128),
            'device_name' => mb_substr($rawName !== '' ? $rawName : 'Dispositivo sin nombre', 0, 120),
            'device_platform' => mb_substr($rawPlatform, 0, 40),
            'token_id' => $personalToken?->id,
        ];
    }

    public function startForSalida(Bitacora $salida, User $authUser, array $payload = [], ?Request $request = null): TripTrackingSession
    {
        $ctx = $this->resolveDeviceContext($authUser, $payload, $request);

        /** @var TripTrackingSession $session */
        $session = TripTrackingSession::query()->create([
            'salida_bitacora_id' => $salida->id,
            'assignment_id' => $salida->assignment_id,
            'vehicle_id' => $salida->vehicle_id,
            'driver_id' => $salida->driver_id ?? $authUser->id,
            'started_by_user_id' => $authUser->id,
            'device_uuid' => $ctx['device_uuid'],
            'device_name' => $ctx['device_name'],
            'device_platform' => $ctx['device_platform'],
            'started_by_token_id' => $ctx['token_id'],
            'status' => TripTrackingSession::STATUS_ACTIVE,
            'started_at' => $salida->recorded_at ?? now(),
        ]);

        $initLat = $payload['initial_latitude'] ?? $payload['current_latitude'] ?? null;
        $initLng = $payload['initial_longitude'] ?? $payload['current_longitude'] ?? null;

        if (is_numeric($initLat) && is_numeric($initLng)) {
            $this->appendPoints(
                $session,
                $authUser,
                [[
                    'latitude' => (float) $initLat,
                    'longitude' => (float) $initLng,
                    'accuracy_m' => isset($payload['initial_accuracy_m']) ? (float) $payload['initial_accuracy_m'] : null,
                    'speed_kmh' => 0,
                    'battery_level' => isset($payload['battery_level']) ? (int) $payload['battery_level'] : null,
                    'is_moving' => true,
                    'source' => TripLocationPoint::SOURCE_START,
                    'recorded_at' => ($salida->recorded_at ?? now())->toIso8601String(),
                    'address_hint' => $salida->destination,
                ]],
                $ctx,
                $request,
            );
        }

        SystemLogger::record(
            $authUser,
            'tracking',
            'session_started',
            "Rastreo iniciado en {$ctx['device_name']} ({$ctx['device_uuid']}) para {$salida->vehicle?->license_plate}",
            $session,
            [
                'tracking_session_id' => $session->id,
                'salida_bitacora_id' => $salida->id,
                'driver_id' => $session->driver_id,
                'device_uuid' => $ctx['device_uuid'],
                'device_name' => $ctx['device_name'],
                'device_platform' => $ctx['device_platform'],
            ],
            $request,
        );

        return $session->fresh();
    }

    public function bindOrStartActiveSession(
        User $authUser,
        ?int $bitacoraId,
        array $payload,
        ?Request $request = null,
    ): TripTrackingSession {
        $ctx = $this->resolveDeviceContext($authUser, $payload, $request);

        $query = TripTrackingSession::query()
            ->where('status', TripTrackingSession::STATUS_ACTIVE)
            ->orderByDesc('started_at');

        if ($bitacoraId) {
            $query->where('salida_bitacora_id', $bitacoraId);
        } else {
            $query->where(function ($q) use ($authUser) {
                $q->where('driver_id', $authUser->id)
                    ->orWhere('started_by_user_id', $authUser->id);
            });
        }

        /** @var TripTrackingSession|null $session */
        $session = $query->first();
        if (! $session) {
            throw ValidationException::withMessages([
                'tracking' => ['No tienes ninguna misión activa pendiente de rastreo.'],
            ]);
        }

        if (! $authUser->canManageFleet()
            && (int) $session->driver_id !== (int) $authUser->id
            && (int) $session->started_by_user_id !== (int) $authUser->id
        ) {
            throw new AuthorizationException('No puedes vincular una misión asignada a otro conductor.');
        }

        $isUnboundPlaceholder = str_starts_with($session->device_uuid, 'web:')
            || str_starts_with($session->device_uuid, 'token:');

        if ($session->device_uuid !== $ctx['device_uuid']) {
            if ($isUnboundPlaceholder && ! empty($payload['device_uuid'])) {
                $oldUuid = $session->device_uuid;
                $session->device_uuid = $ctx['device_uuid'];
                $session->device_name = $ctx['device_name'];
                $session->device_platform = $ctx['device_platform'];
                $session->started_by_token_id = $ctx['token_id'];
                $session->save();

                SystemLogger::record(
                    $authUser,
                    'tracking',
                    'device_bound',
                    "Vinculó rastreo móvil {$ctx['device_name']} ({$ctx['device_uuid']}) a misión #{$session->id}",
                    $session,
                    ['previous_device_uuid' => $oldUuid, 'device_uuid' => $ctx['device_uuid']],
                    $request,
                );
            } else {
                SystemLogger::record(
                    $authUser,
                    'tracking',
                    'device_mismatch',
                    "Bloqueado intento de vincular otro dispositivo ({$ctx['device_uuid']}) en misión #{$session->id}",
                    $session,
                    [
                        'expected_device_uuid' => $session->device_uuid,
                        'incoming_device_uuid' => $ctx['device_uuid'],
                        'incoming_device_name' => $ctx['device_name'],
                    ],
                    $request,
                );

                throw new AuthorizationException(
                    "Esta misión ya está siendo rastreada exclusivamente desde {$session->device_name} ({$session->device_uuid})."
                );
            }
        }

        return $session->fresh();
    }

    public function appendPoints(
        TripTrackingSession $session,
        User $authUser,
        array $pointsPayload,
        array $deviceContext = [],
        ?Request $request = null,
    ): array {
        if (! $authUser->canManageFleet()
            && (int) $session->driver_id !== (int) $authUser->id
            && (int) $session->started_by_user_id !== (int) $authUser->id
        ) {
            throw new AuthorizationException('No tienes permiso para reportar ubicación en esta misión.');
        }

        $incomingUuid = trim((string) ($deviceContext['device_uuid'] ?? ($request?->header('X-Device-UUID') ?? '')));
        if ($incomingUuid !== '' && $incomingUuid !== $session->device_uuid) {
            SystemLogger::record(
                $authUser,
                'tracking',
                'device_mismatch',
                "Alerta: intento de envío de GPS desde {$incomingUuid} distinto al celular autorizado {$session->device_uuid}",
                $session,
                [
                    'tracking_session_id' => $session->id,
                    'expected_device_uuid' => $session->device_uuid,
                    'incoming_device_uuid' => $incomingUuid,
                    'incoming_device_name' => $deviceContext['device_name'] ?? null,
                ],
                $request,
            );

            throw new AuthorizationException(
                "Dispositivo no autorizado: la misión pertenece al celular {$session->device_name}."
            );
        }

        return DB::transaction(function () use ($session, $authUser, $pointsPayload, $incomingUuid) {
            /** @var TripTrackingSession $locked */
            $locked = TripTrackingSession::query()->lockForUpdate()->findOrFail($session->id);

            if ($locked->status !== TripTrackingSession::STATUS_ACTIVE) {
                throw ValidationException::withMessages([
                    'status' => ['La sesión de rastreo ya fue finalizada y no acepta nuevos puntos.'],
                ]);
            }

            if ($incomingUuid !== '' && $incomingUuid !== $locked->device_uuid) {
                throw new AuthorizationException(
                    "Dispositivo no autorizado: la misión pertenece al celular {$locked->device_name}."
                );
            }

            $sorted = collect($pointsPayload)
                ->filter(fn ($p) => is_array($p) && is_numeric($p['latitude'] ?? null) && is_numeric($p['longitude'] ?? null))
                ->map(function (array $p) {
                    $recordedAt = ! empty($p['recorded_at']) ? Carbon::parse($p['recorded_at']) : now();

                    return [
                        'recorded_at' => $recordedAt,
                        'latitude' => round((float) $p['latitude'], 7),
                        'longitude' => round((float) $p['longitude'], 7),
                        'accuracy_m' => isset($p['accuracy_m']) && is_numeric($p['accuracy_m']) ? round((float) $p['accuracy_m'], 2) : null,
                        'speed_kmh' => isset($p['speed_kmh']) && is_numeric($p['speed_kmh']) ? max(0.0, round((float) $p['speed_kmh'], 2)) : null,
                        'heading' => isset($p['heading']) && is_numeric($p['heading']) ? round((float) $p['heading'], 2) : null,
                        'altitude_m' => isset($p['altitude_m']) && is_numeric($p['altitude_m']) ? round((float) $p['altitude_m'], 2) : null,
                        'battery_level' => isset($p['battery_level']) && is_numeric($p['battery_level']) ? max(0, min(100, (int) $p['battery_level'])) : null,
                        'is_moving' => array_key_exists('is_moving', $p) ? (bool) $p['is_moving'] : true,
                        'source' => in_array($p['source'] ?? '', TripLocationPoint::SOURCES, true)
                            ? $p['source']
                            : TripLocationPoint::SOURCE_BACKGROUND,
                        'address_hint' => isset($p['address_hint']) ? mb_substr(trim((string) $p['address_hint']), 0, 255) : null,
                    ];
                })
                ->sortBy(fn (array $p) => $p['recorded_at']->getTimestampMs())
                ->values();

            $lastStored = $locked->points()->reorder('recorded_at', 'desc')->orderByDesc('id')->first();
            $prevLat = $lastStored?->latitude;
            $prevLng = $lastStored?->longitude;
            $prevTs = $lastStored?->recorded_at?->getTimestamp();

            $added = 0;
            $sosTriggered = false;
            $distanceDeltaKm = 0.0;
            $maxSpeed = (float) $locked->max_speed_kmh;

            foreach ($sorted as $pt) {
                $ts = $pt['recorded_at']->getTimestamp();
                // Evitar duplicados exactos (mismo segundo y misma coordenada)
                if ($prevTs !== null && $prevTs === $ts && $prevLat !== null && abs($prevLat - $pt['latitude']) < 0.00001 && abs($prevLng - $pt['longitude']) < 0.00001) {
                    continue;
                }

                if ($prevLat !== null && $prevLng !== null) {
                    $distM = $this->haversineMeters($prevLat, $prevLng, $pt['latitude'], $pt['longitude']);
                    if ($distM >= self::MIN_MOVE_METERS) {
                        $distanceDeltaKm += $distM / 1000.0;
                    }
                }

                if ($pt['speed_kmh'] !== null && $pt['speed_kmh'] > $maxSpeed && $pt['speed_kmh'] <= 220.0) {
                    $maxSpeed = $pt['speed_kmh'];
                }

                TripLocationPoint::query()->create([
                    'tracking_session_id' => $locked->id,
                    'recorded_at' => $pt['recorded_at'],
                    'latitude' => $pt['latitude'],
                    'longitude' => $pt['longitude'],
                    'accuracy_m' => $pt['accuracy_m'],
                    'speed_kmh' => $pt['speed_kmh'],
                    'heading' => $pt['heading'],
                    'altitude_m' => $pt['altitude_m'],
                    'battery_level' => $pt['battery_level'],
                    'is_moving' => $pt['is_moving'],
                    'source' => $pt['source'],
                    'address_hint' => $pt['address_hint'],
                ]);

                if ($pt['source'] === TripLocationPoint::SOURCE_SOS) {
                    $sosTriggered = true;
                }

                $prevLat = $pt['latitude'];
                $prevLng = $pt['longitude'];
                $prevTs = $ts;
                $added++;

                $locked->last_ping_at = $pt['recorded_at'];
                $locked->last_latitude = $pt['latitude'];
                $locked->last_longitude = $pt['longitude'];
                if ($pt['speed_kmh'] !== null) {
                    $locked->last_speed_kmh = $pt['speed_kmh'];
                }
                if ($pt['battery_level'] !== null) {
                    $locked->last_battery_level = $pt['battery_level'];
                }
            }

            if ($added > 0) {
                $locked->points_count = (int) $locked->points_count + $added;
                $locked->gps_distance_km = round((float) $locked->gps_distance_km + $distanceDeltaKm, 2);
                $locked->max_speed_kmh = round($maxSpeed, 2);
                if ($sosTriggered) {
                    $locked->has_sos_alert = true;
                }
                $locked->save();
            }

            return [
                'added' => $added,
                'session' => $locked->fresh(),
            ];
        });
    }

    public function finishForRegreso(
        Bitacora $regreso,
        ?Bitacora $salida,
        User $authUser,
        array $payload = [],
        ?Request $request = null,
    ): ?TripTrackingSession {
        /** @var TripTrackingSession|null $session */
        $session = $salida
            ? TripTrackingSession::query()->where('salida_bitacora_id', $salida->id)->first()
            : TripTrackingSession::query()
                ->where('vehicle_id', $regreso->vehicle_id)
                ->where('status', TripTrackingSession::STATUS_ACTIVE)
                ->orderByDesc('started_at')
                ->first();

        if (! $session) {
            return null;
        }

        $endLat = $payload['final_latitude'] ?? $payload['initial_latitude'] ?? $payload['current_latitude'] ?? null;
        $endLng = $payload['final_longitude'] ?? $payload['initial_longitude'] ?? $payload['current_longitude'] ?? null;

        if ($session->status === TripTrackingSession::STATUS_ACTIVE && is_numeric($endLat) && is_numeric($endLng)) {
            $ctx = $this->resolveDeviceContext($authUser, $payload, $request);
            // Si el cierre viene desde el jefe/admin web, no bloquear el regreso por device_uuid; solo si coincide o es manager
            $appendCtx = $authUser->canManageFleet()
                ? ['device_uuid' => $session->device_uuid, 'device_name' => $session->device_name]
                : $ctx;

            try {
                $this->appendPoints(
                    $session,
                    $authUser,
                    [[
                        'latitude' => (float) $endLat,
                        'longitude' => (float) $endLng,
                        'accuracy_m' => isset($payload['initial_accuracy_m']) ? (float) $payload['initial_accuracy_m'] : null,
                        'speed_kmh' => 0,
                        'battery_level' => isset($payload['battery_level']) ? (int) $payload['battery_level'] : null,
                        'is_moving' => false,
                        'source' => TripLocationPoint::SOURCE_END,
                        'recorded_at' => ($regreso->recorded_at ?? now())->toIso8601String(),
                    ]],
                    $appendCtx,
                    $request,
                );
            } catch (AuthorizationException) {
                // Si un administrador cerró desde otro dispositivo/panel, cerramos la sesión igual dejando auditoría
            }
        }

        $session = $session->fresh(['salidaBitacora', 'regresoBitacora', 'assignment.originalDriver', 'vehicle', 'driver', 'startedByUser']);

        $declaredDistance = null;
        if ($salida?->odometer_km !== null && $regreso->odometer_km !== null && $regreso->odometer_km >= $salida->odometer_km) {
            $declaredDistance = (int) $regreso->odometer_km - (int) $salida->odometer_km;
        }

        $session->regreso_bitacora_id = $regreso->id;
        $session->status = TripTrackingSession::STATUS_FINISHED;
        $session->ended_at = $regreso->recorded_at ?? now();
        $session->declared_distance_km = $declaredDistance;

        $summary = $this->buildSummaryPayload($session);
        $session->stops_count = count($summary['stops']);
        $session->gps_distance_km = $summary['gps_distance_km'];
        $session->summary_json = $summary;
        $session->save();

        SystemLogger::record(
            $authUser,
            'tracking',
            'session_finished',
            "Finalizó rastreo #{$session->id} en {$session->vehicle?->license_plate} ({$session->gps_distance_km} km GPS, {$session->points_count} puntos)",
            $session,
            [
                'tracking_session_id' => $session->id,
                'device_uuid' => $session->device_uuid,
                'device_name' => $session->device_name,
                'gps_distance_km' => $session->gps_distance_km,
                'declared_distance_km' => $declaredDistance,
                'stops_count' => $session->stops_count,
                'points_count' => $session->points_count,
            ],
            $request,
        );

        return $session->fresh();
    }

    public function buildSummaryPayload(TripTrackingSession $session): array
    {
        $session->loadMissing([
            'salidaBitacora',
            'regresoBitacora',
            'assignment.originalDriver',
            'vehicle',
            'driver',
            'startedByUser',
        ]);

        /** @var Collection<int, TripLocationPoint> $points */
        $points = $session->points()->get();

        $totalDistanceMeters = 0.0;
        $maxSpeed = (float) $session->max_speed_kmh;
        $speedSum = 0.0;
        $speedSamples = 0;

        for ($i = 0; $i < $points->count(); $i++) {
            $curr = $points[$i];
            if ($curr->speed_kmh !== null && $curr->speed_kmh <= 220.0) {
                $speedSum += $curr->speed_kmh;
                $speedSamples++;
                if ($curr->speed_kmh > $maxSpeed) {
                    $maxSpeed = $curr->speed_kmh;
                }
            }
            if ($i > 0) {
                $prev = $points[$i - 1];
                $d = $this->haversineMeters($prev->latitude, $prev->longitude, $curr->latitude, $curr->longitude);
                if ($d >= self::MIN_MOVE_METERS) {
                    $totalDistanceMeters += $d;
                }
            }
        }

        $gpsDistanceKm = $points->count() >= 2
            ? round($totalDistanceMeters / 1000.0, 2)
            : (float) $session->gps_distance_km;

        $stops = $this->detectStops($points);

        $startTime = $session->started_at ?? now();
        $endTime = $session->ended_at ?? now();
        $durationMinutes = max(0, (int) round($startTime->diffInSeconds($endTime) / 60));
        $avgSpeed = $speedSamples > 0
            ? round($speedSum / $speedSamples, 1)
            : ($durationMinutes > 0 && $gpsDistanceKm > 0 ? round($gpsDistanceKm / ($durationMinutes / 60), 1) : 0.0);

        $timeline = [];

        $salida = $session->salidaBitacora;
        $assignment = $session->assignment;
        $timeline[] = [
            'type' => 'salida',
            'at' => $startTime->toIso8601String(),
            'title' => 'Inicio de misión (Salida)',
            'detail' => trim(implode(' · ', array_filter([
                $salida?->destination ? "Destino: {$salida->destination}" : null,
                $salida?->trip_category ? "Categoría: {$salida->trip_category}" : null,
                $salida?->odometer_km !== null ? "Odómetro inicial: {$salida->odometer_km} km" : null,
                $salida?->official_instruction ? "Instrucción oficial: {$salida->official_instruction}" : null,
                $salida?->companions ? "Acompañantes: {$salida->companions}" : null,
            ]))),
            'latitude' => $points->first()?->latitude,
            'longitude' => $points->first()?->longitude,
        ];

        if ($assignment?->is_emergency_reassigned) {
            $timeline[] = [
                'type' => 'emergency',
                'at' => ($assignment->reassigned_at ?? $startTime)->toIso8601String(),
                'title' => 'Reasignación por emergencia',
                'detail' => trim(implode(' · ', array_filter([
                    $assignment->originalDriver ? "Original: {$assignment->originalDriver->name}" : null,
                    $assignment->reassignment_reason ? "Motivo: {$assignment->reassignment_reason}" : null,
                ]))),
            ];
        }

        foreach ($stops as $idx => $stop) {
            $timeline[] = [
                'type' => 'stop',
                'at' => $stop['started_at'],
                'title' => 'Parada #'.($idx + 1)." ({$stop['duration_minutes']} min)",
                'detail' => $stop['address_hint'] ?: sprintf('Detención registrada en %.5f, %.5f', $stop['latitude'], $stop['longitude']),
                'latitude' => $stop['latitude'],
                'longitude' => $stop['longitude'],
            ];
        }

        foreach ($points->where('source', TripLocationPoint::SOURCE_SOS) as $sosPt) {
            $timeline[] = [
                'type' => 'sos',
                'at' => $sosPt->recorded_at->toIso8601String(),
                'title' => 'Alerta SOS activada desde el celular',
                'detail' => $sosPt->address_hint ?: sprintf('Ubicación de alerta: %.5f, %.5f', $sosPt->latitude, $sosPt->longitude),
                'latitude' => $sosPt->latitude,
                'longitude' => $sosPt->longitude,
            ];
        }

        $incidents = Incident::query()
            ->where('vehicle_id', $session->vehicle_id)
            ->whereBetween('reported_at', [$startTime->copy()->subMinutes(5), $endTime->copy()->addMinutes(5)])
            ->orderBy('reported_at')
            ->get();

        foreach ($incidents as $inc) {
            $timeline[] = [
                'type' => 'incident',
                'at' => ($inc->reported_at ?? $inc->created_at)->toIso8601String(),
                'title' => "Incidencia ({$inc->severity}): {$inc->title}",
                'detail' => $inc->description,
            ];
        }

        if ($session->regresoBitacora) {
            $reg = $session->regresoBitacora;
            $timeline[] = [
                'type' => 'regreso',
                'at' => ($reg->recorded_at ?? $endTime)->toIso8601String(),
                'title' => 'Cierre de misión (Regreso)',
                'detail' => trim(implode(' · ', array_filter([
                    $reg->odometer_km !== null ? "Odómetro final: {$reg->odometer_km} km" : null,
                    $reg->fuel_level ? "Combustible: {$reg->fuel_level}" : null,
                    $reg->notes ? "Notas: {$reg->notes}" : null,
                ]))),
                'latitude' => $points->last()?->latitude,
                'longitude' => $points->last()?->longitude,
            ];
        }

        usort($timeline, fn (array $a, array $b) => strcmp((string) $a['at'], (string) $b['at']));

        $firstPoint = $points->first();
        $lastPoint = $points->last();

        return [
            'device' => [
                'device_uuid' => $session->device_uuid,
                'device_name' => $session->device_name,
                'device_platform' => $session->device_platform,
                'driver_name' => $session->driver?->name,
                'started_by_name' => $session->startedByUser?->name,
                'started_by_email' => $session->startedByUser?->email,
            ],
            'duration_minutes' => $durationMinutes,
            'gps_distance_km' => $gpsDistanceKm,
            'declared_distance_km' => $session->declared_distance_km,
            'odometer_start' => $salida?->odometer_km,
            'odometer_end' => $session->regresoBitacora?->odometer_km,
            'max_speed_kmh' => round($maxSpeed, 1),
            'avg_speed_kmh' => $avgSpeed,
            'points_count' => $points->count(),
            'start_point' => $firstPoint ? [
                'latitude' => $firstPoint->latitude,
                'longitude' => $firstPoint->longitude,
                'recorded_at' => $firstPoint->recorded_at->toIso8601String(),
            ] : null,
            'last_point' => $lastPoint ? [
                'latitude' => $lastPoint->latitude,
                'longitude' => $lastPoint->longitude,
                'recorded_at' => $lastPoint->recorded_at->toIso8601String(),
                'battery_level' => $lastPoint->battery_level,
            ] : null,
            'stops' => $stops,
            'timeline' => $timeline,
            'google_maps_route_url' => $this->buildGoogleMapsRouteUrl($points, $stops),
            'google_maps_last_url' => $lastPoint
                ? sprintf('https://www.google.com/maps/search/?api=1&query=%s,%s', $lastPoint->latitude, $lastPoint->longitude)
                : null,
            'matched_route' => $this->matchRouteToRoads($points),
        ];
    }

    /**
     * Ajusta los puntos GPS capturados a la geometría real de la calle/carretera (Map Matching OSRM).
     *
     * @param  Collection<int, TripLocationPoint>  $points
     */
    public function matchRouteToRoads(Collection $points): ?array
    {
        if (app()->runningUnitTests() || $points->count() < 2) {
            return null;
        }

        // Filtrar puntos consecutivos casi idénticos (< 10 m) para evitar ruido en el matcher
        $sampled = [];
        $last = null;
        foreach ($points as $pt) {
            if ($last === null || $this->haversineMeters($last->latitude, $last->longitude, $pt->latitude, $pt->longitude) >= 10.0) {
                $sampled[] = $pt;
                $last = $pt;
            }
        }
        if (count($sampled) < 2) {
            return null;
        }

        // Limitar a máximo 80 coordenadas para cumplir URL length estándar de OSRM
        if (count($sampled) > 80) {
            $reduced = [$sampled[0]];
            $step = (count($sampled) - 2) / 78;
            for ($i = 1; $i <= 78; $i++) {
                $reduced[] = $sampled[(int) round($i * $step)];
            }
            $reduced[] = $sampled[count($sampled) - 1];
            $sampled = $reduced;
        }

        $coordsParam = implode(';', array_map(
            fn (TripLocationPoint $p) => sprintf('%F,%F', $p->longitude, $p->latitude),
            $sampled,
        ));

        try {
            $matchRes = Http::timeout(4)->get(
                "https://router.project-osrm.org/match/v1/driving/{$coordsParam}",
                [
                    'overview' => 'full',
                    'geometries' => 'geojson',
                    'steps' => 'false',
                    'gaps' => 'ignore',
                ],
            );

            if ($matchRes->ok() && $matchRes->json('code') === 'Ok') {
                $coords = [];
                foreach ($matchRes->json('matchings', []) as $matching) {
                    foreach ($matching['geometry']['coordinates'] ?? [] as $pair) {
                        if (is_array($pair) && count($pair) >= 2) {
                            $coords[] = [(float) $pair[1], (float) $pair[0]];
                        }
                    }
                }
                if (count($coords) >= 2) {
                    return $coords;
                }
            }

            // Fallback a ruta por carretera si los pings están muy separados para match estricto
            $routeRes = Http::timeout(4)->get(
                "https://router.project-osrm.org/route/v1/driving/{$coordsParam}",
                [
                    'overview' => 'full',
                    'geometries' => 'geojson',
                    'steps' => 'false',
                ],
            );

            if ($routeRes->ok() && $routeRes->json('code') === 'Ok') {
                $rawCoords = $routeRes->json('routes.0.geometry.coordinates', []);
                $coords = [];
                foreach ($rawCoords as $pair) {
                    if (is_array($pair) && count($pair) >= 2) {
                        $coords[] = [(float) $pair[1], (float) $pair[0]];
                    }
                }
                if (count($coords) >= 2) {
                    return $coords;
                }
            }
        } catch (\Throwable) {
            /* si falla la red hacia OSRM, se mantiene fallback al trazo GPS crudo */
        }

        return null;
    }

    /**
     * @param  Collection<int, TripLocationPoint>  $points
     */
    private function detectStops(Collection $points): array
    {
        if ($points->count() < 2) {
            return [];
        }

        $stops = [];
        $anchor = $points->first();
        $clusterEnd = $anchor;

        for ($i = 1; $i < $points->count(); $i++) {
            $curr = $points[$i];
            $dist = $this->haversineMeters($anchor->latitude, $anchor->longitude, $curr->latitude, $curr->longitude);

            if ($dist <= self::STOP_RADIUS_METERS) {
                $clusterEnd = $curr;
                continue;
            }

            $seconds = $anchor->recorded_at->diffInSeconds($clusterEnd->recorded_at);
            if ($seconds >= self::STOP_MIN_SECONDS) {
                $stops[] = [
                    'started_at' => $anchor->recorded_at->toIso8601String(),
                    'ended_at' => $clusterEnd->recorded_at->toIso8601String(),
                    'duration_minutes' => (int) max(1, round($seconds / 60)),
                    'latitude' => $anchor->latitude,
                    'longitude' => $anchor->longitude,
                    'address_hint' => $anchor->address_hint ?: $clusterEnd->address_hint,
                ];
            }

            $anchor = $curr;
            $clusterEnd = $curr;
        }

        $seconds = $anchor->recorded_at->diffInSeconds($clusterEnd->recorded_at);
        if ($seconds >= self::STOP_MIN_SECONDS) {
            $stops[] = [
                'started_at' => $anchor->recorded_at->toIso8601String(),
                'ended_at' => $clusterEnd->recorded_at->toIso8601String(),
                'duration_minutes' => (int) max(1, round($seconds / 60)),
                'latitude' => $anchor->latitude,
                'longitude' => $anchor->longitude,
                'address_hint' => $anchor->address_hint ?: $clusterEnd->address_hint,
            ];
        }

        return $stops;
    }

    /**
     * @param  Collection<int, TripLocationPoint>  $points
     */
    private function buildGoogleMapsRouteUrl(Collection $points, array $stops): ?string
    {
        if ($points->count() === 0) {
            return null;
        }

        if ($points->count() === 1) {
            $p = $points->first();

            return sprintf('https://www.google.com/maps/search/?api=1&query=%s,%s', $p->latitude, $p->longitude);
        }

        $origin = $points->first();
        $dest = $points->last();

        $middle = collect();
        if ($points->count() > 2) {
            $interior = $points->slice(1, $points->count() - 2)->values();
            $maxWaypoints = 8;
            if ($interior->count() <= $maxWaypoints) {
                $middle = $interior;
            } else {
                $step = ($interior->count() - 1) / ($maxWaypoints - 1);
                for ($k = 0; $k < $maxWaypoints; $k++) {
                    $idx = (int) round($k * $step);
                    $middle->push($interior[$idx]);
                }
            }
        }

        $params = [
            'api' => '1',
            'origin' => "{$origin->latitude},{$origin->longitude}",
            'destination' => "{$dest->latitude},{$dest->longitude}",
            'travelmode' => 'driving',
        ];

        if ($middle->isNotEmpty()) {
            $params['waypoints'] = $middle
                ->map(fn (TripLocationPoint $p) => "{$p->latitude},{$p->longitude}")
                ->implode('|');
        }

        return 'https://www.google.com/maps/dir/?'.http_build_query($params);
    }
}
