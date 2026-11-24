<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Assignment extends Model
{
    public const STATUS_PENDING = 'pendiente';

    public const STATUS_IN_PROGRESS = 'en_curso';

    public const STATUS_COMPLETED = 'completada';

    public const STATUS_CANCELLED = 'cancelada';

    public const STATUSES = [
        self::STATUS_PENDING,
        self::STATUS_IN_PROGRESS,
        self::STATUS_COMPLETED,
        self::STATUS_CANCELLED,
    ];

    protected $fillable = [
        'vehicle_id',
        'driver_id',
        'created_by',
        'scheduled_date',
        'scheduled_time',
        'schedule_group_id',
        'destination',
        'destination_address',
        'latitude',
        'longitude',
        'place_id',
        'companions',
        'description',
        'official_instruction',
        'status',
        'is_emergency_reassigned',
        'original_driver_id',
        'reassigned_by',
        'reassignment_reason',
        'reassigned_at',
    ];

    protected function casts(): array
    {
        return [
            'scheduled_date' => 'date:Y-m-d',
            'latitude' => 'float',
            'longitude' => 'float',
            'is_emergency_reassigned' => 'boolean',
            'reassigned_at' => 'datetime',
        ];
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function driver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'driver_id');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function originalDriver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'original_driver_id');
    }

    public function reassignedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reassigned_by');
    }

    public function bitacoras(): HasMany
    {
        return $this->hasMany(Bitacora::class);
    }
}
