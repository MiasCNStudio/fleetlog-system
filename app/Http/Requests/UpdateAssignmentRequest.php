<?php

namespace App\Http\Requests;

use App\Models\Assignment;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateAssignmentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->canManageFleet() ?? false;
    }

    public function rules(): array
    {
        return [
            'vehicle_id' => ['sometimes', 'integer', 'exists:vehicles,id'],
            'driver_id' => ['sometimes', 'integer', 'exists:users,id'],
            'scheduled_date' => ['sometimes', 'date'],
            'scheduled_time' => ['sometimes', 'nullable', 'string', 'max:10'],
            'destination' => ['sometimes', 'string', 'max:255'],
            'destination_address' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'latitude' => ['sometimes', 'nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['sometimes', 'nullable', 'numeric', 'between:-180,180'],
            'place_id' => ['sometimes', 'nullable', 'string', 'max:255'],
            'companions' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'description' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'official_instruction' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'status' => ['sometimes', Rule::in(Assignment::STATUSES)],
        ];
    }
}
