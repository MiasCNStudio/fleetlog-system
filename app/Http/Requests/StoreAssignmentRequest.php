<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreAssignmentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->canManageFleet() ?? false;
    }

    public function rules(): array
    {
        return [
            'vehicle_id' => ['required', 'integer', 'exists:vehicles,id'],
            'driver_id' => ['required', 'integer', 'exists:users,id'],
            'scheduled_date' => ['required_without:date_from', 'nullable', 'date'],
            'date_from' => ['required_without:scheduled_date', 'nullable', 'date'],
            'date_to' => ['required_with:date_from', 'nullable', 'date', 'after_or_equal:date_from'],
            'weekdays' => ['nullable', 'array'],
            'weekdays.*' => ['integer', 'between:0,6'],
            'scheduled_time' => ['nullable', 'string', 'max:10'],
            'destination' => ['required', 'string', 'max:255'],
            'destination_address' => ['nullable', 'string', 'max:2000'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'place_id' => ['nullable', 'string', 'max:255'],
            'companions' => ['nullable', 'string', 'max:2000'],
            'description' => ['nullable', 'string', 'max:2000'],
            'official_instruction' => ['nullable', 'string', 'max:2000'],
        ];
    }
}
