<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    use RefreshDatabase;

    public function test_login_y_dashboard_con_sanctum(): void
    {
        $user = User::factory()->create([
            'email' => 'admin@fleetlog.test',
            'password' => 'password',
        ]);

        $loginResponse = $this->postJson('/api/login', [
            'email' => $user->email,
            'password' => 'password',
        ]);

        $loginResponse->assertOk()->assertJsonStructure(['token', 'user']);

        $token = $loginResponse->json('token');

        $this->withToken($token)
            ->getJson('/api/dashboard')
            ->assertOk()
            ->assertJsonStructure([
                'summary' => ['viajes_activos', 'unidades_disponibles', 'conductores_en_ruta', 'incidencias_hoy'],
                'series' => ['categories', 'values'],
            ]);
    }
}
