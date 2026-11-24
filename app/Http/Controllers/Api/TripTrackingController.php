<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TripLocationPoint;
use App\Models\TripTrackingSession;
use App\Services\SystemLogger;
use App\Services\TripTrackingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TripTrackingController extends Controller
{
    public function __construct(private readonly TripTrackingService $tracking) {}

    private function relations(): array
    {
        return [
            'vehicle:id,license_plate,brand,model,status,current_odometer',
            'driver:id,name,driver_code,email',
            'startedByUser:id,name,email',
            'salidaBitacora:id,vehicle_id,driver_id,assignment_id,type,trip_category,recorded_at,odometer_km,fuel_level,destination,destination_address,latitude,longitude,companions,official_instruction,notes',
            'regresoBitacora:id,vehicle_id,recorded_at,odometer_km,fuel_level,notes',
            'assignment:id,scheduled_date,scheduled_time,destination,official_instruction,status,is_emergency_reassigned,reassignment_reason,original_driver_id',
            'assignment.originalDriver:id,name,driver_code',
        ];
    }

    public function index(Request $request): JsonResponse
    {
        $perPage = min((int) $request->query('per_page', 15), 100);

        $query = TripTrackingSession::query()
            ->with($this->relations())
            ->orderByDesc('started_at')
            ->orderByDesc('id');

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }
        if ($request->filled('vehicle_id')) {
            $query->where('vehicle_id', (int) $request->query('vehicle_id'));
        }
        if ($request->filled('driver_id')) {
            $query->where('driver_id', (int) $request->query('driver_id'));
        }
        if ($request->filled('date_from')) {
            $query->whereDate('started_at', '>=', $request->query('date_from'));
        }
        if ($request->filled('date_to')) {
            $query->whereDate('started_at', '<=', $request->query('date_to'));
        }
        if ($request->boolean('sos_only')) {
            $query->where('has_sos_alert', true);
        }

        return response()->json($query->paginate($perPage));
    }

    public function active(): JsonResponse
    {
        $sessions = TripTrackingSession::query()
            ->with($this->relations())
            ->where('status', TripTrackingSession::STATUS_ACTIVE)
            ->orderByDesc('started_at')
            ->get()
            ->map(function (TripTrackingSession $s) {
                $recentTrail = $s->points()
                    ->reorder('recorded_at', 'desc')
                    ->limit(80)
                    ->get(['id', 'latitude', 'longitude', 'recorded_at', 'speed_kmh', 'source'])
                    ->reverse()
                    ->values();
                $s->setAttribute('recent_trail', $recentTrail);

                return $s;
            });

        return response()->json(['data' => $sessions]);
    }

    public function myActive(Request $request): JsonResponse
    {
        $uid = $request->user()->id;

        $session = TripTrackingSession::query()
            ->with($this->relations())
            ->where('status', TripTrackingSession::STATUS_ACTIVE)
            ->where(function ($q) use ($uid) {
                $q->where('driver_id', $uid)->orWhere('started_by_user_id', $uid);
            })
            ->orderByDesc('started_at')
            ->first();

        return response()->json(['data' => $session]);
    }

    public function show(Request $request, TripTrackingSession $session): JsonResponse
    {
        $session->load($this->relations());
        $points = $session->points()
            ->limit(3000)
            ->get([
                'id',
                'recorded_at',
                'latitude',
                'longitude',
                'accuracy_m',
                'speed_kmh',
                'heading',
                'altitude_m',
                'battery_level',
                'is_moving',
                'source',
                'address_hint',
            ]);

        $summary = ($session->status === TripTrackingSession::STATUS_ACTIVE || empty($session->summary_json))
            ? $this->tracking->buildSummaryPayload($session)
            : $session->summary_json;

        return response()->json([
            'session' => $session,
            'points' => $points,
            'summary' => $summary,
        ]);
    }

    public function start(Request $request): JsonResponse
    {
        $data = $request->validate([
            'bitacora_id' => ['nullable', 'integer', 'exists:bitacoras,id'],
            'device_uuid' => ['required', 'string', 'max:128'],
            'device_name' => ['required', 'string', 'max:120'],
            'device_platform' => ['nullable', 'string', 'max:40'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'accuracy_m' => ['nullable', 'numeric', 'min:0'],
            'battery_level' => ['nullable', 'integer', 'between:0,100'],
        ]);

        $session = $this->tracking->bindOrStartActiveSession(
            $request->user(),
            isset($data['bitacora_id']) ? (int) $data['bitacora_id'] : null,
            $data,
            $request,
        );

        if (isset($data['latitude'], $data['longitude'])) {
            $ctx = $this->tracking->resolveDeviceContext($request->user(), $data, $request);
            $this->tracking->appendPoints(
                $session,
                $request->user(),
                [[
                    'latitude' => $data['latitude'],
                    'longitude' => $data['longitude'],
                    'accuracy_m' => $data['accuracy_m'] ?? null,
                    'battery_level' => $data['battery_level'] ?? null,
                    'source' => TripLocationPoint::SOURCE_FOREGROUND,
                    'recorded_at' => now()->toIso8601String(),
                ]],
                $ctx,
                $request,
            );
        }

        return response()->json([
            'data' => $session->fresh($this->relations()),
        ]);
    }

    public function storePoints(Request $request, TripTrackingSession $session): JsonResponse
    {
        $data = $request->validate([
            'device_uuid' => ['required', 'string', 'max:128'],
            'device_name' => ['nullable', 'string', 'max:120'],
            'device_platform' => ['nullable', 'string', 'max:40'],
            'points' => ['nullable', 'array', 'min:1', 'max:250'],
            'points.*.latitude' => ['required_with:points', 'numeric', 'between:-90,90'],
            'points.*.longitude' => ['required_with:points', 'numeric', 'between:-180,180'],
            'points.*.recorded_at' => ['nullable', 'date'],
            'points.*.accuracy_m' => ['nullable', 'numeric', 'min:0'],
            'points.*.speed_kmh' => ['nullable', 'numeric', 'min:0'],
            'points.*.heading' => ['nullable', 'numeric', 'between:0,360'],
            'points.*.altitude_m' => ['nullable', 'numeric'],
            'points.*.battery_level' => ['nullable', 'integer', 'between:0,100'],
            'points.*.is_moving' => ['nullable', 'boolean'],
            'points.*.source' => ['nullable', 'string', 'max:32'],
            'points.*.address_hint' => ['nullable', 'string', 'max:255'],
            'latitude' => ['required_without:points', 'nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['required_without:points', 'nullable', 'numeric', 'between:-180,180'],
            'recorded_at' => ['nullable', 'date'],
            'accuracy_m' => ['nullable', 'numeric', 'min:0'],
            'speed_kmh' => ['nullable', 'numeric', 'min:0'],
            'heading' => ['nullable', 'numeric', 'between:0,360'],
            'altitude_m' => ['nullable', 'numeric'],
            'battery_level' => ['nullable', 'integer', 'between:0,100'],
            'is_moving' => ['nullable', 'boolean'],
            'source' => ['nullable', 'string', 'max:32'],
            'address_hint' => ['nullable', 'string', 'max:255'],
        ]);

        $points = ! empty($data['points'])
            ? $data['points']
            : [[
                'latitude' => $data['latitude'],
                'longitude' => $data['longitude'],
                'recorded_at' => $data['recorded_at'] ?? now()->toIso8601String(),
                'accuracy_m' => $data['accuracy_m'] ?? null,
                'speed_kmh' => $data['speed_kmh'] ?? null,
                'heading' => $data['heading'] ?? null,
                'altitude_m' => $data['altitude_m'] ?? null,
                'battery_level' => $data['battery_level'] ?? null,
                'is_moving' => $data['is_moving'] ?? true,
                'source' => $data['source'] ?? TripLocationPoint::SOURCE_BACKGROUND,
                'address_hint' => $data['address_hint'] ?? null,
            ]];

        $ctx = $this->tracking->resolveDeviceContext($request->user(), $data, $request);
        $result = $this->tracking->appendPoints($session, $request->user(), $points, $ctx, $request);

        return response()->json([
            'added' => $result['added'],
            'session' => $result['session'],
        ]);
    }

    public function sos(Request $request, TripTrackingSession $session): JsonResponse
    {
        $data = $request->validate([
            'device_uuid' => ['required', 'string', 'max:128'],
            'device_name' => ['nullable', 'string', 'max:120'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'accuracy_m' => ['nullable', 'numeric', 'min:0'],
            'battery_level' => ['nullable', 'integer', 'between:0,100'],
            'message' => ['nullable', 'string', 'max:255'],
        ]);

        $ctx = $this->tracking->resolveDeviceContext($request->user(), $data, $request);
        $result = $this->tracking->appendPoints(
            $session,
            $request->user(),
            [[
                'latitude' => $data['latitude'],
                'longitude' => $data['longitude'],
                'accuracy_m' => $data['accuracy_m'] ?? null,
                'battery_level' => $data['battery_level'] ?? null,
                'is_moving' => false,
                'source' => TripLocationPoint::SOURCE_SOS,
                'recorded_at' => now()->toIso8601String(),
                'address_hint' => $data['message'] ?? 'Botón de alerta SOS activado',
            ]],
            $ctx,
            $request,
        );

        SystemLogger::record(
            $request->user(),
            'tracking',
            'sos_alert',
            "ALERTA SOS en misión #{$session->id} ({$session->vehicle?->license_plate}) desde {$ctx['device_name']} en {$data['latitude']}, {$data['longitude']}",
            $session,
            [
                'tracking_session_id' => $session->id,
                'device_uuid' => $ctx['device_uuid'],
                'latitude' => $data['latitude'],
                'longitude' => $data['longitude'],
                'message' => $data['message'] ?? null,
            ],
            $request,
        );

        return response()->json([
            'message' => 'Alerta SOS registrada y enviada al centro de control.',
            'session' => $result['session'],
        ]);
    }
}
