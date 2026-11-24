<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        if (User::query()->exists()) {
            return;
        }

        User::query()->firstOrCreate(
            ['email' => 'admin@fleetlog.test'],
            [
                'name' => 'Administrador Fleetlog',
                'password' => 'password',
                'person_type' => 'funcionario',
                'role' => User::ROLE_ADMIN,
                'driver_code' => null,
                'email_verified_at' => now(),
            ],
        );

        User::query()->firstOrCreate(
            ['email' => 'motorista@fleetlog.test'],
            [
                'name' => 'Motorista Demo',
                'password' => 'password',
                'person_type' => 'motorista',
                'role' => User::ROLE_DRIVER,
                'driver_code' => 'MOT-001',
                'email_verified_at' => now(),
            ],
        );
    }
}
