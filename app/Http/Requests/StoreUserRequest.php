<?php

namespace App\Http\Requests;

use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->isAdmin() ?? false;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
            'person_type' => ['required', Rule::in(['funcionario', 'motorista'])],
            'role' => ['sometimes', Rule::in(User::ROLES)],
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
