import 'dart:async';
import 'dart:ui';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'offline_location_queue.dart';

const String _kActiveSessionId = 'bg_active_session_id';
const String _kVehiclePlate = 'bg_vehicle_plate';
const String _kDestination = 'bg_destination';
const String _kDeviceUuid = 'fleetlog_device_uuid';
const String _kDeviceName = 'fleetlog_device_name';
const String _kDevicePlatform = 'fleetlog_device_platform';
const String _kApiToken = 'fleetlog_api_token';
const String _kApiBaseUrl = 'fleetlog_api_base_url';

const int _notificationId = 9041;
const String _channelId = 'fleetlog_tracking_channel';

@pragma('vm:entry-point')
void fleetlogBackgroundOnStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final queue = OfflineLocationQueue();
  final battery = Battery();
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
    ),
  );

  var isDisposed = false;
  var isUploading = false;
  var sentCount = 0;
  DateTime? lastCaptureAt;

  Future<void> updateNotification(String title, String content) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(title: title, content: content);
      }
    }
  }

  Future<void> enqueuePosition({
    required Position pos,
    required int sessionId,
    required String deviceUuid,
  }) async {
    int? batteryLevel;
    try {
      batteryLevel = await battery.batteryLevel;
    } catch (_) {}

    final speedKmh = pos.speed >= 0
        ? double.parse((pos.speed * 3.6).toStringAsFixed(2))
        : 0.0;

    await queue.enqueue(
      sessionId: sessionId,
      deviceUuid: deviceUuid,
      pointPayload: {
        'latitude': double.parse(pos.latitude.toStringAsFixed(7)),
        'longitude': double.parse(pos.longitude.toStringAsFixed(7)),
        'accuracy_m': double.parse(pos.accuracy.toStringAsFixed(2)),
        'speed_kmh': speedKmh,
        'heading': double.parse(pos.heading.toStringAsFixed(2)),
        'altitude_m': double.parse(pos.altitude.toStringAsFixed(2)),
        'battery_level': batteryLevel,
        'is_moving': speedKmh >= 2.0,
        'source': 'background',
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
    lastCaptureAt = DateTime.now();
  }

  Future<void> tick({bool forceSyncOnly = false, Position? streamPosition}) async {
    if (isDisposed) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final sessionId = prefs.getInt(_kActiveSessionId);
    final token = prefs.getString(_kApiToken);
    final baseUrl = prefs.getString(_kApiBaseUrl) ?? ApiClient.defaultBaseUrl;
    final deviceUuid = prefs.getString(_kDeviceUuid) ?? '';
    final deviceName = prefs.getString(_kDeviceName) ?? 'Android';
    final devicePlatform = prefs.getString(_kDevicePlatform) ?? 'android';
    final plate = prefs.getString(_kVehiclePlate) ?? 'Unidad';

    if (sessionId == null || token == null || token.isEmpty || deviceUuid.isEmpty) {
      service.stopSelf();
      return;
    }

    if (streamPosition != null) {
      await enqueuePosition(
        pos: streamPosition,
        sessionId: sessionId,
        deviceUuid: deviceUuid,
      );
    } else if (!forceSyncOnly) {
      try {
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              timeLimit: Duration(seconds: 12),
            ),
          );
          await enqueuePosition(
            pos: pos,
            sessionId: sessionId,
            deviceUuid: deviceUuid,
          );
        }
      } catch (_) {
        /* GPS momentáneamente indisponible */
      }
    }

    if (isUploading) return;
    final batch = await queue.peekBatch(sessionId: sessionId, limit: 100);
    if (batch.isNotEmpty) {
      isUploading = true;
      try {
        final payloadPoints = batch.map((e) {
          final pt = Map<String, dynamic>.from(e.payload);
          if (batch.length > 3 && pt['source'] == 'background') {
            pt['source'] = 'offline_sync';
          }
          return pt;
        }).toList();

        dio.options.baseUrl = baseUrl;
        final response = await dio.post<Map<String, dynamic>>(
          '/tracking/sessions/$sessionId/points',
          data: {
            'device_uuid': deviceUuid,
            'device_name': deviceName,
            'device_platform': devicePlatform,
            'points': payloadPoints,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'X-Device-UUID': deviceUuid,
              'X-Device-Name': deviceName,
              'X-Device-Platform': devicePlatform,
            },
          ),
        );

        await queue.deleteByIds(batch.map((e) => e.id).toList());
        sentCount += batch.length;

        final serverSession = response.data?['session'] as Map<String, dynamic>?;
        final serverPoints = (serverSession?['points_count'] as num?)?.toInt() ?? sentCount;
        final distance = serverSession?['gps_distance_km'] ?? 0;

        service.invoke('trackingUpdate', {
          'session_id': sessionId,
          'points_count': serverPoints,
          'gps_distance_km': distance,
          'pending_queue': 0,
          'last_sync': DateTime.now().toIso8601String(),
        });

        await updateNotification(
          'Misión activa · $plate',
          'Rastreo continuo · $serverPoints pts · $distance km',
        );
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 403 || code == 404 || code == 422) {
          await prefs.remove(_kActiveSessionId);
          await queue.clearSession(sessionId);
          service.invoke('trackingStopped', {'reason': e.response?.data?['message'] ?? 'Sesión cerrada'});
          service.stopSelf();
          return;
        }
        final queued = await queue.countForSession(sessionId);
        service.invoke('trackingUpdate', {
          'session_id': sessionId,
          'pending_queue': queued,
        });
        await updateNotification(
          'Misión activa · $plate',
          'Sin conexión · $queued ubicaciones guardadas offline',
        );
      } catch (_) {
      } finally {
        isUploading = false;
      }
    }
  }

  service.on('syncNow').listen((_) async {
    await tick(forceSyncOnly: true);
  });

  final connSub = Connectivity().onConnectivityChanged.listen((results) async {
    if (!results.contains(ConnectivityResult.none)) {
      await tick(forceSyncOnly: true);
    }
  });

  StreamSubscription<Position>? posSub;
  try {
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
      posSub = Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 25,
          intervalDuration: const Duration(seconds: 5),
        ),
      ).listen((pos) async {
        await tick(streamPosition: pos);
      }, onError: (_) {});
    }
  } catch (_) {}

  await tick();
  final timer = Timer.periodic(const Duration(seconds: 25), (_) async {
    final stale = lastCaptureAt == null ||
        DateTime.now().difference(lastCaptureAt!).inSeconds >= 23;
    await tick(forceSyncOnly: !stale);
  });

  service.on('stopService').listen((_) {
    isDisposed = true;
    timer.cancel();
    connSub.cancel();
    posSub?.cancel();
    service.stopSelf();
  });
}

