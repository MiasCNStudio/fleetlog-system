<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class EmergencyReassignAssignmentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'new_driver_id' => ['nullable', 'integer', 'exists:users,id'],
            'reassignment_reason' => ['required', 'string', 'min:5', 'max:1000'],
        ];
    }
}
