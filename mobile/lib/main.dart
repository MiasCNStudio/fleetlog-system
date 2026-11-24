import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data/repositories/auth_repository.dart';
import 'data/repositories/fleet_repository.dart';
import 'data/repositories/tracking_repository.dart';
import 'data/services/api_client.dart';
import 'data/services/background_tracking_service.dart';
import 'data/services/device_identity_service.dart';
import 'ui/core/app_router.dart';
import 'ui/core/app_theme.dart';
import 'ui/features/auth/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundTrackingService.initialize();

  final deviceService = DeviceIdentityService();
  late final AuthController authController;

  final apiClient = ApiClient(
    deviceIdentityService: deviceService,
    onUnauthorized: () => authController.handleUnauthorized(),
  );
  await apiClient.initBaseUrl();

  final authRepository = AuthRepository(
    apiClient: apiClient,
    deviceIdentityService: deviceService,
  );
  final trackingRepository = TrackingRepository(
    apiClient: apiClient,
    deviceIdentityService: deviceService,
  );
  final fleetRepository = FleetRepository(
    apiClient: apiClient,
    deviceIdentityService: deviceService,
  );

  authController = AuthController(
    authRepository: authRepository,
    trackingRepository: trackingRepository,
    deviceIdentityService: deviceService,
  );
  await authController.bootstrap();

  runApp(
    FleetlogMobileApp(
      apiClient: apiClient,
      deviceService: deviceService,
      authRepository: authRepository,
      trackingRepository: trackingRepository,
      fleetRepository: fleetRepository,
      authController: authController,
    ),
  );
}

class FleetlogMobileApp extends StatefulWidget {
  const FleetlogMobileApp({
    super.key,
    required this.apiClient,
    required this.deviceService,
    required this.authRepository,
    required this.trackingRepository,
    required this.fleetRepository,
    required this.authController,
  });

  final ApiClient apiClient;
  final DeviceIdentityService deviceService;
  final AuthRepository authRepository;
  final TrackingRepository trackingRepository;
  final FleetRepository fleetRepository;
  final AuthController authController;

  @override
  State<FleetlogMobileApp> createState() => _FleetlogMobileAppState();
}

class _FleetlogMobileAppState extends State<FleetlogMobileApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(widget.authController);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: widget.apiClient),
        Provider<DeviceIdentityService>.value(value: widget.deviceService),
        Provider<AuthRepository>.value(value: widget.authRepository),
        Provider<TrackingRepository>.value(value: widget.trackingRepository),
        Provider<FleetRepository>.value(value: widget.fleetRepository),
        ChangeNotifierProvider<AuthController>.value(value: widget.authController),
      ],
      child: AnimatedBuilder(
        animation: widget.authController,
        builder: (context, _) {
          return MaterialApp.router(
            title: 'Fleetlog',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: widget.authController.darkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
