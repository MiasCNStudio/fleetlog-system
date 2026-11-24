<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TripTrackingSession extends Model
{
    public const STATUS_ACTIVE = 'activa';

    public const STATUS_FINISHED = 'finalizada';

    public const STATUS_INTERRUPTED = 'interrumpida';

    public const STATUSES = [
        self::STATUS_ACTIVE,
        self::STATUS_FINISHED,
        self::STATUS_INTERRUPTED,
    ];

    protected $fillable = [
        'salida_bitacora_id',
        'regreso_bitacora_id',
        'assignment_id',
        'vehicle_id',
        'driver_id',
        'started_by_user_id',
        'device_uuid',
        'device_name',
        'device_platform',
        'started_by_token_id',
        'status',
        'started_at',
        'ended_at',
        'last_ping_at',
        'last_latitude',
        'last_longitude',
        'last_speed_kmh',
        'last_battery_level',
        'points_count',
        'gps_distance_km',
        'declared_distance_km',
        'max_speed_kmh',
        'stops_count',
        'has_sos_alert',
        'summary_json',
    ];

    protected function casts(): array
    {
        return [
            'started_at' => 'datetime',
            'ended_at' => 'datetime',
            'last_ping_at' => 'datetime',
            'last_latitude' => 'float',
            'last_longitude' => 'float',
            'last_speed_kmh' => 'float',
            'last_battery_level' => 'integer',
            'points_count' => 'integer',
            'gps_distance_km' => 'float',
            'declared_distance_km' => 'integer',
            'max_speed_kmh' => 'float',
            'stops_count' => 'integer',
            'has_sos_alert' => 'boolean',
            'summary_json' => 'array',
        ];
    }

    public function salidaBitacora(): BelongsTo
    {
        return $this->belongsTo(Bitacora::class, 'salida_bitacora_id');
    }

    public function regresoBitacora(): BelongsTo
    {
        return $this->belongsTo(Bitacora::class, 'regreso_bitacora_id');
    }

    public function assignment(): BelongsTo
    {
        return $this->belongsTo(Assignment::class);
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function driver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'driver_id');
    }

    public function startedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'started_by_user_id');
    }

    public function points(): HasMany
    {
        return $this->hasMany(TripLocationPoint::class, 'tracking_session_id')->orderBy('recorded_at')->orderBy('id');
    }
}
