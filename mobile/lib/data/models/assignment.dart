import 'app_user.dart';
import 'vehicle.dart';

class Assignment {
  const Assignment({
    required this.id,
    required this.vehicleId,
    required this.driverId,
    required this.scheduledDate,
    required this.destination,
    required this.status,
    this.scheduledTime,
    this.destinationAddress,
    this.latitude,
    this.longitude,
    this.placeId,
    this.companions,
    this.description,
    this.officialInstruction,
    this.isEmergencyReassigned = false,
    this.reassignmentReason,
    this.vehicle,
    this.driver,
    this.originalDriver,
  });

  final int id;
  final int vehicleId;
  final int driverId;
  final String scheduledDate;
  final String? scheduledTime;
  final String destination;
  final String? destinationAddress;
  final double? latitude;
  final double? longitude;
  final String? placeId;
  final String? companions;
  final String? description;
  final String? officialInstruction;
  final String status;
  final bool isEmergencyReassigned;
  final String? reassignmentReason;
  final Vehicle? vehicle;
  final AppUser? driver;
  final AppUser? originalDriver;

  bool get isPending => status == 'pendiente';
  bool get isInProgress => status == 'en_curso';
  bool get isCompleted => status == 'completada';
  bool get isCancelled => status == 'cancelada';

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: (json['id'] as num).toInt(),
      vehicleId: (json['vehicle_id'] as num?)?.toInt() ?? 0,
      driverId: (json['driver_id'] as num?)?.toInt() ?? 0,
      scheduledDate: (json['scheduled_date'] ?? '').toString(),
      scheduledTime: json['scheduled_time']?.toString(),
      destination: (json['destination'] ?? '').toString(),
      destinationAddress: json['destination_address']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      placeId: json['place_id']?.toString(),
      companions: json['companions']?.toString(),
      description: json['description']?.toString(),
      officialInstruction: json['official_instruction']?.toString(),
      status: (json['status'] ?? 'pendiente').toString(),
      isEmergencyReassigned: json['is_emergency_reassigned'] == true ||
          json['is_emergency_reassigned'] == 1,
      reassignmentReason: json['reassignment_reason']?.toString(),
      vehicle: json['vehicle'] is Map<String, dynamic>
          ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      driver: json['driver'] is Map<String, dynamic>
          ? AppUser.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      originalDriver: json['original_driver'] is Map<String, dynamic>
          ? AppUser.fromJson(json['original_driver'] as Map<String, dynamic>)
          : null,
    );
  }
}
