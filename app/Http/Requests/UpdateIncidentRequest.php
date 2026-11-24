<?php

namespace App\Http\Requests;

use App\Models\Incident;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateIncidentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->canManageFleet() ?? false;
    }

    public function rules(): array
    {
        return [
            'title' => ['sometimes', 'string', 'max:150'],
            'description' => ['sometimes', 'nullable', 'string', 'max:3000'],
            'severity' => ['sometimes', Rule::in(Incident::SEVERITIES)],
            'status' => ['sometimes', Rule::in(Incident::STATUSES)],
        ];
    }
}
