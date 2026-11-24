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
            'vehicle_id' => ['required_without:assignment_id', 'nullable', 'integer', 'exists:vehicles,id'],
            'assignment_id' => ['nullable', 'integer', 'exists:assignments,id'],
            'trip_category' => ['nullable', Rule::in(Bitacora::CATEGORIES)],
            'driver_id' => ['nullable', 'integer', 'exists:users,id'],
            'odometer_km' => ['nullable', 'integer', 'min:0'],
            'fuel_level' => ['nullable', Rule::in(Bitacora::FUEL_LEVELS)],
            'destination' => ['nullable', 'string', 'max:2000'],
            'destination_address' => ['nullable', 'string', 'max:2000'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'place_id' => ['nullable', 'string', 'max:255'],
            'companions' => ['nullable', 'string', 'max:2000'],
            'official_instruction' => ['nullable', 'string', 'max:2000'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'device_uuid' => ['nullable', 'string', 'max:128'],
            'device_name' => ['nullable', 'string', 'max:120'],
            'device_platform' => ['nullable', 'string', 'max:40'],
            'initial_latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'initial_longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'initial_accuracy_m' => ['nullable', 'numeric', 'min:0'],
            'final_latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'final_longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'battery_level' => ['nullable', 'integer', 'between:0,100'],
        ];
    }
}
