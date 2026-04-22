<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
            'person_type' => ['required', Rule::in(['funcionario', 'motorista'])],
            'driver_code' => [
                Rule::requiredIf($this->input('person_type') === 'motorista'),
                'nullable',
                'string',
                'max:100',
                Rule::unique('users', 'driver_code'),
            ],
            'photo' => ['nullable', 'image', 'max:4096'],
        ];
    }
}
