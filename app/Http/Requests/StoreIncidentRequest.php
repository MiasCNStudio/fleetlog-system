<?php

namespace App\Http\Requests;

use App\Models\Incident;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreIncidentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'vehicle_id' => ['required', 'integer', 'exists:vehicles,id'],
            'bitacora_id' => ['nullable', 'integer', 'exists:bitacoras,id'],
            'title' => ['required', 'string', 'max:150'],
            'description' => ['nullable', 'string', 'max:3000'],
            'severity' => ['sometimes', Rule::in(Incident::SEVERITIES)],
            'photo' => ['nullable', 'image', 'max:4096'],
            'set_vehicle_maintenance' => ['sometimes', 'boolean'],
        ];
    }
}
