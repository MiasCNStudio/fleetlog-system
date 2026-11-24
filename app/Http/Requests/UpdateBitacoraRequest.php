<?php

namespace App\Http\Requests;

use App\Models\Bitacora;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateBitacoraRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->canManageFleet() ?? false;
    }

    public function rules(): array
    {
        return [
            'driver_id' => ['sometimes', 'nullable', 'integer', 'exists:users,id'],
            'odometer_km' => ['sometimes', 'nullable', 'integer', 'min:0'],
            'fuel_level' => ['sometimes', 'nullable', Rule::in(Bitacora::FUEL_LEVELS)],
            'destination' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'companions' => ['sometimes', 'nullable', 'string', 'max:2000'],
        ];
    }
}
