<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Facades\Storage;

class Vehicle extends Model
{
    use HasFactory;

    public const STATUS_AVAILABLE = 'disponible';

    public const STATUS_IN_ROUTE = 'en_ruta';

    public const STATUS_MAINTENANCE = 'mantenimiento';

    public const STATUSES = [
        self::STATUS_AVAILABLE,
        self::STATUS_IN_ROUTE,
        self::STATUS_MAINTENANCE,
    ];

    protected $fillable = [
        'license_plate',
        'color',
        'brand',
        'model',
        'status',
        'current_odometer',
        'maintenance_interval_km',
        'photo_path',
    ];

    protected $appends = [
        'photo_url',
    ];

    protected function casts(): array
    {
        return [
            'current_odometer' => 'integer',
            'maintenance_interval_km' => 'integer',
        ];
    }

    public function getPhotoUrlAttribute(): ?string
    {
        return $this->photo_path
            ? Storage::disk('public')->url($this->photo_path)
            : null;
    }

    public function bitacoras(): HasMany
    {
        return $this->hasMany(Bitacora::class);
    }

    public function latestBitacora(): HasOne
    {
        return $this->hasOne(Bitacora::class)->latestOfMany(['recorded_at', 'id']);
    }

    public function incidents(): HasMany
    {
        return $this->hasMany(Incident::class);
    }

    public function assignments(): HasMany
    {
        return $this->hasMany(Assignment::class);
    }

    /**
     * Si el último movimiento fue regreso (o no hay registros), el vehículo está en empresa → siguiente es salida.
     * Si el último fue salida, está fuera → siguiente es regreso.
     */
    public function nextBitacoraType(): string
    {
        $last = $this->bitacoras()
            ->orderByDesc('recorded_at')
            ->orderByDesc('id')
            ->first();

        if (! $last || $last->type === Bitacora::TYPE_REGRESO) {
            return Bitacora::TYPE_SALIDA;
        }

        return Bitacora::TYPE_REGRESO;
    }
}
