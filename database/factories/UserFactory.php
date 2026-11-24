<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    /**
     * The current password being used by the factory.
     */
    protected static ?string $password;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            'email' => fake()->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password' => static::$password ??= Hash::make('password'),
            'person_type' => 'funcionario',
            'role' => User::ROLE_ADMIN,
            'remember_token' => Str::random(10),
        ];
    }

    public function driver(): static
    {
        return $this->state(fn (array $attributes) => [
            'person_type' => 'motorista',
            'role' => User::ROLE_DRIVER,
            'driver_code' => 'DRV-'.fake()->unique()->numerify('####'),
        ]);
    }

    public function dispatcher(): static
    {
        return $this->state(fn (array $attributes) => [
            'person_type' => 'funcionario',
            'role' => User::ROLE_DISPATCHER,
        ]);
    }

    /**
     * Indicate that the model's email address should be unverified.
     */
    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => [
            'email_verified_at' => null,
        ]);
    }
}
