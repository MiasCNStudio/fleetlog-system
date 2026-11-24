<?php

namespace App\Http\Requests;

use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->isAdmin() ?? false;
    }

    public function rules(): array
    {
        /** @var User $user */
        $user = $this->route('user');

        return [
            'name' => ['sometimes', 'string', 'max:255'],
            'email' => ['sometimes', 'email', 'max:255', Rule::unique('users', 'email')->ignore($user->id)],
            'password' => ['nullable', 'string', 'min:8'],
            'person_type' => ['sometimes', Rule::in(['funcionario', 'motorista'])],
            'role' => ['sometimes', Rule::in(User::ROLES)],
            'driver_code' => [
                Rule::requiredIf($this->input('person_type', $user->person_type) === 'motorista'),
                'nullable',
                'string',
                'max:100',
                Rule::unique('users', 'driver_code')->ignore($user->id),
            ],
            'photo' => ['nullable', 'image', 'max:4096'],
        ];
    }
}
