<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bitacora;
use App\Models\FuelLog;
use App\Models\Vehicle;
use App\Services\SystemLogger;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class FuelLogController extends Controller
{
    private function relations(): array
    {
        return [
            'vehicle:id,license_plate,plate_type,plate_number,brand,model,current_odometer',
            'recorder:id,name',
            'driver:id,name,driver_code',
            'bitacora:id,type,trip_category,destination,recorded_at',
        ];
    }

    public function index(Request $request): JsonResponse
    {
        $perPage = min((int) $request->query('per_page', 15), 100);

        $query = FuelLog::query()
            ->with($this->relations())
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

    public function summary(Request $request): JsonResponse
    {
        $range = (string) $request->query('range', 'week');
        $dateFromRaw = $request->query('date_from');
        $dateToRaw = $request->query('date_to');
        $filterVehicleId = $request->filled('vehicle_id') ? (int) $request->query('vehicle_id') : null;

        if ($dateFromRaw || $dateToRaw) {
            $from = $dateFromRaw ? Carbon::parse($dateFromRaw)->startOfDay() : Carbon::now()->subDays(6)->startOfDay();
            $to = $dateToRaw ? Carbon::parse($dateToRaw)->endOfDay() : Carbon::now()->endOfDay();
        } elseif ($range === 'month') {
            $from = Carbon::now()->subDays(29)->startOfDay();
            $to = Carbon::now()->endOfDay();
        } elseif ($range === 'all') {
            $from = Carbon::createFromTimestamp(0);
            $to = Carbon::now()->endOfDay();
        } else {
            $from = Carbon::now()->subDays(6)->startOfDay();
            $to = Carbon::now()->endOfDay();
        }

        $fuelQuery = FuelLog::query()
            ->whereBetween('filled_at', [$from, $to]);
        if ($filterVehicleId) {
            $fuelQuery->where('vehicle_id', $filterVehicleId);
        }
        $fuelLogs = $fuelQuery->get();

        $bitQuery = Bitacora::query()
            ->whereBetween('recorded_at', [$from, $to]);
        if ($filterVehicleId) {
            $bitQuery->where('vehicle_id', $filterVehicleId);
        }
        $bitacoras = $bitQuery->get(['id', 'vehicle_id', 'odometer_km', 'recorded_at']);

        $vehicleIds = $fuelLogs->pluck('vehicle_id')
            ->merge($bitacoras->pluck('vehicle_id'))
            ->unique()
            ->values();

        $vehicles = Vehicle::query()
            ->whereIn('id', $vehicleIds)
            ->orderBy('license_plate')
            ->get()
            ->keyBy('id');

        $byVehicle = [];
        $totalKm = 0;
        $totalGallons = 0.0;
        $totalCost = 0.0;
        $totalRefills = 0;

        foreach ($vehicleIds as $vid) {
            $v = $vehicles->get($vid);
            if (! $v) {
                continue;
            }

            $vFuels = $fuelLogs->where('vehicle_id', $vid);
            $vBits = $bitacoras->where('vehicle_id', $vid);

            $odometers = $vFuels->pluck('odometer_km')
                ->merge($vBits->pluck('odometer_km'))
                ->filter(fn ($km) => $km !== null && (int) $km > 0)
                ->map(fn ($km) => (int) $km);

            $spanKm = $odometers->count() >= 2
                ? max(0, $odometers->max() - $odometers->min())
                : 0;
            $fuelIntervalKm = (int) $vFuels->sum(fn (FuelLog $f) => (int) ($f->km_since_last ?? 0));
            $kmTraveled = max($spanKm, $fuelIntervalKm);

            $gallons = round((float) $vFuels->sum('gallons'), 2);
            $cost = round((float) $vFuels->sum(fn (FuelLog $f) => (float) ($f->cost_usd ?? 0)), 2);
            $refills = $vFuels->count();

            $costPerKm = ($kmTraveled > 0 && $cost > 0) ? round($cost / $kmTraveled, 3) : null;
            $kmPerGallon = ($kmTraveled > 0 && $gallons > 0) ? round($kmTraveled / $gallons, 2) : null;

            $byVehicle[] = [
                'vehicle_id' => $v->id,
                'license_plate' => $v->license_plate,
                'plate_type' => $v->plate_type,
                'plate_number' => $v->plate_number,
                'brand' => $v->brand,
                'model' => $v->model,
                'km_traveled' => $kmTraveled,
                'gallons' => $gallons,
                'cost_usd' => $cost,
                'cost_per_km' => $costPerKm,
                'km_per_gallon' => $kmPerGallon,
                'refills_count' => $refills,
            ];

            $totalKm += $kmTraveled;
            $totalGallons += $gallons;
            $totalCost += $cost;
            $totalRefills += $refills;
        }

        $totalGallons = round($totalGallons, 2);
        $totalCost = round($totalCost, 2);

        return response()->json([
            'period' => [
                'range' => $range,
                'date_from' => $from->toDateString(),
                'date_to' => $to->toDateString(),
            ],
            'totals' => [
                'km_traveled' => $totalKm,
                'gallons' => $totalGallons,
                'cost_usd' => $totalCost,
                'cost_per_km' => ($totalKm > 0 && $totalCost > 0) ? round($totalCost / $totalKm, 3) : null,
                'km_per_gallon' => ($totalKm > 0 && $totalGallons > 0) ? round($totalKm / $totalGallons, 2) : null,
                'refills_count' => $totalRefills,
            ],
            'by_vehicle' => $byVehicle,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'vehicle_id' => ['required', 'integer', 'exists:vehicles,id'],
            'driver_id' => ['nullable', 'integer', 'exists:users,id'],
            'bitacora_id' => ['nullable', 'integer', 'exists:bitacoras,id'],
            'odometer_km' => ['required', 'integer', 'min:0'],
            'gallons' => ['required', 'numeric', 'gt:0', 'max:500'],
            'cost_usd' => ['nullable', 'numeric', 'min:0'],
            'fuel_type' => ['sometimes', Rule::in(FuelLog::FUEL_TYPES)],
            'station' => ['nullable', 'string', 'max:150'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'location_address' => ['nullable', 'string', 'max:255'],
            'full_tank' => ['sometimes', 'boolean'],
            'filled_at' => ['nullable', 'date'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'receipt' => ['nullable', 'file', 'mimes:jpg,jpeg,png,webp,pdf', 'max:10240'],
        ]);

        $authUser = $request->user();
        $receiptFile = $request->file('receipt');
        $receiptPath = null;
        $receiptName = null;

        if ($receiptFile) {
            $receiptPath = $receiptFile->store('fuel_receipts', 'public');
            $receiptName = mb_substr($receiptFile->getClientOriginalName(), 0, 180);
        }

        $lat = isset($data['latitude']) ? (float) $data['latitude'] : null;
        $lng = isset($data['longitude']) ? (float) $data['longitude'] : null;
        $station = isset($data['station']) ? trim((string) $data['station']) : '';
        $locationAddress = isset($data['location_address']) ? trim((string) $data['location_address']) : '';

        if ($lat !== null && $lng !== null && ($locationAddress === '' || $station === '')) {
            $geo = $this->resolveFuelLocationHint($lat, $lng);
            if ($locationAddress === '' && $geo['address'] !== '') {
                $locationAddress = $geo['address'];
            }
            if ($station === '' && $geo['name'] !== '') {
                $station = $geo['name'];
            }
        }

        $log = DB::transaction(function () use (
            $data,
            $authUser,
            $request,
            $receiptPath,
            $receiptName,
            $lat,
            $lng,
            $station,
            $locationAddress,
        ) {
            /** @var Vehicle $vehicle */
            $vehicle = Vehicle::query()->lockForUpdate()->findOrFail((int) $data['vehicle_id']);
            $odometer = (int) $data['odometer_km'];

            if ($vehicle->current_odometer > 0 && $odometer < $vehicle->current_odometer) {
                throw ValidationException::withMessages([
                    'odometer_km' => ["El odómetro no puede ser menor al actual ({$vehicle->current_odometer} km)."],
                ]);
            }

            $bitacoraId = isset($data['bitacora_id']) ? (int) $data['bitacora_id'] : null;
            if (! $bitacoraId && $vehicle->nextBitacoraType() === Bitacora::TYPE_REGRESO) {
                $bitacoraId = $vehicle->bitacoras()
                    ->where('type', Bitacora::TYPE_SALIDA)
                    ->orderByDesc('recorded_at')
                    ->orderByDesc('id')
                    ->value('id');
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
                'bitacora_id' => $bitacoraId,
                'filled_at' => ! empty($data['filled_at']) ? $data['filled_at'] : now(),
                'odometer_km' => $odometer,
                'gallons' => $gallons,
                'cost_usd' => isset($data['cost_usd']) ? round((float) $data['cost_usd'], 2) : null,
                'fuel_type' => $data['fuel_type'] ?? 'regular',
                'station' => $station !== '' ? mb_substr($station, 0, 150) : null,
                'latitude' => $lat,
                'longitude' => $lng,
                'location_address' => $locationAddress !== '' ? mb_substr($locationAddress, 0, 255) : null,
                'full_tank' => $data['full_tank'] ?? true,
                'km_since_last' => $kmSinceLast,
                'km_per_gallon' => $kmPerGallon,
                'notes' => $data['notes'] ?? null,
                'receipt_path' => $receiptPath,
                'receipt_name' => $receiptName,
            ]);

            if ($odometer > $vehicle->current_odometer) {
                $vehicle->current_odometer = $odometer;
                $vehicle->save();
            }

            SystemLogger::record(
                $authUser,
                'fuel',
                'created',
                "Registró carga de {$gallons} gal ({$created->fuel_type}) en {$vehicle->license_plate} a {$odometer} km"
                    .($created->station ? " en {$created->station}" : ''),
                $created,
                [
                    'vehicle_plate' => $vehicle->license_plate,
                    'odometer_km' => $odometer,
                    'gallons' => $gallons,
                    'cost_usd' => $created->cost_usd,
                    'station' => $created->station,
                    'latitude' => $lat,
                    'longitude' => $lng,
                    'has_receipt' => $receiptPath !== null,
                    'km_per_gallon' => $kmPerGallon,
                    'maintenance_status' => $vehicle->maintenance_status,
                ],
                $request,
            );

            return $created;
        });

        return response()->json(
            $log->load($this->relations()),
            201,
        );
    }

    public function uploadReceipt(Request $request, FuelLog $fuelLog): JsonResponse
    {
        $authUser = $request->user();
        $isOwner = (int) $fuelLog->user_id === (int) $authUser->id
            || (int) $fuelLog->driver_id === (int) $authUser->id;

        if (! $authUser->canManageFleet() && ! $isOwner) {
            return response()->json([
                'message' => 'No tienes permiso para adjuntar comprobante a esta carga.',
            ], 403);
        }

        $request->validate([
            'receipt' => ['required', 'file', 'mimes:jpg,jpeg,png,webp,pdf', 'max:10240'],
        ]);

        $file = $request->file('receipt');
        if ($fuelLog->receipt_path) {
            Storage::disk('public')->delete($fuelLog->receipt_path);
        }

        $fuelLog->receipt_path = $file->store('fuel_receipts', 'public');
        $fuelLog->receipt_name = mb_substr($file->getClientOriginalName(), 0, 180);
        $fuelLog->save();

        SystemLogger::record(
            $authUser,
            'fuel',
            'receipt_attached',
            "Adjuntó comprobante ({$fuelLog->receipt_name}) a carga de combustible #{$fuelLog->id}",
            $fuelLog,
            [
                'fuel_log_id' => $fuelLog->id,
                'receipt_name' => $fuelLog->receipt_name,
            ],
            $request,
        );

        return response()->json($fuelLog->fresh($this->relations()));
    }

    public function destroy(Request $request, FuelLog $fuelLog): JsonResponse
    {
        $id = $fuelLog->id;
        $plate = $fuelLog->vehicle?->license_plate ?? '';

        if ($fuelLog->receipt_path) {
            Storage::disk('public')->delete($fuelLog->receipt_path);
        }

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

    private function resolveFuelLocationHint(float $lat, float $lng): array
    {
        if (app()->runningUnitTests()) {
            return ['name' => '', 'address' => ''];
        }

        try {
            $res = Http::timeout(4)
                ->withHeaders([
                    'User-Agent' => 'FleetlogSystem/1.0 (https://fleetlog.miascn.org)',
                    'Accept-Language' => 'es',
                ])
                ->get('https://nominatim.openstreetmap.org/reverse', [
                    'lat' => $lat,
                    'lon' => $lng,
                    'format' => 'jsonv2',
                    'zoom' => 18,
                    'addressdetails' => 1,
                ]);

            if ($res->ok()) {
                $body = $res->json() ?? [];
                $name = trim((string) ($body['name'] ?? ($body['address']['amenity'] ?? '')));
                $address = trim((string) ($body['display_name'] ?? ''));

                return [
                    'name' => $name,
                    'address' => $address,
                ];
            }
        } catch (\Throwable) {
            /* fallback silencioso */
        }

        return ['name' => '', 'address' => ''];
    }
}
