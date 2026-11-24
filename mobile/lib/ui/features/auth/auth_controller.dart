import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/app_user.dart';
import '../../../data/models/tracking_models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/tracking_repository.dart';
import '../../../data/services/background_tracking_service.dart';
import '../../../data/services/device_identity_service.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository authRepository,
    required TrackingRepository trackingRepository,
    required DeviceIdentityService deviceIdentityService,
  }) : _authRepo = authRepository,
       _trackingRepo = trackingRepository,
       _deviceService = deviceIdentityService;

  static const _themeKey = 'fleetlog_theme_mode';

  final AuthRepository _authRepo;
  final TrackingRepository _trackingRepo;
  final DeviceIdentityService _deviceService;

  AppUser? _user;
  AppUser? get user => _user;

  DeviceIdentity? _deviceIdentity;
  DeviceIdentity? get deviceIdentity => _deviceIdentity;

  TripTrackingSession? _myActiveSession;
  TripTrackingSession? get myActiveSession => _myActiveSession;

  String? _trackingWarning;
  String? get trackingWarning => _trackingWarning;

  int _livePointsCount = 0;
  int get livePointsCount => _livePointsCount;

  double _liveDistanceKm = 0;
  double get liveDistanceKm => _liveDistanceKm;

  int _pendingOfflinePoints = 0;
  int get pendingOfflinePoints => _pendingOfflinePoints;

  bool _initializing = true;
  bool get initializing => _initializing;

  bool _darkMode = false;
  bool get darkMode => _darkMode;

  bool get isAuthenticated => _user != null;

  StreamSubscription<Map<String, dynamic>?>? _trackingSub;
  StreamSubscription<Map<String, dynamic>?>? _stoppedSub;

  Future<void> bootstrap() async {
    _initializing = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool(_themeKey) ?? false;
    _deviceIdentity = await _deviceService.getIdentity();

    _trackingSub ??= BackgroundTrackingService.updates.listen((event) {
      if (event == null) return;
      if (event['points_count'] != null) {
        _livePointsCount = (event['points_count'] as num).toInt();
      }
      if (event['gps_distance_km'] != null) {
        _liveDistanceKm = (event['gps_distance_km'] as num).toDouble();
      }
      if (event['pending_queue'] != null) {
        _pendingOfflinePoints = (event['pending_queue'] as num).toInt();
      }
      notifyListeners();
    });

    _stoppedSub ??= BackgroundTrackingService.stoppedEvents.listen((event) {
      _trackingWarning = event?['reason']?.toString();
      _myActiveSession = null;
      notifyListeners();
    });

    try {
      final hasToken = await _authRepo.hasStoredToken();
      if (hasToken) {
        _user = await _authRepo.fetchMe();
        await syncActiveMissionTracking();
      }
    } catch (_) {
      _user = null;
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  Future<void> toggleDarkMode() async {
    _darkMode = !_darkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _darkMode);
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _user = await _authRepo.login(email: email, password: password);
    _deviceIdentity = await _deviceService.getIdentity();
    await syncActiveMissionTracking();
    notifyListeners();
  }

  Future<void> syncActiveMissionTracking() async {
    if (_user == null) return;
    try {
      final active = await _trackingRepo.fetchMyActiveSession();
      _myActiveSession = active;
      _trackingWarning = null;

      if (active == null) {
        await BackgroundTrackingService.stopMission();
        _livePointsCount = 0;
        _liveDistanceKm = 0;
        _pendingOfflinePoints = 0;
        notifyListeners();
        return;
      }

      _livePointsCount = active.pointsCount;
      _liveDistanceKm = active.gpsDistanceKm;

      final localUuid = _deviceIdentity?.uuid ?? (await _deviceService.getIdentity()).uuid;
      final isPlaceholder = active.deviceUuid.startsWith('web:') ||
          active.deviceUuid.startsWith('token:');

      if (active.deviceUuid == localUuid) {
        await BackgroundTrackingService.startMission(
          sessionId: active.id,
          vehiclePlate: active.vehicle?.licensePlate ?? 'Unidad',
          destination: active.salidaBitacora?.destination,
        );
      } else if (isPlaceholder) {
        // Si la salida se inició desde el navegador web y ahora abre su celular, lo vincula
        final bound = await _trackingRepo.bindToCurrentDevice();
        _myActiveSession = bound;
        await BackgroundTrackingService.startMission(
          sessionId: bound.id,
          vehiclePlate: bound.vehicle?.licensePlate ?? 'Unidad',
          destination: bound.salidaBitacora?.destination,
        );
      } else {
        await BackgroundTrackingService.stopMission();
        _trackingWarning =
            'Misión activa rastreada exclusivamente desde ${active.deviceName}. Este celular no puede suplantar el rastreo.';
      }
      notifyListeners();
    } catch (_) {
      /* mantener estado previo si no hay red temporalmente */
    }
  }

  Future<void> handleUnauthorized() async {
    _user = null;
    _myActiveSession = null;
    await _authRepo.logout(stopTracking: false);
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _myActiveSession = null;
    _trackingWarning = null;
    await _authRepo.logout(stopTracking: true);
    notifyListeners();
  }

  @override
  void dispose() {
    _trackingSub?.cancel();
    _stoppedSub?.cancel();
    super.dispose();
  }
}
