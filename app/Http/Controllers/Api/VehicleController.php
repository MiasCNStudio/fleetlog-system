<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreVehicleRequest;
use App\Http\Requests\UpdateVehicleRequest;
use App\Models\Vehicle;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class VehicleController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $perPage = min((int) $request->query('per_page', 15), 100);

        return response()->json(
            Vehicle::query()->orderBy('license_plate')->paginate($perPage)
        );
    }

    public function store(StoreVehicleRequest $request): JsonResponse
    {
        $data = $request->validated();
        $photo = $request->file('photo');

        unset($data['photo']);

        if ($photo) {
            $data['photo_path'] = $photo->store('vehicles', 'public');
        }

        $vehicle = Vehicle::query()->create($data);

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

        if ($photo) {
            if ($vehicle->photo_path) {
                Storage::disk('public')->delete($vehicle->photo_path);
            }
            $data['photo_path'] = $photo->store('vehicles', 'public');
        }

        $vehicle->fill($data);
        $vehicle->save();

        return response()->json($vehicle->fresh());
    }

    public function destroy(Vehicle $vehicle): JsonResponse
    {
        if ($vehicle->photo_path) {
            Storage::disk('public')->delete($vehicle->photo_path);
        }

        $vehicle->delete();

        return response()->json(null, 204);
    }
}
