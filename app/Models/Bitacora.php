<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Bitacora extends Model
{
    public const TYPE_SALIDA = 'salida';

    public const TYPE_REGRESO = 'regreso';

    protected $fillable = [
        'vehicle_id',
        'user_id',
        'type',
        'recorded_at',
        'destination',
        'companions',
    ];

    protected function casts(): array
    {
        return [
            'recorded_at' => 'datetime',
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
}
