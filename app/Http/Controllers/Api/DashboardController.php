<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bitacora;
use App\Models\Incident;
use App\Models\Vehicle;
use Carbon\CarbonPeriod;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function __invoke(Request $request)
    {
        $days = in_array((int) $request->query('days', 7), [7, 30], true)
            ? (int) $request->query('days', 7)
            : 7;

        $totalVehicles = Vehicle::query()->count();
        $availableVehicles = Vehicle::query()->where('status', Vehicle::STATUS_AVAILABLE)->count();
        $maintenanceVehicles = Vehicle::query()->where('status', Vehicle::STATUS_MAINTENANCE)->count();

        $inRouteVehicles = Vehicle::query()
            ->where('status', Vehicle::STATUS_IN_ROUTE)
            ->with(['latestBitacora' => function ($q) {
                $q->with(['driver:id,name,driver_code', 'user:id,name']);
            }])
            ->orderBy('license_plate')
            ->get();

        $activeTripsCount = $inRouteVehicles->count();
        $driversInRouteCount = $inRouteVehicles
            ->map(fn (Vehicle $v) => $v->latestBitacora?->driver_id ?? $v->latestBitacora?->user_id)
            ->filter()
            ->unique()
            ->count();

        $incidentsToday = Incident::query()->whereDate('reported_at', today())->count();
        $openIncidents = Incident::query()
            ->whereIn('status', [Incident::STATUS_OPEN, Incident::STATUS_IN_REVIEW])
            ->count();

        $startDate = now()->subDays($days - 1)->startOfDay();
        $movements = Bitacora::query()
            ->where('recorded_at', '>=', $startDate)
            ->get(['type', 'recorded_at']);

        $byDate = [];
        foreach ($movements as $mov) {
            $key = $mov->recorded_at->format('Y-m-d');
            if (! isset($byDate[$key])) {
                $byDate[$key] = ['salidas' => 0, 'regresos' => 0];
            }
            if ($mov->type === Bitacora::TYPE_SALIDA) {
                $byDate[$key]['salidas']++;
            } else {
                $byDate[$key]['regresos']++;
            }
        }

        $categories = [];
        $values = [];
        $salidasSeries = [];
        $regresosSeries = [];

        $period = CarbonPeriod::create($startDate, now()->startOfDay());
        foreach ($period as $date) {
            $key = $date->format('Y-m-d');
            $daySalidas = $byDate[$key]['salidas'] ?? 0;
            $dayRegresos = $byDate[$key]['regresos'] ?? 0;

            $categories[] = $date->format('d/m');
            $values[] = $daySalidas;
            $salidasSeries[] = $daySalidas;
            $regresosSeries[] = $dayRegresos;
        }

        $activeTrips = $inRouteVehicles->map(function (Vehicle $vehicle) {
            $b = $vehicle->latestBitacora;

            return [
                'vehicle_id' => $vehicle->id,
                'license_plate' => $vehicle->license_plate,
                'brand' => $vehicle->brand,
                'model' => $vehicle->model,
                'destination' => $b?->destination,
                'recorded_at' => $b?->recorded_at?->toIso8601String(),
                'driver_name' => $b?->driver?->name ?? $b?->user?->name,
                'odometer_km' => $b?->odometer_km ?? $vehicle->current_odometer,
            ];
        })->values();

        $recentIncidents = Incident::query()
            ->with(['vehicle:id,license_plate,brand,model', 'reporter:id,name'])
            ->whereIn('status', [Incident::STATUS_OPEN, Incident::STATUS_IN_REVIEW])
            ->orderByDesc('reported_at')
            ->limit(5)
            ->get();

        return response()->json([
            'summary' => [
                'viajes_activos' => $activeTripsCount,
                'unidades_disponibles' => $availableVehicles,
                'conductores_en_ruta' => $driversInRouteCount,
                'incidencias_hoy' => $incidentsToday,
                'incidencias_abiertas' => $openIncidents,
                'unidades_mantenimiento' => $maintenanceVehicles,
                'total_vehiculos' => $totalVehicles,
            ],
            'series' => [
                'categories' => $categories,
                'values' => $values,
                'salidas' => $salidasSeries,
                'regresos' => $regresosSeries,
            ],
            'active_trips' => $activeTrips,
            'recent_incidents' => $recentIncidents,
            'user' => $request->user(),
        ]);
    }
}
