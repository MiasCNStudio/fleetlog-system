<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FuelLog;
use App\Models\Vehicle;
use App\Services\SystemLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class FuelLogController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $perPage = min((int) $request->query('per_page', 15), 100);

        $query = FuelLog::query()
            ->with([
                'vehicle:id,license_plate,plate_type,plate_number,brand,model,current_odometer',
                'recorder:id,name',
                'driver:id,name,driver_code',
            ])
            ->orderByDesc('filled_at')
            ->orderByDesc('id');

        if ($request->filled('vehicle_id')) {
            $query->where('vehicle_id', (int) $request->query('vehicle_id'));
        }
        if ($request->filled('fuel_type')) {
            $query->where('fuel_type', $request->query('fuel_type'));
        }
        if ($request->filled('date_from')) {
            $query->whereDate('filled_at', '>=', $request->query('date_from'));
        }
        if ($request->filled('date_to')) {
            $query->whereDate('filled_at', '<=', $request->query('date_to'));
        }
        if ($request->boolean('mine')) {
            $uid = $request->user()->id;
            $query->where(function ($q) use ($uid) {
                $q->where('driver_id', $uid)->orWhere('user_id', $uid);
            });
        }

        return response()->json($query->paginate($perPage));
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'vehicle_id' => ['required', 'integer', 'exists:vehicles,id'],
            'driver_id' => ['nullable', 'integer', 'exists:users,id'],
            'odometer_km' => ['required', 'integer', 'min:0'],
            'gallons' => ['required', 'numeric', 'gt:0', 'max:500'],
            'cost_usd' => ['nullable', 'numeric', 'min:0'],
            'fuel_type' => ['sometimes', Rule::in(FuelLog::FUEL_TYPES)],
            'station' => ['nullable', 'string', 'max:150'],
            'full_tank' => ['sometimes', 'boolean'],
            'filled_at' => ['nullable', 'date'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $authUser = $request->user();

        $log = DB::transaction(function () use ($data, $authUser, $request) {
            /** @var Vehicle $vehicle */
            $vehicle = Vehicle::query()->lockForUpdate()->findOrFail((int) $data['vehicle_id']);
            $odometer = (int) $data['odometer_km'];

            if ($vehicle->current_odometer > 0 && $odometer < $vehicle->current_odometer) {
                throw ValidationException::withMessages([
                    'odometer_km' => ["El odómetro no puede ser menor al actual ({$vehicle->current_odometer} km)."],
                ]);
            }

            $prevFuel = FuelLog::query()
                ->where('vehicle_id', $vehicle->id)
                ->orderByDesc('odometer_km')
                ->orderByDesc('id')
                ->first();

            $kmSinceLast = null;
            $kmPerGallon = null;
            $gallons = round((float) $data['gallons'], 2);

            if ($prevFuel && $odometer > $prevFuel->odometer_km && $gallons > 0) {
                $kmSinceLast = $odometer - $prevFuel->odometer_km;
                $kmPerGallon = round($kmSinceLast / $gallons, 2);
            }

            $driverId = $authUser->canManageFleet()
                ? ($data['driver_id'] ?? $authUser->id)
                : $authUser->id;

            $created = FuelLog::query()->create([
                'vehicle_id' => $vehicle->id,
                'user_id' => $authUser->id,
                'driver_id' => $driverId,
                'filled_at' => ! empty($data['filled_at']) ? $data['filled_at'] : now(),
                'odometer_km' => $odometer,
                'gallons' => $gallons,
                'cost_usd' => isset($data['cost_usd']) ? round((float) $data['cost_usd'], 2) : null,
                'fuel_type' => $data['fuel_type'] ?? 'regular',
                'station' => $data['station'] ?? null,
                'full_tank' => $data['full_tank'] ?? true,
                'km_since_last' => $kmSinceLast,
                'km_per_gallon' => $kmPerGallon,
                'notes' => $data['notes'] ?? null,
            ]);

            if ($odometer > $vehicle->current_odometer) {
                $vehicle->current_odometer = $odometer;
                $vehicle->save();
            }

            SystemLogger::record(
                $authUser,
                'fuel',
                'created',
                "Registró carga de {$gallons} gal ({$created->fuel_type}) en {$vehicle->license_plate} a {$odometer} km",
                $created,
                [
                    'vehicle_plate' => $vehicle->license_plate,
                    'odometer_km' => $odometer,
                    'gallons' => $gallons,
                    'cost_usd' => $created->cost_usd,
                    'km_per_gallon' => $kmPerGallon,
                    'maintenance_status' => $vehicle->maintenance_status,
                ],
                $request,
            );

            return $created;
        });

        return response()->json(
            $log->load(['vehicle', 'recorder:id,name', 'driver:id,name']),
            201,
        );
    }

    public function destroy(Request $request, FuelLog $fuelLog): JsonResponse
    {
        $id = $fuelLog->id;
        $plate = $fuelLog->vehicle?->license_plate ?? '';
        $fuelLog->delete();

        SystemLogger::record(
            $request->user(),
            'fuel',
            'deleted',
            "Eliminó registro de combustible #{$id}".($plate ? " ({$plate})" : ''),
            null,
            ['fuel_log_id' => $id, 'vehicle_plate' => $plate],
            $request,
        );

        return response()->json(null, 204);
    }
}
