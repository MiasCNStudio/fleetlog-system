<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BitacoraController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\VehicleController;
use Illuminate\Support\Facades\Route;

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/dashboard', DashboardController::class);

    Route::post('users/{user}', [UserController::class, 'update']);
    Route::post('vehicles/{vehicle}', [VehicleController::class, 'update']);
    Route::get('vehicles/{vehicle}/siguiente-tipo-bitacora', [BitacoraController::class, 'nextType']);
    Route::apiResource('users', UserController::class);
    Route::apiResource('vehicles', VehicleController::class);
    Route::apiResource('bitacoras', BitacoraController::class);
});
