<?php

namespace App\Http\Requests;

use App\Models\Vehicle;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateVehicleRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->canManageFleet() ?? false;
    }

    protected function prepareForValidation(): void
    {
        $plateType = $this->input('plate_type');
        $plateNumber = $this->input('plate_number');

        if ($plateType && $plateNumber) {
            $cleanType = strtoupper(trim((string) $plateType));
            $cleanNum = strtoupper(preg_replace('/[^A-Z0-9]/i', '', (string) $plateNumber) ?? '');
            $this->merge([
                'plate_type' => $cleanType,
                'plate_number' => $cleanNum,
                'license_plate' => $cleanType.$cleanNum,
            ]);
        } elseif ($this->filled('license_plate')) {
            $this->merge([
                'license_plate' => strtoupper(trim((string) $this->input('license_plate'))),
            ]);
        }
    }

    public function rules(): array
    {
        /** @var Vehicle $vehicle */
        $vehicle = $this->route('vehicle');

        return [
            'license_plate' => ['sometimes', 'string', 'max:32', Rule::unique('vehicles', 'license_plate')->ignore($vehicle->id)],
            'plate_type' => ['nullable', Rule::in(Vehicle::SV_PLATE_TYPES)],
            'plate_number' => ['nullable', 'string', 'min:3', 'max:10', 'regex:/^[A-Z0-9]+$/i'],
            'color' => ['sometimes', 'string', 'max:100'],
            'brand' => ['sometimes', 'string', 'max:100'],
            'model' => ['sometimes', 'string', 'max:100'],
            'status' => ['sometimes', Rule::in(Vehicle::STATUSES)],
            'current_odometer' => ['sometimes', 'integer', 'min:0'],
            'maintenance_interval_km' => ['nullable', 'integer', 'min:100'],
            'next_maintenance_odometer' => ['nullable', 'integer', 'min:0'],
            'maintenance_alert_before_km' => ['nullable', 'integer', 'min:50', 'max:5000'],
            'photo' => ['nullable', 'image', 'max:4096'],
        ];
    }
}
