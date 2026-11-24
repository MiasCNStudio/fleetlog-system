<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TripLocationPoint extends Model
{
    public const SOURCE_START = 'start';

    public const SOURCE_FOREGROUND = 'foreground';

    public const SOURCE_BACKGROUND = 'background';

    public const SOURCE_OFFLINE_SYNC = 'offline_sync';

    public const SOURCE_SOS = 'sos';

    public const SOURCE_END = 'end';

    public const SOURCES = [
        self::SOURCE_START,
        self::SOURCE_FOREGROUND,
        self::SOURCE_BACKGROUND,
        self::SOURCE_OFFLINE_SYNC,
        self::SOURCE_SOS,
        self::SOURCE_END,
    ];

    protected $fillable = [
        'tracking_session_id',
        'recorded_at',
        'latitude',
        'longitude',
        'accuracy_m',
        'speed_kmh',
        'heading',
        'altitude_m',
        'battery_level',
        'is_moving',
        'source',
        'address_hint',
    ];

    protected function casts(): array
    {
        return [
            'recorded_at' => 'datetime',
            'latitude' => 'float',
            'longitude' => 'float',
            'accuracy_m' => 'float',
            'speed_kmh' => 'float',
            'heading' => 'float',
            'altitude_m' => 'float',
            'battery_level' => 'integer',
            'is_moving' => 'boolean',
        ];
    }

    public function trackingSession(): BelongsTo
    {
        return $this->belongsTo(TripTrackingSession::class, 'tracking_session_id');
    }
}
