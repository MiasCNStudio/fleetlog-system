import 'package:battery_plus/battery_plus.dart';

import '../models/tracking_models.dart';
import '../services/api_client.dart';
import '../services/background_tracking_service.dart';
import '../services/device_identity_service.dart';

class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;
}

class TrackingRepository {
  TrackingRepository({
    required ApiClient apiClient,
    required DeviceIdentityService deviceIdentityService,
  }) : _api = apiClient,
       _device = deviceIdentityService;

  final ApiClient _api;
  final DeviceIdentityService _device;

  Future<TripTrackingSession?> fetchMyActiveSession() async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>('/tracking/my-active');
      final raw = res.data?['data'];
      if (raw is Map<String, dynamic>) {
        return TripTrackingSession.fromJson(raw);
      }
      return null;
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<TripTrackingSession> bindToCurrentDevice({int? bitacoraId}) async {
    try {
      final identity = await _device.getIdentity();
      final pos = await BackgroundTrackingService.tryCurrentPosition();
      int? batteryLevel;
      try {
        batteryLevel = await Battery().batteryLevel;
      } catch (_) {}

      final res = await _api.dio.post<Map<String, dynamic>>(
        '/tracking/sessions/start',
        data: {
          'bitacora_id': ?bitacoraId,
          'device_uuid': identity.uuid,
          'device_name': identity.name,
          'device_platform': identity.platform,
          if (pos != null) 'latitude': pos.latitude,
          if (pos != null) 'longitude': pos.longitude,
          if (pos != null) 'accuracy_m': pos.accuracy,
          'battery_level': ?batteryLevel,
        },
      );
      return TripTrackingSession.fromJson(res.data!['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<TripTrackingSession> sendSos({
    required int sessionId,
    String? message,
  }) async {
    try {
      final identity = await _device.getIdentity();
      final pos = await BackgroundTrackingService.tryCurrentPosition();
      if (pos == null) {
        throw ApiException(
          'Activa el GPS para enviar tu ubicación exacta de emergencia.',
        );
      }
      int? batteryLevel;
      try {
        batteryLevel = await Battery().batteryLevel;
      } catch (_) {}

      final res = await _api.dio.post<Map<String, dynamic>>(
        '/tracking/sessions/$sessionId/sos',
        data: {
          'device_uuid': identity.uuid,
          'device_name': identity.name,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'accuracy_m': pos.accuracy,
          'battery_level': ?batteryLevel,
          if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
        },
      );
      return TripTrackingSession.fromJson(res.data!['session'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<List<TripTrackingSession>> fetchActiveFleet() async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>('/tracking/sessions/active');
      final raw = res.data?['data'] as List<dynamic>? ?? const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(TripTrackingSession.fromJson)
          .toList();
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<PaginatedResult<TripTrackingSession>> fetchSessions({
    int page = 1,
    String? status,
    int? vehicleId,
    int? driverId,
    String? dateFrom,
    String? dateTo,
    bool sosOnly = false,
  }) async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(
        '/tracking/sessions',
        queryParameters: {
          'page': page,
          if (status != null && status.isNotEmpty) 'status': status,
          'vehicle_id': ?vehicleId,
          'driver_id': ?driverId,
          if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
          if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
          if (sosOnly) 'sos_only': 1,
        },
      );
      final body = res.data ?? const {};
      final raw = body['data'] as List<dynamic>? ?? const [];
      return PaginatedResult(
        items: raw
            .whereType<Map<String, dynamic>>()
            .map(TripTrackingSession.fromJson)
            .toList(),
        currentPage: (body['current_page'] as num?)?.toInt() ?? 1,
        lastPage: (body['last_page'] as num?)?.toInt() ?? 1,
        total: (body['total'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<TripTrackingDetail> fetchSessionDetail(int sessionId) async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>('/tracking/sessions/$sessionId');
      return TripTrackingDetail.fromJson(res.data ?? const {});
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }
}
