<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreBitacoraRequest;
use App\Http\Requests\UpdateBitacoraRequest;
use App\Models\Bitacora;
use App\Models\Vehicle;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class BitacoraController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $perPage = min((int) $request->query('per_page', 15), 100);

        $query = Bitacora::query()
            ->with(['vehicle:id,license_plate,brand,model', 'user:id,name,email'])
            ->orderByDesc('recorded_at');

        if ($request->filled('vehicle_id')) {
            $query->where('vehicle_id', (int) $request->query('vehicle_id'));
        }

        return response()->json($query->paginate($perPage));
    }

    public function nextType(Vehicle $vehicle): JsonResponse
    {
        return response()->json([
            'type' => $vehicle->nextBitacoraType(),
        ]);
    }

    public function store(StoreBitacoraRequest $request): JsonResponse
    {
        $data = $request->validated();
        $vehicle = Vehicle::query()->findOrFail($data['vehicle_id']);
        $type = $vehicle->nextBitacoraType();

        if ($type === Bitacora::TYPE_SALIDA && trim((string) ($data['destination'] ?? '')) === '') {
            throw ValidationException::withMessages([
                'destination' => ['Indica a dónde se dirige el vehículo al registrar una salida.'],
            ]);
        }

        $destRaw = isset($data['destination']) ? trim((string) $data['destination']) : '';
        $destination = $destRaw !== '' ? $destRaw : null;
        $compRaw = isset($data['companions']) ? trim((string) $data['companions']) : '';
        $companions = $compRaw !== '' ? $compRaw : null;

        $bitacora = Bitacora::query()->create([
            'vehicle_id' => $vehicle->id,
            'user_id' => $request->user()->id,
            'type' => $type,
            'recorded_at' => now(),
            'destination' => $destination,
            'companions' => $companions,
        ]);

        return response()->json($bitacora->load(['vehicle:id,license_plate,brand,model', 'user:id,name,email']), 201);
    }

    public function show(Bitacora $bitacora): JsonResponse
    {
        return response()->json(
            $bitacora->load(['vehicle:id,license_plate,brand,model,color', 'user:id,name,email'])
        );
    }

    public function update(UpdateBitacoraRequest $request, Bitacora $bitacora): JsonResponse
    {
        $bitacora->fill($request->validated());
        $bitacora->save();

        return response()->json($bitacora->load(['vehicle:id,license_plate,brand,model', 'user:id,name,email']));
    }

    public function destroy(Bitacora $bitacora): JsonResponse
    {
        $bitacora->delete();

        return response()->json(null, 204);
    }
}
