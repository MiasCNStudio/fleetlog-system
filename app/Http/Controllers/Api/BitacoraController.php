<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreBitacoraRequest;
use App\Http\Requests\UpdateBitacoraRequest;
use App\Models\Bitacora;
use App\Models\Vehicle;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class BitacoraController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $perPage = min((int) $request->query('per_page', 15), 100);

        $query = Bitacora::query()
            ->with([
                'vehicle:id,license_plate,brand,model,status,current_odometer',
                'user:id,name,email',
                'driver:id,name,driver_code',
            ])
            ->orderByDesc('recorded_at')
            ->orderByDesc('id');

        if ($request->filled('vehicle_id')) {
            $query->where('vehicle_id', (int) $request->query('vehicle_id'));
        }

        if ($request->filled('type')) {
            $query->where('type', $request->query('type'));
        }

        if ($request->filled('date_from')) {
            $query->whereDate('recorded_at', '>=', $request->query('date_from'));
        }

        if ($request->filled('date_to')) {
            $query->whereDate('recorded_at', '<=', $request->query('date_to'));
        }

        if ($request->boolean('mine')) {
            $uid = $request->user()->id;
            $query->where(function ($q) use ($uid) {
                $q->where('driver_id', $uid)->orWhere('user_id', $uid);
            });
        }

        return response()->json($query->paginate($perPage));
    }

    public function nextType(Vehicle $vehicle): JsonResponse
    {
        return response()->json([
            'type' => $vehicle->nextBitacoraType(),
            'status' => $vehicle->status,
            'current_odometer' => $vehicle->current_odometer,
        ]);
    }

    public function store(StoreBitacoraRequest $request): JsonResponse
    {
        $data = $request->validated();
        $authUser = $request->user();

        $bitacora = DB::transaction(function () use ($data, $authUser) {
            /** @var Vehicle $vehicle */
            $vehicle = Vehicle::query()->lockForUpdate()->findOrFail($data['vehicle_id']);
            $type = $vehicle->nextBitacoraType();

            if ($type === Bitacora::TYPE_SALIDA && $vehicle->status === Vehicle::STATUS_MAINTENANCE) {
                throw ValidationException::withMessages([
                    'vehicle_id' => ['El vehículo se encuentra en mantenimiento y no puede registrar salida.'],
                ]);
            }

            if ($type === Bitacora::TYPE_SALIDA && trim((string) ($data['destination'] ?? '')) === '') {
                throw ValidationException::withMessages([
                    'destination' => ['Indica a dónde se dirige el vehículo al registrar una salida.'],
                ]);
            }

            $odometer = isset($data['odometer_km']) ? (int) $data['odometer_km'] : null;
            if ($odometer !== null && $vehicle->current_odometer > 0 && $odometer < $vehicle->current_odometer) {
                throw ValidationException::withMessages([
                    'odometer_km' => ["El odómetro no puede ser menor al último registrado ({$vehicle->current_odometer} km)."],
                ]);
            }

            $driverId = $authUser->canManageFleet()
                ? ($data['driver_id'] ?? $authUser->id)
                : $authUser->id;

            $destRaw = isset($data['destination']) ? trim((string) $data['destination']) : '';
            $destination = $destRaw !== '' ? $destRaw : null;
            $compRaw = isset($data['companions']) ? trim((string) $data['companions']) : '';
            $companions = $compRaw !== '' ? $compRaw : null;

            $created = Bitacora::query()->create([
                'vehicle_id' => $vehicle->id,
                'user_id' => $authUser->id,
                'driver_id' => $driverId,
                'type' => $type,
                'recorded_at' => now(),
                'odometer_km' => $odometer,
                'fuel_level' => $data['fuel_level'] ?? null,
                'destination' => $destination,
                'companions' => $companions,
            ]);

            if ($vehicle->status !== Vehicle::STATUS_MAINTENANCE) {
                $vehicle->status = $type === Bitacora::TYPE_SALIDA
                    ? Vehicle::STATUS_IN_ROUTE
                    : Vehicle::STATUS_AVAILABLE;
            }
            if ($odometer !== null) {
                $vehicle->current_odometer = $odometer;
            }
            $vehicle->save();

            return $created;
        });

        return response()->json(
            $bitacora->load([
                'vehicle:id,license_plate,brand,model,status,current_odometer',
                'user:id,name,email',
                'driver:id,name,driver_code',
            ]),
            201
        );
    }

    public function show(Bitacora $bitacora): JsonResponse
    {
        return response()->json(
            $bitacora->load([
                'vehicle:id,license_plate,brand,model,color,status,current_odometer',
                'user:id,name,email',
                'driver:id,name,driver_code',
            ])
        );
    }

    public function update(UpdateBitacoraRequest $request, Bitacora $bitacora): JsonResponse
    {
        $bitacora->fill($request->validated());
        $bitacora->save();

        return response()->json(
            $bitacora->load([
                'vehicle:id,license_plate,brand,model,status,current_odometer',
                'user:id,name,email',
                'driver:id,name,driver_code',
            ])
        );
    }

    public function destroy(Bitacora $bitacora): JsonResponse
    {
        DB::transaction(function () use ($bitacora) {
            $vehicle = $bitacora->vehicle()->lockForUpdate()->first();
            $bitacora->delete();

            if ($vehicle && $vehicle->status !== Vehicle::STATUS_MAINTENANCE) {
                $nextType = $vehicle->nextBitacoraType();
                $vehicle->status = $nextType === Bitacora::TYPE_REGRESO
                    ? Vehicle::STATUS_IN_ROUTE
                    : Vehicle::STATUS_AVAILABLE;
                $vehicle->save();
            }
        });

        return response()->json(null, 204);
    }
}
