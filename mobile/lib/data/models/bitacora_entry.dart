import 'app_user.dart';
import 'assignment.dart';
import 'tracking_models.dart';
import 'vehicle.dart';

class BitacoraEntry {
  const BitacoraEntry({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.tripCategory,
    required this.recordedAt,
    this.assignmentId,
    this.odometerKm,
    this.fuelLevel,
    this.destination,
    this.destinationAddress,
    this.latitude,
    this.longitude,
    this.companions,
    this.officialInstruction,
    this.notes,
    this.vehicle,
    this.driver,
    this.user,
    this.assignment,
    this.trackingSession,
    this.regresoTrackingSession,
  });

  final int id;
  final int vehicleId;
  final int? assignmentId;
  final String type;
  final String tripCategory;
  final String recordedAt;
  final int? odometerKm;
  final String? fuelLevel;
  final String? destination;
  final String? destinationAddress;
  final double? latitude;
  final double? longitude;
  final String? companions;
  final String? officialInstruction;
  final String? notes;
  final Vehicle? vehicle;
  final AppUser? driver;
  final AppUser? user;
  final Assignment? assignment;
  final TripTrackingSession? trackingSession;
  final TripTrackingSession? regresoTrackingSession;

  TripTrackingSession? get linkedTracking => trackingSession ?? regresoTrackingSession;

  factory BitacoraEntry.fromJson(Map<String, dynamic> json) {
    return BitacoraEntry(
      id: (json['id'] as num).toInt(),
      vehicleId: (json['vehicle_id'] as num?)?.toInt() ?? 0,
      assignmentId: (json['assignment_id'] as num?)?.toInt(),
      type: (json['type'] ?? 'salida').toString(),
      tripCategory: (json['trip_category'] ?? 'asignacion').toString(),
      recordedAt: (json['recorded_at'] ?? '').toString(),
      odometerKm: (json['odometer_km'] as num?)?.toInt(),
      fuelLevel: json['fuel_level']?.toString(),
      destination: json['destination']?.toString(),
      destinationAddress: json['destination_address']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      companions: json['companions']?.toString(),
      officialInstruction: json['official_instruction']?.toString(),
      notes: json['notes']?.toString(),
      vehicle: json['vehicle'] is Map<String, dynamic>
          ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      driver: json['driver'] is Map<String, dynamic>
          ? AppUser.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      user: json['user'] is Map<String, dynamic>
          ? AppUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      assignment: json['assignment'] is Map<String, dynamic>
          ? Assignment.fromJson(json['assignment'] as Map<String, dynamic>)
          : null,
      trackingSession: json['tracking_session'] is Map<String, dynamic>
          ? TripTrackingSession.fromJson(json['tracking_session'] as Map<String, dynamic>)
          : null,
      regresoTrackingSession: json['regreso_tracking_session'] is Map<String, dynamic>
          ? TripTrackingSession.fromJson(json['regreso_tracking_session'] as Map<String, dynamic>)
          : null,
    );
  }
}
