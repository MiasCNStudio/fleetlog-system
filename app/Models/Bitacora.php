<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Bitacora extends Model
{
    public const TYPE_SALIDA = 'salida';

    public const TYPE_REGRESO = 'regreso';

    public const FUEL_LEVELS = [
        'lleno',
        '3/4',
        '1/2',
        '1/4',
        'reserva',
    ];

    protected $fillable = [
        'vehicle_id',
        'user_id',
        'driver_id',
        'type',
        'recorded_at',
        'odometer_km',
        'fuel_level',
        'destination',
        'companions',
    ];

    protected function casts(): array
    {
        return [
            'recorded_at' => 'datetime',
            'odometer_km' => 'integer',
        ];
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function driver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'driver_id');
    }
}
