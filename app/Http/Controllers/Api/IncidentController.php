<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreIncidentRequest;
use App\Http\Requests\UpdateIncidentRequest;
use App\Models\Incident;
use App\Models\Vehicle;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class IncidentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $perPage = min((int) $request->query('per_page', 15), 100);

        $query = Incident::query()
            ->with([
                'vehicle:id,license_plate,brand,model,status',
                'reporter:id,name,email',
                'resolver:id,name',
            ])
            ->orderByDesc('reported_at')
            ->orderByDesc('id');

        if ($request->filled('vehicle_id')) {
            $query->where('vehicle_id', (int) $request->query('vehicle_id'));
        }

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        if ($request->filled('severity')) {
            $query->where('severity', $request->query('severity'));
        }

        return response()->json($query->paginate($perPage));
    }

    public function store(StoreIncidentRequest $request): JsonResponse
    {
        $data = $request->validated();
        $photo = $request->file('photo');
        $setMaintenance = $request->boolean('set_vehicle_maintenance');
        $authUser = $request->user();

        $incident = DB::transaction(function () use ($data, $photo, $setMaintenance, $authUser) {
            $photoPath = $photo ? $photo->store('incidents', 'public') : null;
            $severity = $data['severity'] ?? Incident::SEVERITY_MEDIUM;

            $created = Incident::query()->create([
                'vehicle_id' => $data['vehicle_id'],
                'user_id' => $authUser->id,
                'bitacora_id' => $data['bitacora_id'] ?? null,
                'title' => trim($data['title']),
                'description' => isset($data['description']) ? trim((string) $data['description']) : null,
                'severity' => $severity,
                'status' => Incident::STATUS_OPEN,
                'photo_path' => $photoPath,
                'reported_at' => now(),
            ]);

            if ($setMaintenance && $authUser->canManageFleet()) {
                Vehicle::query()
                    ->where('id', $data['vehicle_id'])
                    ->update(['status' => Vehicle::STATUS_MAINTENANCE]);
            }

            return $created;
        });

        return response()->json(
            $incident->load([
                'vehicle:id,license_plate,brand,model,status',
                'reporter:id,name,email',
            ]),
            201
        );
    }

    public function show(Incident $incident): JsonResponse
    {
        return response()->json(
            $incident->load([
                'vehicle:id,license_plate,brand,model,status',
                'reporter:id,name,email',
                'resolver:id,name',
                'bitacora:id,type,recorded_at,destination',
            ])
        );
    }

    public function update(UpdateIncidentRequest $request, Incident $incident): JsonResponse
    {
        $data = $request->validated();

        if (isset($data['status'])) {
            if ($data['status'] === Incident::STATUS_RESOLVED && $incident->status !== Incident::STATUS_RESOLVED) {
                $data['resolved_at'] = now();
                $data['resolved_by'] = $request->user()->id;
            } elseif ($data['status'] !== Incident::STATUS_RESOLVED) {
                $data['resolved_at'] = null;
                $data['resolved_by'] = null;
            }
        }

        $incident->fill($data);
        $incident->save();

        return response()->json(
            $incident->load([
                'vehicle:id,license_plate,brand,model,status',
                'reporter:id,name,email',
                'resolver:id,name',
            ])
        );
    }

    public function destroy(Incident $incident): JsonResponse
    {
        if ($incident->photo_path) {
            Storage::disk('public')->delete($incident->photo_path);
        }

        $incident->delete();

        return response()->json(null, 204);
    }
}
