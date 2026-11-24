import 'package:fleetlog_mobile/data/models/app_user.dart';
import 'package:fleetlog_mobile/data/models/dashboard_data.dart';
import 'package:fleetlog_mobile/data/models/tracking_models.dart';
import 'package:fleetlog_mobile/data/repositories/auth_repository.dart';
import 'package:fleetlog_mobile/data/repositories/tracking_repository.dart';
import 'package:fleetlog_mobile/data/services/api_client.dart';
import 'package:fleetlog_mobile/data/services/device_identity_service.dart';
import 'package:fleetlog_mobile/ui/features/auth/auth_controller.dart';
import 'package:fleetlog_mobile/ui/features/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('AppUser role helpers map driver vs manager roles accurately', () {
    final driver = AppUser.fromJson({
      'id': 3,
      'name': 'Juan Pérez',
      'email': 'juan@fleetlog.test',
      'role': 'motorista',
      'driver_code': 'M-01',
    });
    expect(driver.isDriver, isTrue);
    expect(driver.canManageFleet, isFalse);
    expect(driver.roleLabel, 'Motorista');

    final chief = AppUser.fromJson({
      'id': 2,
      'name': 'Carlos Jefe',
      'email': 'jefe@fleetlog.test',
      'role': 'despachador',
    });
    expect(chief.isDispatcher, isTrue);
    expect(chief.canManageFleet, isTrue);
    expect(chief.isAdmin, isFalse);
    expect(chief.roleLabel, 'Jefe de motoristas');
  });

  test('TripTrackingDetail parses points, stops, timeline, and Google Maps links', () {
    final detail = TripTrackingDetail.fromJson({
      'session': {
        'id': 11,
        'vehicle_id': 4,
        'driver_id': 3,
        'device_uuid': 'android-juan-001',
        'device_name': 'Samsung Galaxy A54',
        'status': 'finalizada',
        'started_at': '2026-11-24T04:00:00Z',
        'gps_distance_km': 14.6,
        'declared_distance_km': 15,
        'stops_count': 1,
        'has_sos_alert': true,
      },
      'points': [
        {
          'latitude': 13.6978,
          'longitude': -89.1914,
          'recorded_at': '2026-11-24T04:00:00Z',
          'source': 'start',
        },
        {
          'latitude': 13.7010,
          'longitude': -89.2050,
          'recorded_at': '2026-11-24T04:10:00Z',
          'source': 'sos',
        },
      ],
      'summary': {
        'duration_minutes': 35,
        'gps_distance_km': 14.6,
        'declared_distance_km': 15,
        'max_speed_kmh': 62.0,
        'avg_speed_kmh': 25.0,
        'points_count': 2,
        'google_maps_route_url': 'https://www.google.com/maps/dir/?api=1',
        'stops': [
          {
            'started_at': '2026-11-24T04:10:00Z',
            'ended_at': '2026-11-24T04:18:00Z',
            'duration_minutes': 8,
            'latitude': 13.7010,
            'longitude': -89.2050,
          },
        ],
        'timeline': [
          {
            'type': 'salida',
            'at': '2026-11-24T04:00:00Z',
            'title': 'Inicio de misión',
          },
        ],
      },
    });

    expect(detail.session.deviceUuid, 'android-juan-001');
    expect(detail.session.hasSosAlert, isTrue);
    expect(detail.points.length, 2);
    expect(detail.summary.stops.first.durationMinutes, 8);
    expect(detail.summary.timeline.first.type, 'salida');
    expect(detail.summary.googleMapsRouteUrl, contains('google.com/maps'));
  });

  test('DashboardData parses summary and myActiveTrip payload', () {
    final dash = DashboardData.fromJson({
      'summary': {
        'viajes_activos': 2,
        'unidades_disponibles': 5,
        'total_vehiculos': 7,
      },
      'my_active_trip': {
        'vehicle_id': 9,
        'license_plate': 'P-12345',
        'brand': 'Toyota',
        'model': 'Hilux',
        'destination': 'Centro Histórico',
      },
    });

    expect(dash.summary.activeTrips, 2);
    expect(dash.summary.availableVehicles, 5);
    expect(dash.myActiveTrip?.licensePlate, 'P-12345');
  });

  testWidgets('LoginScreen displays branding and validates empty credentials', (tester) async {
    final deviceService = DeviceIdentityService();
    final apiClient = ApiClient(deviceIdentityService: deviceService);
    final authRepo = AuthRepository(
      apiClient: apiClient,
      deviceIdentityService: deviceService,
    );
    final trackingRepo = TrackingRepository(
      apiClient: apiClient,
      deviceIdentityService: deviceService,
    );
    final authCtrl = AuthController(
      authRepository: authRepo,
      trackingRepository: trackingRepo,
      deviceIdentityService: deviceService,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: apiClient),
          ChangeNotifierProvider<AuthController>.value(value: authCtrl),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Fleetlog Mobile'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);

    await tester.tap(find.text('Entrar a Fleetlog'));
    await tester.pump();

    expect(find.text('Ingresa tu correo'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });
}