@pragma('vm:entry-point')
Future<bool> fleetlogBackgroundOnIos(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

class BackgroundTrackingService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    const channel = AndroidNotificationChannel(
      _channelId,
      'Rastreo de misión Fleetlog',
      description: 'Mantiene el rastreo GPS de seguridad mientras una misión está en curso.',
      importance: Importance.low,
    );

    final notificationsPlugin = FlutterLocalNotificationsPlugin();
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: fleetlogBackgroundOnStart,
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'Misión Fleetlog en curso',
        initialNotificationContent: 'Rastreo GPS de seguridad activo',
        foregroundServiceNotificationId: _notificationId,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: fleetlogBackgroundOnStart,
        onBackground: fleetlogBackgroundOnIos,
      ),
    );
  }

  static Future<bool> requestLocationPermissions() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return false;
    }

    // Solicitar notificaciones en Android 13+ sin bloquear si rechazan
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}

    return true;
  }

  static Future<Position?> tryCurrentPosition() async {
    try {
      final ok = await requestLocationPermissions();
      if (!ok) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> startMission({
    required int sessionId,
    required String vehiclePlate,
    String? destination,
  }) async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kActiveSessionId, sessionId);
    await prefs.setString(_kVehiclePlate, vehiclePlate);
    await prefs.setString(_kDestination, destination ?? '');

    final service = FlutterBackgroundService();
    final running = await service.isRunning();
    if (!running) {
      await service.startService();
    } else {
      service.invoke('syncNow');
    }
  }

  static Future<void> stopMission() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getInt(_kActiveSessionId);
    await prefs.remove(_kActiveSessionId);
    await prefs.remove(_kVehiclePlate);
    await prefs.remove(_kDestination);
    if (sessionId != null) {
      await OfflineLocationQueue().clearSession(sessionId);
    }

    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('stopService');
    }
  }

  static Stream<Map<String, dynamic>?> get updates =>
      FlutterBackgroundService().on('trackingUpdate');

  static Stream<Map<String, dynamic>?> get stoppedEvents =>
      FlutterBackgroundService().on('trackingStopped');
}
