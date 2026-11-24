<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Bitacora extends Model
{
    public const TYPE_SALIDA = 'salida';

    public const TYPE_REGRESO = 'regreso';

    public const CATEGORY_ASSIGNMENT = 'asignacion';

    public const CATEGORY_PERSONAL = 'personal';

    public const CATEGORY_UNPLANNED = 'imprevisto';

    public const CATEGORIES = [
        self::CATEGORY_ASSIGNMENT,
        self::CATEGORY_PERSONAL,
        self::CATEGORY_UNPLANNED,
    ];

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
        'assignment_id',
        'type',
        'trip_category',
        'recorded_at',
        'odometer_km',
        'fuel_level',
        'destination',
        'destination_address',
        'latitude',
        'longitude',
        'place_id',
        'companions',
        'official_instruction',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'recorded_at' => 'datetime',
            'odometer_km' => 'integer',
            'latitude' => 'float',
            'longitude' => 'float',
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

    public function assignment(): BelongsTo
    {
        return $this->belongsTo(Assignment::class);
    }
}
