<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateBitacoraRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'destination' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'companions' => ['sometimes', 'nullable', 'string', 'max:2000'],
        ];
    }
}
