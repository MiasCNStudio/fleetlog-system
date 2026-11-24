<?php

namespace App\Http\Requests;

use App\Models\Bitacora;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreBitacoraRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'vehicle_id' => ['required', 'integer', 'exists:vehicles,id'],
            'driver_id' => ['nullable', 'integer', 'exists:users,id'],
            'odometer_km' => ['nullable', 'integer', 'min:0'],
            'fuel_level' => ['nullable', Rule::in(Bitacora::FUEL_LEVELS)],
            'destination' => ['nullable', 'string', 'max:2000'],
            'companions' => ['nullable', 'string', 'max:2000'],
        ];
    }
}
