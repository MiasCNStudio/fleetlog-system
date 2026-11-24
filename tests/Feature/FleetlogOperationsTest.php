<?php

namespace Tests\Feature;

use App\Models\Assignment;
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

        // Motorista no puede iniciar salida libre sin asignación
        $this->actingAs($driver)->postJson('/api/bitacoras', [
            'vehicle_id' => $vehicle->id,
            'destination' => 'Bodega Central',
            'odometer_km' => 5100,
        ])->assertUnprocessable();

        // Admin crea una asignación con coordenadas e instrucción oficial
        $assignmentResp = $this->actingAs($admin)->postJson('/api/assignments', [
            'vehicle_id' => $vehicle->id,
            'driver_id' => $driver->id,
            'scheduled_date' => now()->toDateString(),
            'destination' => 'Centro Histórico de El Salvador',
            'destination_address' => 'Plaza Gerardo Barrios, San Salvador',
            'latitude' => 13.6978,
            'longitude' => -89.1914,
            'description' => 'Entregar suministros',
            'official_instruction' => 'Esperar a los compañeros a que regresen',
        ])->assertCreated();

        $assignmentId = $assignmentResp->json('assignment.id');

        // Odómetro menor al actual debe fallar
        $this->actingAs($driver)->postJson('/api/bitacoras', [
            'assignment_id' => $assignmentId,
            'vehicle_id' => $vehicle->id,
            'odometer_km' => 4500,
        ])->assertUnprocessable();

        // Registrar salida válida desde la asignación
        $this->actingAs($driver)->postJson('/api/bitacoras', [
            'assignment_id' => $assignmentId,
            'odometer_km' => 5100,
            'fuel_level' => '3/4',
        ])->assertCreated()
            ->assertJsonPath('type', 'salida')
            ->assertJsonPath('destination', 'Centro Histórico de El Salvador')
            ->assertJsonPath('official_instruction', 'Esperar a los compañeros a que regresen');

        $vehicle->refresh();
        $this->assertSame(Vehicle::STATUS_IN_ROUTE, $vehicle->status);
        $this->assertSame(5100, $vehicle->current_odometer);
        $this->assertSame(Assignment::STATUS_IN_PROGRESS, Assignment::find($assignmentId)->status);

        // Dashboard refleja el viaje activo y conductor en ruta
        $this->actingAs($admin)->getJson('/api/dashboard')
            ->assertOk()
            ->assertJsonPath('summary.viajes_activos', 1)
            ->assertJsonPath('summary.unidades_disponibles', 0)
            ->assertJsonPath('summary.conductores_en_ruta', 1);

        // Registrar regreso cierra automáticamente la asignación
        $this->actingAs($driver)->postJson('/api/bitacoras', [
            'vehicle_id' => $vehicle->id,
            'odometer_km' => 5250,
            'fuel_level' => '1/2',
        ])->assertCreated()->assertJsonPath('type', 'regreso');

        $vehicle->refresh();
        $this->assertSame(Vehicle::STATUS_AVAILABLE, $vehicle->status);
        $this->assertSame(5250, $vehicle->current_odometer);
        $this->assertSame(Assignment::STATUS_COMPLETED, Assignment::find($assignmentId)->status);
    }

    public function test_assignments_batch_schedule_and_emergency_reassignment(): void
    {
        $dispatcher = User::factory()->create(['role' => User::ROLE_DISPATCHER]);
        $driverA = User::factory()->driver()->create();
        $driverB = User::factory()->driver()->create();

        $vehicle = Vehicle::query()->create([
            'license_plate' => 'HDD-2026',
            'color' => 'Blanco',
            'brand' => 'Toyota',
            'model' => 'Hiace',
            'status' => Vehicle::STATUS_AVAILABLE,
            'current_odometer' => 8000,
        ]);

        // Motorista no puede crear asignaciones
        $this->actingAs($driverA)->postJson('/api/assignments', [
            'vehicle_id' => $vehicle->id,
            'driver_id' => $driverA->id,
            'scheduled_date' => now()->toDateString(),
            'destination' => 'Centro Histórico',
        ])->assertForbidden();

        // Jefe de motoristas (despachador) agenda una semana completa (7 días filtrados)
        $batch = $this->actingAs($dispatcher)->postJson('/api/assignments', [
            'vehicle_id' => $vehicle->id,
            'driver_id' => $driverA->id,
            'date_from' => '2026-12-01',
            'date_to' => '2026-12-07',
            'destination' => 'Centro Histórico de El Salvador',
            'official_instruction' => 'No dejar la unidad sola en zona restringida',
        ])->assertCreated();

        $this->assertSame(7, $batch->json('created_count'));
        $firstId = $batch->json('data.0.id');

        // Driver B no puede iniciar salida de una asignación de Driver A sin reasignación
        $this->actingAs($driverB)->postJson('/api/bitacoras', [
            'assignment_id' => $firstId,
            'odometer_km' => 8050,
        ])->assertUnprocessable();

        // Driver B toma la asignación por emergencia con razón justificada
        $this->actingAs($driverB)->postJson("/api/assignments/{$firstId}/emergency-reassign", [
            'reassignment_reason' => 'Juan Pérez presentó incapacidad médica de último minuto.',
        ])->assertOk()
            ->assertJsonPath('is_emergency_reassigned', true)
            ->assertJsonPath('driver_id', $driverB->id)
            ->assertJsonPath('original_driver_id', $driverA->id);

        // Ahora Driver B sí puede iniciar la salida
        $this->actingAs($driverB)->postJson('/api/bitacoras', [
            'assignment_id' => $firstId,
            'odometer_km' => 8050,
        ])->assertCreated()->assertJsonPath('driver_id', $driverB->id);
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

        // No debe permitir salida si está en mantenimiento (ni por admin)
        $this->actingAs($admin)->postJson('/api/bitacoras', [
            'vehicle_id' => $vehicle->id,
            'trip_category' => 'imprevisto',
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

    public function test_personal_and_unplanned_trips_and_system_logs_audit(): void
    {
        $admin = User::factory()->create(['role' => User::ROLE_ADMIN]);
        $dispatcher = User::factory()->create(['role' => User::ROLE_DISPATCHER]);
        $driver = User::factory()->driver()->create();

        $vehicle = Vehicle::query()->create([
            'license_plate' => 'HEE-3030',
            'color' => 'Gris',
            'brand' => 'Toyota',
            'model' => 'Hilux',
            'status' => Vehicle::STATUS_AVAILABLE,
            'current_odometer' => 1000,
        ]);

        // Motorista NO puede crear viaje imprevisto
        $this->actingAs($driver)->postJson('/api/bitacoras', [
            'vehicle_id' => $vehicle->id,
            'trip_category' => 'imprevisto',
            'destination' => 'Puerto',
        ])->assertUnprocessable();

        // Admin NO puede crear salida libre sin categoría ni asignación
        $this->actingAs($admin)->postJson('/api/bitacoras', [
            'vehicle_id' => $vehicle->id,
            'destination' => 'Sin motivo',
        ])->assertUnprocessable();

        // Motorista SÍ puede registrar viaje Personal con destino
        $this->actingAs($driver)->postJson('/api/bitacoras', [
            'vehicle_id' => $vehicle->id,
            'trip_category' => 'personal',
            'destination' => 'Trámite personal en centro',
            'odometer_km' => 1020,
        ])->assertCreated()->assertJsonPath('trip_category', 'personal');

        // Regreso cierra viaje personal
        $this->actingAs($driver)->postJson('/api/bitacoras', [
            'vehicle_id' => $vehicle->id,
            'odometer_km' => 1035,
        ])->assertCreated()->assertJsonPath('type', 'regreso');

        // Jefe de motoristas (despachador) SÍ puede registrar Viaje imprevisto
        $this->actingAs($dispatcher)->postJson('/api/bitacoras', [
            'vehicle_id' => $vehicle->id,
            'trip_category' => 'imprevisto',
            'destination' => 'Emergencia logística',
            'notes' => 'Entrega urgente autorizada',
            'odometer_km' => 1040,
        ])->assertCreated()->assertJsonPath('trip_category', 'imprevisto');

        // Motorista NO puede ver Bitácora del sistema
        $this->actingAs($driver)->getJson('/api/system-logs')->assertForbidden();

        // Admin y Jefe de motoristas SÍ pueden verla y contiene los registros auditados
        $logsResp = $this->actingAs($dispatcher)->getJson('/api/system-logs')->assertOk();
        $actions = collect($logsResp->json('data'))->pluck('action')->all();
        $this->assertContains('personal_trip', $actions);
        $this->assertContains('unplanned_trip', $actions);
    }

    public function test_device_bound_mission_tracking_sos_and_final_route_summary(): void
    {
        $dispatcher = User::factory()->create(['role' => User::ROLE_DISPATCHER]);
        $driver = User::factory()->create(['role' => User::ROLE_DRIVER, 'driver_code' => 'M-30']);

        $vehicle = Vehicle::query()->create([
            'license_plate' => 'P-99001',
            'brand' => 'Toyota',
            'model' => 'Hiace',
            'year' => 2024,
            'status' => Vehicle::STATUS_AVAILABLE,
            'current_odometer' => 5000,
        ]);

        $this->travel(-20)->minutes();

        // Motorista inicia viaje personal desde un celular específico
        $salidaResp = $this->actingAs($driver)->postJson('/api/bitacoras', [
            'vehicle_id' => $vehicle->id,
            'trip_category' => 'personal',
            'destination' => 'Centro Histórico',
            'odometer_km' => 5000,
            'device_uuid' => 'android-juan-001',
            'device_name' => 'Samsung Galaxy A54',
            'device_platform' => 'android',
            'initial_latitude' => 13.6978,
            'initial_longitude' => -89.1914,
            'battery_level' => 88,
        ])->assertCreated();

        $sessionId = $salidaResp->json('tracking_session.id');
        $this->assertNotNull($sessionId);
        $this->assertSame('android-juan-001', $salidaResp->json('tracking_session.device_uuid'));

        // Motorista consulta su propia misión activa
        $this->actingAs($driver)
            ->getJson('/api/tracking/my-active')
            ->assertOk()
            ->assertJsonPath('data.id', $sessionId);

        // Otro celular con la misma cuenta NO puede reportar ni suplantar esta misión
        $this->actingAs($driver)->postJson("/api/tracking/sessions/{$sessionId}/points", [
            'device_uuid' => 'android-intruso-999',
            'device_name' => 'Otro Telefono',
            'latitude' => 13.7050,
            'longitude' => -89.2100,
        ])->assertForbidden();

        // El celular original envía lote de puntos con una parada (>= 3 min en mismo radio) y desplazamiento
        $t0 = now()->addMinutes(3);
        $this->actingAs($driver)->postJson("/api/tracking/sessions/{$sessionId}/points", [
            'device_uuid' => 'android-juan-001',
            'device_name' => 'Samsung Galaxy A54',
            'points' => [
                [
                    'latitude' => 13.7010,
                    'longitude' => -89.2050,
                    'speed_kmh' => 42.5,
                    'battery_level' => 86,
                    'recorded_at' => $t0->toIso8601String(),
                ],
                [
                    'latitude' => 13.7011,
                    'longitude' => -89.2051,
                    'speed_kmh' => 0,
                    'is_moving' => false,
                    'battery_level' => 85,
                    'recorded_at' => $t0->copy()->addMinutes(5)->toIso8601String(),
                ],
                [
                    'latitude' => 13.7120,
                    'longitude' => -89.2250,
                    'speed_kmh' => 54.0,
                    'battery_level' => 83,
                    'recorded_at' => $t0->copy()->addMinutes(10)->toIso8601String(),
                ],
            ],
        ])->assertOk()->assertJsonPath('added', 3);

        $this->travel(15)->minutes();

        // Botón de alerta SOS desde el mismo celular
        $this->actingAs($driver)->postJson("/api/tracking/sessions/{$sessionId}/sos", [
            'device_uuid' => 'android-juan-001',
            'device_name' => 'Samsung Galaxy A54',
            'latitude' => 13.7122,
            'longitude' => -89.2252,
            'battery_level' => 82,
            'message' => 'Emergencia en carretera',
        ])->assertOk()->assertJsonPath('session.has_sos_alert', true);

        $this->travel(5)->minutes();

        // Regreso cierra la misión y genera el resumen final con distancia, paradas y enlace Google Maps
        $this->actingAs($driver)->postJson('/api/bitacoras', [
            'vehicle_id' => $vehicle->id,
            'odometer_km' => 5012,
            'device_uuid' => 'android-juan-001',
            'final_latitude' => 13.6980,
            'final_longitude' => -89.1916,
            'notes' => 'Regreso sin daños',
        ])->assertCreated()->assertJsonPath('type', 'regreso');

        // Motorista NO puede listar sesiones globales ni acceder a resumen administrativo
        $this->actingAs($driver)->getJson('/api/tracking/sessions')->assertForbidden();
        $this->actingAs($driver)->getJson("/api/tracking/sessions/{$sessionId}")->assertForbidden();

        // Jefe de motoristas SÍ consulta el resumen completo en mapa
        $detail = $this->actingAs($dispatcher)
            ->getJson("/api/tracking/sessions/{$sessionId}")
            ->assertOk();

        $detail->assertJsonPath('session.status', 'finalizada');
        $detail->assertJsonPath('session.declared_distance_km', 12);
        $detail->assertJsonPath('session.has_sos_alert', true);
        $detail->assertJsonPath('summary.device.device_uuid', 'android-juan-001');
        $detail->assertJsonPath('summary.stops.0.duration_minutes', 5);
        $this->assertStringContainsString('https://www.google.com/maps/', (string) $detail->json('summary.google_maps_route_url'));
        $this->assertGreaterThanOrEqual(5, count($detail->json('points')));

        // Auditoría registró tanto el intento de dispositivo distinto como el SOS
        $logsResp = $this->actingAs($dispatcher)->getJson('/api/system-logs?module=tracking')->assertOk();
        $actions = collect($logsResp->json('data'))->pluck('action')->all();
        $this->assertContains('device_mismatch', $actions);
        $this->assertContains('sos_alert', $actions);
        $this->assertContains('session_finished', $actions);
    }
}
