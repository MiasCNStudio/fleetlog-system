<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FuelLog extends Model
{
    public const FUEL_TYPES = [
        'regular',
        'especial',
        'diesel',
    ];

    protected $fillable = [
        'vehicle_id',
        'user_id',
        'driver_id',
        'filled_at',
        'odometer_km',
        'gallons',
        'cost_usd',
        'fuel_type',
        'station',
        'full_tank',
        'km_since_last',
        'km_per_gallon',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'filled_at' => 'datetime',
            'odometer_km' => 'integer',
            'gallons' => 'float',
            'cost_usd' => 'float',
            'full_tank' => 'boolean',
            'km_since_last' => 'integer',
            'km_per_gallon' => 'float',
        ];
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function recorder(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function driver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'driver_id');
    }
}
