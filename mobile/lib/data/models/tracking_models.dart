import 'app_user.dart';
import 'assignment.dart';
import 'bitacora_entry.dart';
import 'vehicle.dart';

class TripLocationPoint {
  const TripLocationPoint({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.id,
    this.accuracyM,
    this.speedKmh,
    this.heading,
    this.altitudeM,
    this.batteryLevel,
    this.isMoving = true,
    this.source = 'background',
    this.addressHint,
  });

  final int? id;
  final double latitude;
  final double longitude;
  final String recordedAt;
  final double? accuracyM;
  final double? speedKmh;
  final double? heading;
  final double? altitudeM;
  final int? batteryLevel;
  final bool isMoving;
  final String source;
  final String? addressHint;

  factory TripLocationPoint.fromJson(Map<String, dynamic> json) {
    return TripLocationPoint(
      id: (json['id'] as num?)?.toInt(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      recordedAt: (json['recorded_at'] ?? '').toString(),
      accuracyM: (json['accuracy_m'] as num?)?.toDouble(),
      speedKmh: (json['speed_kmh'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      altitudeM: (json['altitude_m'] as num?)?.toDouble(),
      batteryLevel: (json['battery_level'] as num?)?.toInt(),
      isMoving: json['is_moving'] == null ? true : (json['is_moving'] == true || json['is_moving'] == 1),
      source: (json['source'] ?? 'background').toString(),
      addressHint: json['address_hint']?.toString(),
    );
  }
}

class TripStopSummary {
  const TripStopSummary({
    required this.startedAt,
    required this.endedAt,
    required this.durationMinutes,
    required this.latitude,
    required this.longitude,
    this.addressHint,
  });

  final String startedAt;
  final String endedAt;
  final int durationMinutes;
  final double latitude;
  final double longitude;
  final String? addressHint;

  factory TripStopSummary.fromJson(Map<String, dynamic> json) {
    return TripStopSummary(
      startedAt: (json['started_at'] ?? '').toString(),
      endedAt: (json['ended_at'] ?? '').toString(),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      addressHint: json['address_hint']?.toString(),
    );
  }
}

class TripTimelineEvent {
  const TripTimelineEvent({
    required this.type,
    required this.at,
    required this.title,
    this.detail,
    this.latitude,
    this.longitude,
  });

  final String type;
  final String at;
  final String title;
  final String? detail;
  final double? latitude;
  final double? longitude;

  factory TripTimelineEvent.fromJson(Map<String, dynamic> json) {
    return TripTimelineEvent(
      type: (json['type'] ?? '').toString(),
      at: (json['at'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      detail: json['detail']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class TripRouteSummary {
  const TripRouteSummary({
    required this.durationMinutes,
    required this.gpsDistanceKm,
    required this.maxSpeedKmh,
    required this.avgSpeedKmh,
    required this.pointsCount,
    this.declaredDistanceKm,
    this.odometerStart,
    this.odometerEnd,
    this.stops = const [],
    this.timeline = const [],
    this.googleMapsRouteUrl,
    this.googleMapsLastUrl,
  });

  final int durationMinutes;
  final double gpsDistanceKm;
  final int? declaredDistanceKm;
  final int? odometerStart;
  final int? odometerEnd;
  final double maxSpeedKmh;
  final double avgSpeedKmh;
  final int pointsCount;
  final List<TripStopSummary> stops;
  final List<TripTimelineEvent> timeline;
  final String? googleMapsRouteUrl;
  final String? googleMapsLastUrl;

  factory TripRouteSummary.fromJson(Map<String, dynamic> json) {
    final stopsJson = json['stops'] as List<dynamic>? ?? const [];
    final timelineJson = json['timeline'] as List<dynamic>? ?? const [];
    return TripRouteSummary(
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      gpsDistanceKm: (json['gps_distance_km'] as num?)?.toDouble() ?? 0.0,
      declaredDistanceKm: (json['declared_distance_km'] as num?)?.toInt(),
      odometerStart: (json['odometer_start'] as num?)?.toInt(),
      odometerEnd: (json['odometer_end'] as num?)?.toInt(),
      maxSpeedKmh: (json['max_speed_kmh'] as num?)?.toDouble() ?? 0.0,
      avgSpeedKmh: (json['avg_speed_kmh'] as num?)?.toDouble() ?? 0.0,
      pointsCount: (json['points_count'] as num?)?.toInt() ?? 0,
      stops: stopsJson
          .whereType<Map<String, dynamic>>()
          .map(TripStopSummary.fromJson)
          .toList(),
      timeline: timelineJson
          .whereType<Map<String, dynamic>>()
          .map(TripTimelineEvent.fromJson)
          .toList(),
      googleMapsRouteUrl: json['google_maps_route_url']?.toString(),
      googleMapsLastUrl: json['google_maps_last_url']?.toString(),
    );
  }
}

class TripTrackingSession {
  const TripTrackingSession({
    required this.id,
    required this.vehicleId,
    required this.driverId,
    required this.deviceUuid,
    required this.deviceName,
    required this.status,
    required this.startedAt,
    this.devicePlatform,
    this.endedAt,
    this.lastPingAt,
    this.lastLatitude,
    this.lastLongitude,
    this.lastSpeedKmh,
    this.lastBatteryLevel,
    this.pointsCount = 0,
    this.gpsDistanceKm = 0.0,
    this.declaredDistanceKm,
    this.maxSpeedKmh = 0.0,
    this.stopsCount = 0,
    this.hasSosAlert = false,
    this.vehicle,
    this.driver,
    this.startedByUser,
    this.salidaBitacora,
    this.regresoBitacora,
    this.assignment,
    this.recentTrail = const [],
  });

  final int id;
  final int vehicleId;
  final int driverId;
  final String deviceUuid;
  final String deviceName;
  final String? devicePlatform;
  final String status;
  final String startedAt;
  final String? endedAt;
  final String? lastPingAt;
  final double? lastLatitude;
  final double? lastLongitude;
  final double? lastSpeedKmh;
  final int? lastBatteryLevel;
  final int pointsCount;
  final double gpsDistanceKm;
  final int? declaredDistanceKm;
  final double maxSpeedKmh;
  final int stopsCount;
  final bool hasSosAlert;
  final Vehicle? vehicle;
  final AppUser? driver;
  final AppUser? startedByUser;
  final BitacoraEntry? salidaBitacora;
  final BitacoraEntry? regresoBitacora;
  final Assignment? assignment;
  final List<TripLocationPoint> recentTrail;

  bool get isActive => status == 'activa';

  factory TripTrackingSession.fromJson(Map<String, dynamic> json) {
    final trailRaw = json['recent_trail'] as List<dynamic>? ?? const [];
    return TripTrackingSession(
      id: (json['id'] as num).toInt(),
      vehicleId: (json['vehicle_id'] as num?)?.toInt() ?? 0,
      driverId: (json['driver_id'] as num?)?.toInt() ?? 0,
      deviceUuid: (json['device_uuid'] ?? '').toString(),
      deviceName: (json['device_name'] ?? '').toString(),
      devicePlatform: json['device_platform']?.toString(),
      status: (json['status'] ?? 'activa').toString(),
      startedAt: (json['started_at'] ?? '').toString(),
      endedAt: json['ended_at']?.toString(),
      lastPingAt: json['last_ping_at']?.toString(),
      lastLatitude: (json['last_latitude'] as num?)?.toDouble(),
      lastLongitude: (json['last_longitude'] as num?)?.toDouble(),
      lastSpeedKmh: (json['last_speed_kmh'] as num?)?.toDouble(),
      lastBatteryLevel: (json['last_battery_level'] as num?)?.toInt(),
      pointsCount: (json['points_count'] as num?)?.toInt() ?? 0,
      gpsDistanceKm: (json['gps_distance_km'] as num?)?.toDouble() ?? 0.0,
      declaredDistanceKm: (json['declared_distance_km'] as num?)?.toInt(),
      maxSpeedKmh: (json['max_speed_kmh'] as num?)?.toDouble() ?? 0.0,
      stopsCount: (json['stops_count'] as num?)?.toInt() ?? 0,
      hasSosAlert: json['has_sos_alert'] == true || json['has_sos_alert'] == 1,
      vehicle: json['vehicle'] is Map<String, dynamic>
          ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      driver: json['driver'] is Map<String, dynamic>
          ? AppUser.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      startedByUser: json['started_by_user'] is Map<String, dynamic>
          ? AppUser.fromJson(json['started_by_user'] as Map<String, dynamic>)
          : null,
      salidaBitacora: json['salida_bitacora'] is Map<String, dynamic>
          ? BitacoraEntry.fromJson(json['salida_bitacora'] as Map<String, dynamic>)
          : null,
      regresoBitacora: json['regreso_bitacora'] is Map<String, dynamic>
          ? BitacoraEntry.fromJson(json['regreso_bitacora'] as Map<String, dynamic>)
          : null,
      assignment: json['assignment'] is Map<String, dynamic>
          ? Assignment.fromJson(json['assignment'] as Map<String, dynamic>)
          : null,
      recentTrail: trailRaw
          .whereType<Map<String, dynamic>>()
          .map(TripLocationPoint.fromJson)
          .toList(),
    );
  }
}

class TripTrackingDetail {
  const TripTrackingDetail({
    required this.session,
    required this.points,
    required this.summary,
  });

  final TripTrackingSession session;
  final List<TripLocationPoint> points;
  final TripRouteSummary summary;

  factory TripTrackingDetail.fromJson(Map<String, dynamic> json) {
    final pointsRaw = json['points'] as List<dynamic>? ?? const [];
    return TripTrackingDetail(
      session: TripTrackingSession.fromJson(json['session'] as Map<String, dynamic>),
      points: pointsRaw
          .whereType<Map<String, dynamic>>()
          .map(TripLocationPoint.fromJson)
          .toList(),
      summary: TripRouteSummary.fromJson(
        (json['summary'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}
