<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\EmergencyReassignAssignmentRequest;
use App\Http\Requests\StoreAssignmentRequest;
use App\Http\Requests\UpdateAssignmentRequest;
use App\Models\Assignment;
use App\Services\SystemLogger;
use Carbon\Carbon;
use Carbon\CarbonPeriod;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AssignmentController extends Controller
{
    private function relations(): array
    {
        return [
            'vehicle:id,license_plate,brand,model,color,status,current_odometer',
            'driver:id,name,email,driver_code',
            'creator:id,name',
            'originalDriver:id,name,driver_code',
            'reassignedByUser:id,name',
        ];
    }

    public function index(Request $request): JsonResponse
    {
        $perPage = min((int) $request->query('per_page', 20), 100);

        $query = Assignment::query()
            ->with($this->relations())
            ->orderBy('scheduled_date')
            ->orderByRaw('CASE WHEN scheduled_time IS NULL THEN 1 ELSE 0 END')
            ->orderBy('scheduled_time')
            ->orderBy('id');

        if ($request->filled('date_from')) {
            $query->whereDate('scheduled_date', '>=', $request->query('date_from'));
        }

        if ($request->filled('date_to')) {
            $query->whereDate('scheduled_date', '<=', $request->query('date_to'));
        }

        if ($request->filled('driver_id')) {
            $query->where('driver_id', (int) $request->query('driver_id'));
        }

        if ($request->filled('vehicle_id')) {
            $query->where('vehicle_id', (int) $request->query('vehicle_id'));
        }

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        if ($request->boolean('mine')) {
            $query->where('driver_id', $request->user()->id);
        }

        if ($request->boolean('emergency_only')) {
            $query->where('is_emergency_reassigned', true);
        }

        return response()->json($query->paginate($perPage));
    }

    public function options(Request $request): JsonResponse
    {
        $authUser = $request->user();

        $query = Assignment::query()
            ->with($this->relations())
            ->whereIn('status', [Assignment::STATUS_PENDING, Assignment::STATUS_IN_PROGRESS])
            ->orderBy('scheduled_date')
            ->orderBy('scheduled_time')
            ->orderBy('id');

        if (! $authUser->canManageFleet() && ! $request->boolean('include_all')) {
            $query->where('driver_id', $authUser->id);
        }

        return response()->json([
            'data' => $query->limit(100)->get(),
        ]);
    }

    public function store(StoreAssignmentRequest $request): JsonResponse
    {
        $data = $request->validated();
        $authUser = $request->user();

        $dates = [];
        if (! empty($data['date_from']) && ! empty($data['date_to'])) {
            $start = Carbon::parse($data['date_from'])->startOfDay();
            $end = Carbon::parse($data['date_to'])->startOfDay();

            if ($start->diffInDays($end) > 92) {
                throw ValidationException::withMessages([
                    'date_to' => ['El rango máximo para programar asignaciones en lote es de 93 días (3 meses).'],
                ]);
            }

            $allowedWeekdays = isset($data['weekdays']) && count($data['weekdays']) > 0
                ? array_map('intval', $data['weekdays'])
                : null;

            foreach (CarbonPeriod::create($start, $end) as $date) {
                if ($allowedWeekdays !== null && ! in_array($date->dayOfWeek, $allowedWeekdays, true)) {
                    continue;
                }
                $dates[] = $date->format('Y-m-d');
            }

            if (count($dates) === 0) {
                throw ValidationException::withMessages([
                    'weekdays' => ['Ninguna fecha dentro del rango coincide con los días seleccionados.'],
                ]);
            }
        } else {
            $dates[] = Carbon::parse($data['scheduled_date'])->format('Y-m-d');
        }

        $groupId = count($dates) > 1 ? (string) Str::uuid() : null;

        $created = DB::transaction(function () use ($dates, $data, $authUser, $groupId) {
            $items = collect();

            foreach ($dates as $dateStr) {
                $assignment = Assignment::query()->create([
                    'vehicle_id' => (int) $data['vehicle_id'],
                    'driver_id' => (int) $data['driver_id'],
                    'created_by' => $authUser->id,
                    'scheduled_date' => $dateStr,
                    'scheduled_time' => $data['scheduled_time'] ?? null,
                    'schedule_group_id' => $groupId,
                    'destination' => trim((string) $data['destination']),
                    'destination_address' => isset($data['destination_address']) ? trim((string) $data['destination_address']) ?: null : null,
                    'latitude' => isset($data['latitude']) ? (float) $data['latitude'] : null,
                    'longitude' => isset($data['longitude']) ? (float) $data['longitude'] : null,
                    'place_id' => $data['place_id'] ?? null,
                    'companions' => isset($data['companions']) ? trim((string) $data['companions']) ?: null : null,
                    'description' => isset($data['description']) ? trim((string) $data['description']) ?: null : null,
                    'official_instruction' => isset($data['official_instruction']) ? trim((string) $data['official_instruction']) ?: null : null,
                    'status' => Assignment::STATUS_PENDING,
                ]);

                $items->push($assignment->load($this->relations()));
            }

            return $items;
        });

        $first = $created->first();
        SystemLogger::record(
            $authUser,
            'assignments',
            'created',
            $created->count() > 1
                ? "Programó {$created->count()} asignaciones hacia {$first?->destination}"
                : "Creó asignación #{$first?->id} hacia {$first?->destination} ({$first?->scheduled_date?->format('Y-m-d')})",
            $first,
            [
                'created_count' => $created->count(),
                'schedule_group_id' => $groupId,
                'vehicle_plate' => $first?->vehicle?->license_plate,
                'driver_name' => $first?->driver?->name,
            ],
            $request,
        );

        return response()->json([
            'created_count' => $created->count(),
            'schedule_group_id' => $groupId,
            'data' => $created->values(),
            'assignment' => $first,
        ], 201);
    }

    public function show(Assignment $assignment): JsonResponse
    {
        return response()->json($assignment->load($this->relations()));
    }

    public function update(UpdateAssignmentRequest $request, Assignment $assignment): JsonResponse
    {
        $data = $request->validated();

        foreach (['destination', 'destination_address', 'companions', 'description', 'official_instruction'] as $field) {
            if (array_key_exists($field, $data) && $data[$field] !== null) {
                $trimmed = trim((string) $data[$field]);
                $data[$field] = $trimmed !== '' ? $trimmed : null;
            }
        }

        $assignment->fill($data);
        $assignment->save();

        SystemLogger::record(
            $request->user(),
            'assignments',
            'updated',
            "Actualizó asignación #{$assignment->id} ({$assignment->destination})",
            $assignment,
            ['changes' => $assignment->getChanges()],
            $request,
        );

        return response()->json($assignment->load($this->relations()));
    }

    public function emergencyReassign(EmergencyReassignAssignmentRequest $request, Assignment $assignment): JsonResponse
    {
        $data = $request->validated();
        $authUser = $request->user();

        $updated = DB::transaction(function () use ($assignment, $data, $authUser, $request) {
            /** @var Assignment $locked */
            $locked = Assignment::query()->lockForUpdate()->findOrFail($assignment->id);

            if ($locked->status !== Assignment::STATUS_PENDING) {
                throw ValidationException::withMessages([
                    'status' => ['Solo se pueden reasignar por emergencia asignaciones en estado pendiente.'],
                ]);
            }

            $newDriverId = $authUser->canManageFleet() && ! empty($data['new_driver_id'])
                ? (int) $data['new_driver_id']
                : $authUser->id;

            if ((int) $locked->driver_id === $newDriverId) {
                throw ValidationException::withMessages([
                    'new_driver_id' => ['Esta asignación ya pertenece al motorista seleccionado.'],
                ]);
            }

            if (! $locked->original_driver_id) {
                $locked->original_driver_id = $locked->driver_id;
            }

            $locked->driver_id = $newDriverId;
            $locked->is_emergency_reassigned = true;
            $locked->reassigned_by = $authUser->id;
            $locked->reassignment_reason = trim((string) $data['reassignment_reason']);
            $locked->reassigned_at = now();
            $locked->save();

            $loaded = $locked->load($this->relations());

            SystemLogger::record(
                $authUser,
                'assignments',
                'emergency_reassigned',
                "Reasignación por emergencia en #{$loaded->id}: {$loaded->driver?->name} sustituyó a {$loaded->originalDriver?->name} ({$loaded->destination})",
                $loaded,
                [
                    'original_driver' => $loaded->originalDriver?->name,
                    'new_driver' => $loaded->driver?->name,
                    'reason' => $loaded->reassignment_reason,
                    'vehicle_plate' => $loaded->vehicle?->license_plate,
                ],
                $request,
            );

            return $loaded;
        });

        return response()->json($updated);
    }

    public function destroy(Request $request, Assignment $assignment): JsonResponse
    {
        $id = $assignment->id;
        $dest = $assignment->destination;
        $assignment->delete();

        SystemLogger::record(
            $request->user(),
            'assignments',
            'deleted',
            "Eliminó asignación #{$id} ({$dest})",
            null,
            ['assignment_id' => $id, 'destination' => $dest],
            $request,
        );

        return response()->json(null, 204);
    }
}
