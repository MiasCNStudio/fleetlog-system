import 'app_user.dart';
import 'vehicle.dart';

class IncidentEntry {
  const IncidentEntry({
    required this.id,
    required this.vehicleId,
    required this.title,
    required this.severity,
    required this.status,
    required this.reportedAt,
    this.description,
    this.photoUrl,
    this.vehicle,
    this.reporter,
  });

  final int id;
  final int vehicleId;
  final String title;
  final String? description;
  final String severity;
  final String status;
  final String reportedAt;
  final String? photoUrl;
  final Vehicle? vehicle;
  final AppUser? reporter;

  factory IncidentEntry.fromJson(Map<String, dynamic> json) {
    return IncidentEntry(
      id: (json['id'] as num).toInt(),
      vehicleId: (json['vehicle_id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      severity: (json['severity'] ?? 'media').toString(),
      status: (json['status'] ?? 'abierta').toString(),
      reportedAt: (json['reported_at'] ?? '').toString(),
      photoUrl: json['photo_url']?.toString(),
      vehicle: json['vehicle'] is Map<String, dynamic>
          ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      reporter: json['reporter'] is Map<String, dynamic>
          ? AppUser.fromJson(json['reporter'] as Map<String, dynamic>)
          : null,
    );
  }
}
