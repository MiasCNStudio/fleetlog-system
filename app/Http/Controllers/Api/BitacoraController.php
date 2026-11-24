<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreBitacoraRequest;
use App\Http\Requests\UpdateBitacoraRequest;
use App\Models\Assignment;
use App\Models\Bitacora;
use App\Models\Vehicle;
use App\Services\SystemLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class BitacoraController extends Controller
{
    private function relations(): array
    {
        return [
            'vehicle:id,license_plate,brand,model,status,current_odometer',
            'user:id,name,email',
            'driver:id,name,driver_code',
            'assignment:id,scheduled_date,scheduled_time,driver_id,original_driver_id,is_emergency_reassigned,reassignment_reason,official_instruction,description,status',
            'assignment.originalDriver:id,name,driver_code',
        ];
    }

    public function index(Request $request): JsonResponse
    {
        $perPage = min((int) $request->query('per_page', 15), 100);

        $query = Bitacora::query()
            ->with($this->relations())
            ->orderByDesc('recorded_at')
            ->orderByDesc('id');

        if ($request->filled('vehicle_id')) {
            $query->where('vehicle_id', (int) $request->query('vehicle_id'));
        }

        if ($request->filled('type')) {
            $query->where('type', $request->query('type'));
        }

        if ($request->filled('trip_category')) {
            $query->where('trip_category', $request->query('trip_category'));
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

        $bitacora = DB::transaction(function () use ($data, $authUser, $request) {
            /** @var Assignment|null $assignment */
            $assignment = null;

            if (! empty($data['assignment_id'])) {
                $assignment = Assignment::query()->lockForUpdate()->findOrFail((int) $data['assignment_id']);
                if (in_array($assignment->status, [Assignment::STATUS_CANCELLED, Assignment::STATUS_COMPLETED], true)) {
                    throw ValidationException::withMessages([
                        'assignment_id' => ['Esta asignación ya fue completada o cancelada.'],
                    ]);
                }
            }

            $vehicleId = $assignment ? $assignment->vehicle_id : (int) ($data['vehicle_id'] ?? 0);
            if ($assignment && ! empty($data['vehicle_id']) && (int) $data['vehicle_id'] !== (int) $assignment->vehicle_id) {
                throw ValidationException::withMessages([
                    'vehicle_id' => ['El vehículo no coincide con la unidad asignada a este viaje.'],
                ]);
            }

            /** @var Vehicle $vehicle */
            $vehicle = Vehicle::query()->lockForUpdate()->findOrFail($vehicleId);
            $type = $vehicle->nextBitacoraType();

            if ($type === Bitacora::TYPE_SALIDA && $vehicle->status === Vehicle::STATUS_MAINTENANCE) {
                throw ValidationException::withMessages([
                    'vehicle_id' => ['El vehículo se encuentra en mantenimiento y no puede registrar salida.'],
                ]);
            }

            $tripCategory = $data['trip_category'] ?? null;

            if ($type === Bitacora::TYPE_SALIDA) {
                if ($assignment) {
                    $tripCategory = Bitacora::CATEGORY_ASSIGNMENT;

                    if ($assignment->status !== Assignment::STATUS_PENDING) {
                        throw ValidationException::withMessages([
                            'assignment_id' => ['Esta asignación ya tiene una salida en curso.'],
                        ]);
                    }

                    if (! $authUser->canManageFleet() && (int) $assignment->driver_id !== (int) $authUser->id) {
                        throw ValidationException::withMessages([
                            'assignment_id' => ['Esta asignación pertenece a otro motorista. Usa "Tomar por emergencia" con una razón justificada si debes cubrirla.'],
                        ]);
                    }
                } else {
                    if ($tripCategory === Bitacora::CATEGORY_UNPLANNED) {
                        if (! $authUser->canManageFleet()) {
                            throw ValidationException::withMessages([
                                'trip_category' => ['Solo el administrador o jefe de motoristas puede registrar un viaje imprevisto.'],
                            ]);
                        }
                    } elseif ($tripCategory === Bitacora::CATEGORY_PERSONAL) {
                        // Permitido para motoristas y jefes/admin, siempre con destino obligatorio
                    } else {
                        throw ValidationException::withMessages([
                            'trip_category' => $authUser->canManageFleet()
                                ? ['Selecciona una asignación o indica si la salida es Personal o Viaje imprevisto.']
                                : ['Los motoristas solo pueden iniciar salidas desde una asignación (o registrar una salida Personal).'],
                        ]);
                    }
                }
            } else {
                // Regreso: vincular automáticamente con la última salida del vehículo
                $lastSalida = $vehicle->bitacoras()
                    ->where('type', Bitacora::TYPE_SALIDA)
                    ->orderByDesc('recorded_at')
                    ->orderByDesc('id')
                    ->first();

                if (! $assignment && $lastSalida?->assignment_id) {
                    $candidate = Assignment::query()->lockForUpdate()->find($lastSalida->assignment_id);
                    if ($candidate && $candidate->status === Assignment::STATUS_IN_PROGRESS) {
                        if (! $authUser->canManageFleet() && (int) $candidate->driver_id !== (int) $authUser->id) {
                            throw ValidationException::withMessages([
                                'vehicle_id' => ['Este viaje en curso pertenece a otro motorista.'],
                            ]);
                        }
                        $assignment = $candidate;
                    }
                } elseif ($assignment && ! $authUser->canManageFleet() && $assignment->driver_id && (int) $assignment->driver_id !== (int) $authUser->id) {
                    throw ValidationException::withMessages([
                        'assignment_id' => ['Este viaje en curso pertenece a otro motorista.'],
                    ]);
                } elseif (! $assignment && $lastSalida && ! $authUser->canManageFleet()) {
                    $ownerId = $lastSalida->driver_id ?? $lastSalida->user_id;
                    if ($ownerId && (int) $ownerId !== (int) $authUser->id) {
                        throw ValidationException::withMessages([
                            'vehicle_id' => ['Este movimiento pertenece a otro usuario/motorista.'],
                        ]);
                    }
                }

                $tripCategory = $assignment
                    ? Bitacora::CATEGORY_ASSIGNMENT
                    : ($lastSalida?->trip_category ?? Bitacora::CATEGORY_ASSIGNMENT);
            }

            $destRaw = isset($data['destination']) ? trim((string) $data['destination']) : '';
            if ($destRaw === '' && $assignment && $type === Bitacora::TYPE_SALIDA) {
                $destRaw = (string) $assignment->destination;
            }

            if ($type === Bitacora::TYPE_SALIDA && $destRaw === '') {
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
                ? ($data['driver_id'] ?? $assignment?->driver_id ?? $authUser->id)
                : $authUser->id;

            $destination = $destRaw !== '' ? $destRaw : null;
            $destAddressRaw = isset($data['destination_address']) ? trim((string) $data['destination_address']) : '';
            $destinationAddress = $destAddressRaw !== '' ? $destAddressRaw : ($type === Bitacora::TYPE_SALIDA ? $assignment?->destination_address : null);

            $latitude = array_key_exists('latitude', $data) && $data['latitude'] !== null
                ? (float) $data['latitude']
                : ($type === Bitacora::TYPE_SALIDA ? $assignment?->latitude : null);
            $longitude = array_key_exists('longitude', $data) && $data['longitude'] !== null
                ? (float) $data['longitude']
                : ($type === Bitacora::TYPE_SALIDA ? $assignment?->longitude : null);
            $placeId = $data['place_id'] ?? ($type === Bitacora::TYPE_SALIDA ? $assignment?->place_id : null);

            $compRaw = isset($data['companions']) ? trim((string) $data['companions']) : '';
            $companions = $compRaw !== '' ? $compRaw : ($type === Bitacora::TYPE_SALIDA ? $assignment?->companions : null);

            $instrRaw = isset($data['official_instruction']) ? trim((string) $data['official_instruction']) : '';
            $officialInstruction = $instrRaw !== '' ? $instrRaw : $assignment?->official_instruction;

            $notesRaw = isset($data['notes']) ? trim((string) $data['notes']) : '';
            $notes = $notesRaw !== '' ? $notesRaw : null;

            $created = Bitacora::query()->create([
                'vehicle_id' => $vehicle->id,
                'user_id' => $authUser->id,
                'driver_id' => $driverId,
                'assignment_id' => $assignment?->id,
                'type' => $type,
                'trip_category' => $tripCategory,
                'recorded_at' => now(),
                'odometer_km' => $odometer,
                'fuel_level' => $data['fuel_level'] ?? null,
                'destination' => $destination,
                'destination_address' => $destinationAddress,
                'latitude' => $latitude,
                'longitude' => $longitude,
                'place_id' => $placeId,
                'companions' => $companions,
                'official_instruction' => $officialInstruction,
                'notes' => $notes,
            ]);

            if ($assignment) {
                $assignment->status = $type === Bitacora::TYPE_SALIDA
                    ? Assignment::STATUS_IN_PROGRESS
                    : Assignment::STATUS_COMPLETED;
                $assignment->save();
            }

            if ($vehicle->status !== Vehicle::STATUS_MAINTENANCE) {
                $vehicle->status = $type === Bitacora::TYPE_SALIDA
                    ? Vehicle::STATUS_IN_ROUTE
                    : Vehicle::STATUS_AVAILABLE;
            }
            if ($odometer !== null) {
                $vehicle->current_odometer = $odometer;
            }
            $vehicle->save();

            $actionName = match (true) {
                $type === Bitacora::TYPE_SALIDA && $tripCategory === Bitacora::CATEGORY_PERSONAL => 'personal_trip',
                $type === Bitacora::TYPE_SALIDA && $tripCategory === Bitacora::CATEGORY_UNPLANNED => 'unplanned_trip',
                default => 'created',
            };

            $catLabel = match ($tripCategory) {
                Bitacora::CATEGORY_PERSONAL => 'Personal',
                Bitacora::CATEGORY_UNPLANNED => 'Viaje imprevisto',
                default => 'Asignación',
            };

            SystemLogger::record(
                $authUser,
                'bitacoras',
                $actionName,
                "Registró {$type} ({$catLabel}) en {$vehicle->license_plate}".($destination ? " hacia {$destination}" : ''),
                $created,
                [
                    'vehicle_plate' => $vehicle->license_plate,
                    'type' => $type,
                    'trip_category' => $tripCategory,
                    'assignment_id' => $assignment?->id,
                    'driver_id' => $driverId,
                    'odometer_km' => $odometer,
                    'destination' => $destination,
                    'notes' => $notes,
                ],
                $request,
            );

            return $created;
        });

        return response()->json($bitacora->load($this->relations()), 201);
    }

    public function show(Bitacora $bitacora): JsonResponse
    {
        return response()->json($bitacora->load($this->relations()));
    }

    public function update(UpdateBitacoraRequest $request, Bitacora $bitacora): JsonResponse
    {
        $bitacora->fill($request->validated());
        $bitacora->save();

        SystemLogger::record(
            $request->user(),
            'bitacoras',
            'updated',
            "Editó la bitácora #{$bitacora->id}",
            $bitacora,
            ['changes' => $bitacora->getChanges()],
            $request,
        );

        return response()->json($bitacora->load($this->relations()));
    }

    public function destroy(Request $request, Bitacora $bitacora): JsonResponse
    {
        $plate = $bitacora->vehicle?->license_plate ?? '';
        $bitacoraId = $bitacora->id;

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

        SystemLogger::record(
            $request->user(),
            'bitacoras',
            'deleted',
            "Eliminó la bitácora #{$bitacoraId}".($plate ? " ({$plate})" : ''),
            null,
            ['bitacora_id' => $bitacoraId, 'vehicle_plate' => $plate],
            $request,
        );

        return response()->json(null, 204);
    }
}
