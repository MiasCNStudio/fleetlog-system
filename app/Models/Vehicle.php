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

    public const SV_PLATE_TYPES = [
        'P',
        'CD',
        'MI',
        'N',
        'CC',
        'A',
        'C',
        'M',
        'AB',
        'MB',
    ];

    protected $fillable = [
        'license_plate',
        'plate_type',
        'plate_number',
        'color',
        'brand',
        'model',
        'status',
        'current_odometer',
        'maintenance_interval_km',
        'next_maintenance_odometer',
        'maintenance_alert_before_km',
        'last_maintenance_odometer',
        'last_maintenance_at',
        'photo_path',
    ];

    protected $appends = [
        'photo_url',
        'maintenance_status',
        'km_to_maintenance',
    ];

    protected function casts(): array
    {
        return [
            'current_odometer' => 'integer',
            'maintenance_interval_km' => 'integer',
            'next_maintenance_odometer' => 'integer',
            'maintenance_alert_before_km' => 'integer',
            'last_maintenance_odometer' => 'integer',
            'last_maintenance_at' => 'datetime',
        ];
    }

    public function getPhotoUrlAttribute(): ?string
    {
        return $this->photo_path
            ? Storage::disk('public')->url($this->photo_path)
            : null;
    }

    public function getKmToMaintenanceAttribute(): ?int
    {
        if ($this->next_maintenance_odometer === null) {
            return null;
        }

        return (int) $this->next_maintenance_odometer - (int) $this->current_odometer;
    }

    public function getMaintenanceStatusAttribute(): string
    {
        $remaining = $this->km_to_maintenance;
        if ($remaining === null) {
            return 'sin_programar';
        }

        $threshold = max(1, (int) ($this->maintenance_alert_before_km ?: 500));

        if ($remaining <= 0) {
            return 'vencido';
        }

        if ($remaining <= $threshold) {
            return 'pronto';
        }

        return 'al_dia';
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

    public function maintenances(): HasMany
    {
        return $this->hasMany(VehicleMaintenance::class)->orderByDesc('created_at')->orderByDesc('id');
    }

    public function fuelLogs(): HasMany
    {
        return $this->hasMany(FuelLog::class)->orderByDesc('filled_at')->orderByDesc('id');
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
