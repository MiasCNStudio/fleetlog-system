<?php

use App\Http\Controllers\Api\AssignmentController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BitacoraController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\IncidentController;
use App\Http\Controllers\Api\PlaceController;
use App\Http\Controllers\Api\SystemLogController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\VehicleController;
use Illuminate\Support\Facades\Route;

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/dashboard', DashboardController::class);

    // Mapas y búsqueda de lugares (Google Maps / OpenStreetMap)
    Route::get('maps/config', [PlaceController::class, 'config']);
    Route::get('places/search', [PlaceController::class, 'search']);
    Route::get('places/reverse', [PlaceController::class, 'reverse']);

    // Opciones ligeras para web y app móvil
    Route::get('vehicles/options', [VehicleController::class, 'options']);
    Route::get('drivers/options', [UserController::class, 'driverOptions']);
    Route::get('assignments/options', [AssignmentController::class, 'options']);
    Route::get('vehicles/{vehicle}/siguiente-tipo-bitacora', [BitacoraController::class, 'nextType']);

    // Administración de usuarios (solo admin)
    Route::middleware('role:admin')->group(function () {
        Route::post('users/{user}', [UserController::class, 'update']);
        Route::apiResource('users', UserController::class);
    });

    // Vehículos: lectura para todos; alta/edición para admin/despachador; borrado solo admin
    Route::get('vehicles', [VehicleController::class, 'index']);
    Route::get('vehicles/{vehicle}', [VehicleController::class, 'show']);
    Route::middleware('role:admin,despachador')->group(function () {
        Route::post('vehicles', [VehicleController::class, 'store']);
        Route::post('vehicles/{vehicle}', [VehicleController::class, 'update']);
        Route::put('vehicles/{vehicle}', [VehicleController::class, 'update']);
        Route::patch('vehicles/{vehicle}', [VehicleController::class, 'update']);
    });
    Route::delete('vehicles/{vehicle}', [VehicleController::class, 'destroy'])->middleware('role:admin');

    // Asignaciones (agenda diaria/semanal/mensual): lectura y reasignación de emergencia para todos; alta/edición para admin/despachador
    Route::get('assignments', [AssignmentController::class, 'index']);
    Route::get('assignments/{assignment}', [AssignmentController::class, 'show']);
    Route::post('assignments/{assignment}/emergency-reassign', [AssignmentController::class, 'emergencyReassign']);
    Route::middleware('role:admin,despachador')->group(function () {
        Route::post('assignments', [AssignmentController::class, 'store']);
        Route::put('assignments/{assignment}', [AssignmentController::class, 'update']);
        Route::patch('assignments/{assignment}', [AssignmentController::class, 'update']);
    });
    Route::delete('assignments/{assignment}', [AssignmentController::class, 'destroy'])->middleware('role:admin,despachador');

    // Bitácoras: lectura/registro para todos; edición para admin/despachador; borrado solo admin
    Route::get('bitacoras', [BitacoraController::class, 'index']);
    Route::get('bitacoras/{bitacora}', [BitacoraController::class, 'show']);
    Route::post('bitacoras', [BitacoraController::class, 'store']);
    Route::middleware('role:admin,despachador')->group(function () {
        Route::put('bitacoras/{bitacora}', [BitacoraController::class, 'update']);
        Route::patch('bitacoras/{bitacora}', [BitacoraController::class, 'update']);
    });
    Route::delete('bitacoras/{bitacora}', [BitacoraController::class, 'destroy'])->middleware('role:admin');

    // Incidencias: lectura/reporte para todos; seguimiento para admin/despachador; borrado solo admin
    Route::get('incidents', [IncidentController::class, 'index']);
    Route::get('incidents/{incident}', [IncidentController::class, 'show']);
    Route::post('incidents', [IncidentController::class, 'store']);
    Route::middleware('role:admin,despachador')->group(function () {
        Route::put('incidents/{incident}', [IncidentController::class, 'update']);
        Route::patch('incidents/{incident}', [IncidentController::class, 'update']);
    });
    Route::delete('incidents/{incident}', [IncidentController::class, 'destroy'])->middleware('role:admin');

    // Bitácora del sistema (auditoría): solo admin y jefe de motoristas (despachador)
    Route::get('system-logs', [SystemLogController::class, 'index'])->middleware('role:admin,despachador');
});
