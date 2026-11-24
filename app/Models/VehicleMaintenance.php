<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VehicleMaintenance extends Model
{
    public const STATUS_SCHEDULED = 'programado';

    public const STATUS_COMPLETED = 'completado';

    public const STATUS_CANCELLED = 'cancelado';

    public const STATUSES = [
        self::STATUS_SCHEDULED,
        self::STATUS_COMPLETED,
        self::STATUS_CANCELLED,
    ];

    protected $fillable = [
        'vehicle_id',
        'user_id',
        'title',
        'description',
        'status',
        'scheduled_odometer_km',
        'completed_odometer_km',
        'scheduled_date',
        'completed_at',
        'workshop',
        'cost_usd',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'scheduled_odometer_km' => 'integer',
            'completed_odometer_km' => 'integer',
            'scheduled_date' => 'date:Y-m-d',
            'completed_at' => 'datetime',
            'cost_usd' => 'float',
        ];
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
