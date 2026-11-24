<?php

namespace App\Http\Requests;

use App\Models\Vehicle;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreVehicleRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->canManageFleet() ?? false;
    }

    public function rules(): array
    {
        return [
            'license_plate' => ['required', 'string', 'max:32', 'unique:vehicles,license_plate'],
            'color' => ['required', 'string', 'max:100'],
            'brand' => ['required', 'string', 'max:100'],
            'model' => ['required', 'string', 'max:100'],
            'status' => ['sometimes', Rule::in(Vehicle::STATUSES)],
            'current_odometer' => ['sometimes', 'integer', 'min:0'],
            'maintenance_interval_km' => ['nullable', 'integer', 'min:500'],
            'photo' => ['nullable', 'image', 'max:4096'],
        ];
    }
}
