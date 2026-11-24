<?php

namespace Tests\Feature;

use App\Models\Incident;
use App\Models\User;
use App\Models\Vehicle;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FleetlogOperationsTest extends TestCase
{
    use RefreshDatabase;

    public function test_role_permissions_for_users_and_vehicles(): void
    {
        $admin = User::factory()->create(['role' => User::ROLE_ADMIN]);
        $driver = User::factory()->driver()->create();

        // El motorista no puede listar ni crear usuarios ni crear vehículos
        $this->actingAs($driver)->getJson('/api/users')->assertForbidden();
        $this->actingAs($driver)->postJson('/api/vehicles', [
            'license_plate' => 'HAA-1234',
            'color' => 'Blanco',
            'brand' => 'Toyota',
            'model' => 'Hilux',
        ])->assertForbidden();

        // El admin sí puede crear vehículos
        $this->actingAs($admin)->postJson('/api/vehicles', [
            'license_plate' => 'HAA-1234',
            'color' => 'Blanco',
            'brand' => 'Toyota',
            'model' => 'Hilux',
            'current_odometer' => 10000,
        ])->assertCreated()->assertJsonPath('status', Vehicle::STATUS_AVAILABLE);
    }

    public function test_bitacora_toggles_status_validates_odometer_and_updates_dashboard(): void
    {
        $admin = User::factory()->create(['role' => User::ROLE_ADMIN]);
        $driver = User::factory()->driver()->create();

        $vehicle = Vehicle::query()->create([
            'license_plate' => 'HBB-5678',
            'color' => 'Gris',
            'brand' => 'Nissan',
            'model' => 'Frontier',
            'status' => Vehicle::STATUS_AVAILABLE,
            'current_odometer' => 5000,
        ]);

        // Odómetro menor al actual debe fallar
        $this->actingAs($driver)->postJson('/api/bitacoras', [
            'vehicle_id' => $vehicle->id,
            'destination' => 'Bodega Central',
            'odometer_km' => 4500,
        ])->assertUnprocessable();

        // Registrar salida válida
        $this->actingAs($driver)->postJson('/api/bitacoras', [
            'vehicle_id' => $vehicle->id,
            'destination' => 'Bodega Central',
            'odometer_km' => 5100,
            'fuel_level' => '3/4',
        ])->assertCreated()->assertJsonPath('type', 'salida');

        $vehicle->refresh();
        $this->assertSame(Vehicle::STATUS_IN_ROUTE, $vehicle->status);
        $this->assertSame(5100, $vehicle->current_odometer);

        // Dashboard refleja el viaje activo y conductor en ruta
        $this->actingAs($admin)->getJson('/api/dashboard')
            ->assertOk()
            ->assertJsonPath('summary.viajes_activos', 1)
            ->assertJsonPath('summary.unidades_disponibles', 0)
            ->assertJsonPath('summary.conductores_en_ruta', 1);

        // Registrar regreso
        $this->actingAs($driver)->postJson('/api/bitacoras', [
            'vehicle_id' => $vehicle->id,
            'odometer_km' => 5250,
            'fuel_level' => '1/2',
        ])->assertCreated()->assertJsonPath('type', 'regreso');

        $vehicle->refresh();
        $this->assertSame(Vehicle::STATUS_AVAILABLE, $vehicle->status);
        $this->assertSame(5250, $vehicle->current_odometer);
    }

    public function test_incident_reporting_and_maintenance_block(): void
    {
        $admin = User::factory()->create(['role' => User::ROLE_ADMIN]);
        $driver = User::factory()->driver()->create();

        $vehicle = Vehicle::query()->create([
            'license_plate' => 'HCC-9999',
            'color' => 'Azul',
            'brand' => 'Ford',
            'model' => 'Ranger',
            'status' => Vehicle::STATUS_AVAILABLE,
            'current_odometer' => 12000,
        ]);

        // Admin reporta incidencia enviando vehículo a mantenimiento
        $incidentResponse = $this->actingAs($admin)->postJson('/api/incidents', [
            'vehicle_id' => $vehicle->id,
            'title' => 'Falla en frenos',
            'severity' => Incident::SEVERITY_CRITICAL,
            'set_vehicle_maintenance' => true,
        ])->assertCreated();

        $incidentId = $incidentResponse->json('id');
        $vehicle->refresh();
        $this->assertSame(Vehicle::STATUS_MAINTENANCE, $vehicle->status);

        // No debe permitir salida si está en mantenimiento
        $this->actingAs($driver)->postJson('/api/bitacoras', [
            'vehicle_id' => $vehicle->id,
            'destination' => 'Puerto Cortés',
        ])->assertUnprocessable();

        // Driver no puede cerrar incidencia, admin sí
        $this->actingAs($driver)->putJson("/api/incidents/{$incidentId}", [
            'status' => Incident::STATUS_RESOLVED,
        ])->assertForbidden();

        $this->actingAs($admin)->putJson("/api/incidents/{$incidentId}", [
            'status' => Incident::STATUS_RESOLVED,
        ])->assertOk()->assertJsonPath('status', Incident::STATUS_RESOLVED);
    }
}
