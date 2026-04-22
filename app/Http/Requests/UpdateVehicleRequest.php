<?php

namespace App\Http\Requests;

use App\Models\Vehicle;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateVehicleRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        /** @var Vehicle $vehicle */
        $vehicle = $this->route('vehicle');

        return [
            'license_plate' => ['sometimes', 'string', 'max:32', Rule::unique('vehicles', 'license_plate')->ignore($vehicle->id)],
            'color' => ['sometimes', 'string', 'max:100'],
            'brand' => ['sometimes', 'string', 'max:100'],
            'model' => ['sometimes', 'string', 'max:100'],
            'photo' => ['nullable', 'image', 'max:4096'],
        ];
    }
}
