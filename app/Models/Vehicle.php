<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\Storage;

class Vehicle extends Model
{
    use HasFactory;

    protected $fillable = [
        'license_plate',
        'color',
        'brand',
        'model',
        'photo_path',
    ];

    protected $appends = [
        'photo_url',
    ];

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

    /**
     * Si el último movimiento fue regreso (o no hay registros), el vehículo está en empresa → siguiente es salida.
     * Si el último fue salida, está fuera → siguiente es regreso.
     */
    public function nextBitacoraType(): string
    {
        $last = $this->bitacoras()->latest('recorded_at')->first();

        if (! $last || $last->type === Bitacora::TYPE_REGRESO) {
            return Bitacora::TYPE_SALIDA;
        }

        return Bitacora::TYPE_REGRESO;
    }
}
