<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreUserRequest;
use App\Http\Requests\UpdateUserRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class UserController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $perPage = min((int) $request->query('per_page', 15), 100);
        $query = User::query()->orderBy('name');

        if ($request->filled('role')) {
            $query->where('role', $request->query('role'));
        }

        if ($request->filled('person_type')) {
            $query->where('person_type', $request->query('person_type'));
        }

        if ($request->filled('search')) {
            $term = '%'.trim((string) $request->query('search')).'%';
            $query->where(function ($q) use ($term) {
                $q->where('name', 'like', $term)
                    ->orWhere('email', 'like', $term)
                    ->orWhere('driver_code', 'like', $term);
            });
        }

        return response()->json($query->paginate($perPage));
    }

    public function driverOptions(): JsonResponse
    {
        $drivers = User::query()
            ->select(['id', 'name', 'person_type', 'role', 'driver_code'])
            ->where(function ($q) {
                $q->where('person_type', 'motorista')
                    ->orWhere('role', User::ROLE_DRIVER);
            })
            ->orderBy('name')
            ->get();

        return response()->json(['data' => $drivers]);
    }

    public function store(StoreUserRequest $request): JsonResponse
    {
        $data = $request->validated();
        $photo = $request->file('photo');

        unset($data['photo']);
        $data['password'] = Hash::make($data['password']);

        if (($data['person_type'] ?? null) === 'funcionario') {
            $data['driver_code'] = null;
        }

        if (! isset($data['role'])) {
            $data['role'] = ($data['person_type'] ?? null) === 'motorista'
                ? User::ROLE_DRIVER
                : User::ROLE_DISPATCHER;
        }

        if ($photo) {
            $data['photo_path'] = $photo->store('users', 'public');
        }

        $user = User::query()->create($data);

        return response()->json($user->fresh(), 201);
    }

    public function show(User $user): JsonResponse
    {
        return response()->json($user);
    }

    public function update(UpdateUserRequest $request, User $user): JsonResponse
    {
        $data = $request->validated();
        $photo = $request->file('photo');

        unset($data['photo']);

        if (array_key_exists('password', $data)) {
            if ($data['password'] === null || $data['password'] === '') {
                unset($data['password']);
            } else {
                $data['password'] = Hash::make($data['password']);
            }
        }

        $personType = $data['person_type'] ?? $user->person_type;
        if ($personType === 'funcionario') {
            $data['driver_code'] = null;
        }

        if ($photo) {
            if ($user->photo_path) {
                Storage::disk('public')->delete($user->photo_path);
            }
            $data['photo_path'] = $photo->store('users', 'public');
        }

        $user->fill($data);
        $user->save();

        return response()->json($user->fresh());
    }

    public function destroy(Request $request, User $user): JsonResponse
    {
        if ($request->user()?->id === $user->id) {
            return response()->json([
                'message' => 'No puedes eliminar tu propia cuenta activa.',
            ], 422);
        }

        if ($user->photo_path) {
            Storage::disk('public')->delete($user->photo_path);
        }

        $user->delete();

        return response()->json(null, 204);
    }
}
