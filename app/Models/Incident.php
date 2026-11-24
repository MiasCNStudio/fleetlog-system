<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class Incident extends Model
{
    public const SEVERITY_LOW = 'baja';

    public const SEVERITY_MEDIUM = 'media';

    public const SEVERITY_HIGH = 'alta';

    public const SEVERITY_CRITICAL = 'critica';

    public const SEVERITIES = [
        self::SEVERITY_LOW,
        self::SEVERITY_MEDIUM,
        self::SEVERITY_HIGH,
        self::SEVERITY_CRITICAL,
    ];

    public const STATUS_OPEN = 'abierta';

    public const STATUS_IN_REVIEW = 'en_revision';

    public const STATUS_RESOLVED = 'resuelta';

    public const STATUSES = [
        self::STATUS_OPEN,
        self::STATUS_IN_REVIEW,
        self::STATUS_RESOLVED,
    ];

    protected $fillable = [
        'vehicle_id',
        'user_id',
        'bitacora_id',
        'title',
        'description',
        'severity',
        'status',
        'photo_path',
        'reported_at',
        'resolved_at',
        'resolved_by',
    ];

    protected $appends = [
        'photo_url',
    ];

    protected function casts(): array
    {
        return [
            'reported_at' => 'datetime',
            'resolved_at' => 'datetime',
        ];
    }

    public function getPhotoUrlAttribute(): ?string
    {
        return $this->photo_path
            ? Storage::disk('public')->url($this->photo_path)
            : null;
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function reporter(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function resolver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'resolved_by');
    }

    public function bitacora(): BelongsTo
    {
        return $this->belongsTo(Bitacora::class);
    }
}
