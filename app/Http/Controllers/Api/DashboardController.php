<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function __invoke(Request $request)
    {
        return response()->json([
            'summary' => [
                'viajes_activos' => 12,
                'unidades_disponibles' => 34,
                'conductores_en_ruta' => 18,
                'incidencias_hoy' => 2,
            ],
            'series' => [
                'categories' => ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'],
                'values' => [14, 19, 17, 22, 26, 21, 24],
            ],
            'user' => $request->user(),
        ]);
    }
}
