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
            'trip_category' => ['sometimes', Rule::in(Bitacora::CATEGORIES)],
            'odometer_km' => ['sometimes', 'nullable', 'integer', 'min:0'],
            'fuel_level' => ['sometimes', 'nullable', Rule::in(Bitacora::FUEL_LEVELS)],
            'destination' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'destination_address' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'latitude' => ['sometimes', 'nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['sometimes', 'nullable', 'numeric', 'between:-180,180'],
            'place_id' => ['sometimes', 'nullable', 'string', 'max:255'],
            'companions' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'official_instruction' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'notes' => ['sometimes', 'nullable', 'string', 'max:2000'],
        ];
    }
}
