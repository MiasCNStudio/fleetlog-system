<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Vehicle;
use App\Models\VehicleMaintenance;
use App\Services\SystemLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class VehicleMaintenanceController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $perPage = min((int) $request->query('per_page', 15), 100);

        $query = VehicleMaintenance::query()
            ->with([
                'vehicle:id,license_plate,plate_type,plate_number,brand,model,status,current_odometer,next_maintenance_odometer,maintenance_interval_km,maintenance_alert_before_km',
                'creator:id,name',
            ])
            ->orderByRaw("CASE WHEN status = 'programado' THEN 0 ELSE 1 END")
            ->orderByDesc('created_at')
            ->orderByDesc('id');

        if ($request->filled('vehicle_id')) {
            $query->where('vehicle_id', (int) $request->query('vehicle_id'));
        }
        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        $alerts = Vehicle::query()
            ->whereNotNull('next_maintenance_odometer')
            ->orderBy('license_plate')
            ->get()
            ->filter(fn (Vehicle $v) => in_array($v->maintenance_status, ['vencido', 'pronto'], true))
            ->values();

        return response()->json([
            'records' => $query->paginate($perPage),
            'alerts' => $alerts,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'vehicle_id' => ['required', 'integer', 'exists:vehicles,id'],
            'title' => ['required', 'string', 'max:150'],
            'description' => ['nullable', 'string', 'max:2000'],
            'status' => ['sometimes', Rule::in(VehicleMaintenance::STATUSES)],
            'scheduled_odometer_km' => ['nullable', 'integer', 'min:0'],
            'completed_odometer_km' => ['nullable', 'integer', 'min:0'],
            'scheduled_date' => ['nullable', 'date'],
            'alert_before_km' => ['nullable', 'integer', 'min:50', 'max:5000'],
            'next_interval_km' => ['nullable', 'integer', 'min:100', 'max:100000'],
            'workshop' => ['nullable', 'string', 'max:150'],
            'cost_usd' => ['nullable', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'put_in_maintenance' => ['sometimes', 'boolean'],
            'release_vehicle' => ['sometimes', 'boolean'],
        ]);

        $authUser = $request->user();
        $status = $data['status'] ?? VehicleMaintenance::STATUS_SCHEDULED;

        $maintenance = DB::transaction(function () use ($data, $authUser, $status, $request) {
            /** @var Vehicle $vehicle */
            $vehicle = Vehicle::query()->lockForUpdate()->findOrFail((int) $data['vehicle_id']);

            if (isset($data['alert_before_km'])) {
                $vehicle->maintenance_alert_before_km = (int) $data['alert_before_km'];
            }
            if (isset($data['next_interval_km'])) {
                $vehicle->maintenance_interval_km = (int) $data['next_interval_km'];
            }

            $completedKm = isset($data['completed_odometer_km'])
                ? (int) $data['completed_odometer_km']
                : ($status === VehicleMaintenance::STATUS_COMPLETED ? $vehicle->current_odometer : null);

            $created = VehicleMaintenance::query()->create([
                'vehicle_id' => $vehicle->id,
                'user_id' => $authUser->id,
                'title' => trim($data['title']),
                'description' => $data['description'] ?? null,
                'status' => $status,
                'scheduled_odometer_km' => $data['scheduled_odometer_km'] ?? null,
                'completed_odometer_km' => $completedKm,
                'scheduled_date' => $data['scheduled_date'] ?? null,
                'completed_at' => $status === VehicleMaintenance::STATUS_COMPLETED ? now() : null,
                'workshop' => $data['workshop'] ?? null,
                'cost_usd' => $data['cost_usd'] ?? null,
                'notes' => $data['notes'] ?? null,
            ]);

            if ($status === VehicleMaintenance::STATUS_SCHEDULED) {
                if (isset($data['scheduled_odometer_km'])) {
                    $vehicle->next_maintenance_odometer = (int) $data['scheduled_odometer_km'];
                }
                if (! empty($data['put_in_maintenance'])) {
                    $vehicle->status = Vehicle::STATUS_MAINTENANCE;
                }
            } elseif ($status === VehicleMaintenance::STATUS_COMPLETED) {
                $refKm = $completedKm ?? $vehicle->current_odometer;
                if ($refKm > $vehicle->current_odometer) {
                    $vehicle->current_odometer = $refKm;
                }
                $vehicle->last_maintenance_odometer = $refKm;
                $vehicle->last_maintenance_at = now();

                if (isset($data['scheduled_odometer_km'])) {
                    $vehicle->next_maintenance_odometer = (int) $data['scheduled_odometer_km'];
                } elseif ($vehicle->maintenance_interval_km > 0) {
                    $vehicle->next_maintenance_odometer = $refKm + (int) $vehicle->maintenance_interval_km;
                }

                if (! empty($data['release_vehicle']) && $vehicle->status === Vehicle::STATUS_MAINTENANCE) {
                    $vehicle->status = Vehicle::STATUS_AVAILABLE;
                }
            }

            $vehicle->save();

            SystemLogger::record(
                $authUser,
                'maintenance',
                $status === VehicleMaintenance::STATUS_COMPLETED ? 'completed' : 'created',
                "Mantenimiento ({$status}) en {$vehicle->license_plate}: {$created->title}",
                $created,
                [
                    'vehicle_plate' => $vehicle->license_plate,
                    'scheduled_odometer_km' => $created->scheduled_odometer_km,
                    'completed_odometer_km' => $created->completed_odometer_km,
                    'next_maintenance_odometer' => $vehicle->next_maintenance_odometer,
                ],
                $request,
            );

            return $created;
        });

        return response()->json(
            $maintenance->load(['vehicle', 'creator:id,name']),
            201,
        );
    }

    public function complete(Request $request, VehicleMaintenance $maintenance): JsonResponse
    {
        $data = $request->validate([
            'completed_odometer_km' => ['nullable', 'integer', 'min:0'],
            'next_maintenance_odometer' => ['nullable', 'integer', 'min:0'],
            'next_interval_km' => ['nullable', 'integer', 'min:100', 'max:100000'],
            'workshop' => ['nullable', 'string', 'max:150'],
            'cost_usd' => ['nullable', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'release_vehicle' => ['sometimes', 'boolean'],
        ]);

        $authUser = $request->user();

        DB::transaction(function () use ($maintenance, $data, $authUser, $request) {
            /** @var Vehicle $vehicle */
            $vehicle = Vehicle::query()->lockForUpdate()->findOrFail($maintenance->vehicle_id);

            $completedKm = isset($data['completed_odometer_km'])
                ? (int) $data['completed_odometer_km']
                : $vehicle->current_odometer;

            if ($completedKm > $vehicle->current_odometer) {
                $vehicle->current_odometer = $completedKm;
            }

            $maintenance->status = VehicleMaintenance::STATUS_COMPLETED;
            $maintenance->completed_odometer_km = $completedKm;
            $maintenance->completed_at = now();
            if (array_key_exists('workshop', $data)) {
                $maintenance->workshop = $data['workshop'];
            }
            if (array_key_exists('cost_usd', $data)) {
                $maintenance->cost_usd = $data['cost_usd'];
            }
            if (array_key_exists('notes', $data)) {
                $maintenance->notes = $data['notes'];
            }
            $maintenance->save();

            $vehicle->last_maintenance_odometer = $completedKm;
            $vehicle->last_maintenance_at = now();

            if (isset($data['next_interval_km'])) {
                $vehicle->maintenance_interval_km = (int) $data['next_interval_km'];
            }

            if (isset($data['next_maintenance_odometer'])) {
                $vehicle->next_maintenance_odometer = (int) $data['next_maintenance_odometer'];
            } elseif ($vehicle->maintenance_interval_km > 0) {
                $vehicle->next_maintenance_odometer = $completedKm + (int) $vehicle->maintenance_interval_km;
            }

            if (($data['release_vehicle'] ?? true) && $vehicle->status === Vehicle::STATUS_MAINTENANCE) {
                $vehicle->status = Vehicle::STATUS_AVAILABLE;
            }

            $vehicle->save();

            SystemLogger::record(
                $authUser,
                'maintenance',
                'completed',
                "Completó mantenimiento en {$vehicle->license_plate} ({$completedKm} km) · Próximo: {$vehicle->next_maintenance_odometer} km",
                $maintenance,
                [
                    'vehicle_plate' => $vehicle->license_plate,
                    'completed_odometer_km' => $completedKm,
                    'next_maintenance_odometer' => $vehicle->next_maintenance_odometer,
                ],
                $request,
            );
        });

        return response()->json($maintenance->fresh(['vehicle', 'creator:id,name']));
    }

    public function destroy(Request $request, VehicleMaintenance $maintenance): JsonResponse
    {
        $id = $maintenance->id;
        $plate = $maintenance->vehicle?->license_plate ?? '';
        $maintenance->delete();

        SystemLogger::record(
            $request->user(),
            'maintenance',
            'deleted',
            "Eliminó registro de mantenimiento #{$id}".($plate ? " ({$plate})" : ''),
            null,
            ['maintenance_id' => $id, 'vehicle_plate' => $plate],
            $request,
        );

        return response()->json(null, 204);
    }
}
