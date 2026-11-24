<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreVehicleRequest;
use App\Http\Requests\UpdateVehicleRequest;
use App\Models\Bitacora;
use App\Models\Vehicle;
use App\Services\SystemLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class VehicleController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $perPage = min((int) $request->query('per_page', 15), 100);
        $query = Vehicle::query()->orderBy('license_plate');

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        if ($request->filled('search')) {
            $term = '%'.trim((string) $request->query('search')).'%';
            $query->where(function ($q) use ($term) {
                $q->where('license_plate', 'like', $term)
                    ->orWhere('brand', 'like', $term)
                    ->orWhere('model', 'like', $term);
            });
        }

        return response()->json($query->paginate($perPage));
    }

    public function options(): JsonResponse
    {
        $vehicles = Vehicle::query()
            ->select([
                'id',
                'license_plate',
                'plate_type',
                'plate_number',
                'brand',
                'model',
                'color',
                'status',
                'current_odometer',
                'maintenance_interval_km',
                'next_maintenance_odometer',
                'maintenance_alert_before_km',
            ])
            ->with('latestBitacora:bitacoras.id,bitacoras.vehicle_id,bitacoras.type,bitacoras.recorded_at')
            ->orderBy('license_plate')
            ->get()
            ->map(function (Vehicle $vehicle) {
                $lastType = $vehicle->latestBitacora?->type;
                $nextType = (! $lastType || $lastType === Bitacora::TYPE_REGRESO)
                    ? Bitacora::TYPE_SALIDA
                    : Bitacora::TYPE_REGRESO;

                return [
                    'id' => $vehicle->id,
                    'license_plate' => $vehicle->license_plate,
                    'plate_type' => $vehicle->plate_type,
                    'plate_number' => $vehicle->plate_number,
                    'brand' => $vehicle->brand,
                    'model' => $vehicle->model,
                    'color' => $vehicle->color,
                    'status' => $vehicle->status,
                    'current_odometer' => $vehicle->current_odometer,
                    'next_maintenance_odometer' => $vehicle->next_maintenance_odometer,
                    'maintenance_status' => $vehicle->maintenance_status,
                    'km_to_maintenance' => $vehicle->km_to_maintenance,
                    'next_type' => $nextType,
                ];
            });

        return response()->json(['data' => $vehicles]);
    }

    public function store(StoreVehicleRequest $request): JsonResponse
    {
        $data = $request->validated();
        $photo = $request->file('photo');

        unset($data['photo']);
        $data['license_plate'] = strtoupper(trim($data['license_plate']));
        $data['status'] = $data['status'] ?? Vehicle::STATUS_AVAILABLE;
        $data['current_odometer'] = $data['current_odometer'] ?? 0;

        if ($photo) {
            $data['photo_path'] = $photo->store('vehicles', 'public');
        }

        $vehicle = Vehicle::query()->create($data);

        SystemLogger::record(
            $request->user(),
            'vehicles',
            'created',
            "Registró el vehículo {$vehicle->license_plate} ({$vehicle->brand} {$vehicle->model})",
            $vehicle,
            ['license_plate' => $vehicle->license_plate, 'status' => $vehicle->status],
            $request,
        );

        return response()->json($vehicle->fresh(), 201);
    }

    public function show(Vehicle $vehicle): JsonResponse
    {
        return response()->json($vehicle);
    }

    public function update(UpdateVehicleRequest $request, Vehicle $vehicle): JsonResponse
    {
        $data = $request->validated();
        $photo = $request->file('photo');

        unset($data['photo']);

        if (isset($data['license_plate'])) {
            $data['license_plate'] = strtoupper(trim($data['license_plate']));
        }

        if ($photo) {
            if ($vehicle->photo_path) {
                Storage::disk('public')->delete($vehicle->photo_path);
            }
            $data['photo_path'] = $photo->store('vehicles', 'public');
        }

        $vehicle->fill($data);
        $vehicle->save();

        SystemLogger::record(
            $request->user(),
            'vehicles',
            'updated',
            "Actualizó vehículo {$vehicle->license_plate}",
            $vehicle,
            ['changes' => $vehicle->getChanges()],
            $request,
        );

        return response()->json($vehicle->fresh());
    }

    public function destroy(Request $request, Vehicle $vehicle): JsonResponse
    {
        $plate = $vehicle->license_plate;
        $id = $vehicle->id;

        if ($vehicle->photo_path) {
            Storage::disk('public')->delete($vehicle->photo_path);
        }

        $vehicle->delete();

        SystemLogger::record(
            $request->user(),
            'vehicles',
            'deleted',
            "Eliminó vehículo {$plate}",
            null,
            ['vehicle_id' => $id, 'license_plate' => $plate],
            $request,
        );

        return response()->json(null, 204);
    }
}
