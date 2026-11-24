import 'vehicle.dart';

class VehicleMaintenanceEntry {
  const VehicleMaintenanceEntry({
    required this.id,
    required this.vehicleId,
    required this.title,
    required this.status,
    this.description,
    this.scheduledOdometerKm,
    this.completedOdometerKm,
    this.scheduledDate,
    this.completedAt,
    this.workshop,
    this.costUsd,
    this.notes,
    this.vehicle,
  });

  final int id;
  final int vehicleId;
  final String title;
  final String status;
  final String? description;
  final int? scheduledOdometerKm;
  final int? completedOdometerKm;
  final String? scheduledDate;
  final String? completedAt;
  final String? workshop;
  final double? costUsd;
  final String? notes;
  final Vehicle? vehicle;

  factory VehicleMaintenanceEntry.fromJson(Map<String, dynamic> json) {
    return VehicleMaintenanceEntry(
      id: (json['id'] as num).toInt(),
      vehicleId: (json['vehicle_id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? 'programado').toString(),
      description: json['description']?.toString(),
      scheduledOdometerKm: (json['scheduled_odometer_km'] as num?)?.toInt(),
      completedOdometerKm: (json['completed_odometer_km'] as num?)?.toInt(),
      scheduledDate: json['scheduled_date']?.toString(),
      completedAt: json['completed_at']?.toString(),
      workshop: json['workshop']?.toString(),
      costUsd: (json['cost_usd'] as num?)?.toDouble(),
      notes: json['notes']?.toString(),
      vehicle: json['vehicle'] is Map<String, dynamic>
          ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
    );
  }
}

class FuelLogEntry {
  const FuelLogEntry({
    required this.id,
    required this.vehicleId,
    required this.odometerKm,
    required this.gallons,
    required this.fuelType,
    required this.filledAt,
    this.costUsd,
    this.station,
    this.fullTank = true,
    this.kmSinceLast,
    this.kmPerGallon,
    this.notes,
    this.vehicle,
    this.driverName,
  });

  final int id;
  final int vehicleId;
  final int odometerKm;
  final double gallons;
  final String fuelType;
  final String filledAt;
  final double? costUsd;
  final String? station;
  final bool fullTank;
  final int? kmSinceLast;
  final double? kmPerGallon;
  final String? notes;
  final Vehicle? vehicle;
  final String? driverName;

  factory FuelLogEntry.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] as Map<String, dynamic>?;
    final recorder = json['recorder'] as Map<String, dynamic>?;
    return FuelLogEntry(
      id: (json['id'] as num).toInt(),
      vehicleId: (json['vehicle_id'] as num?)?.toInt() ?? 0,
      odometerKm: (json['odometer_km'] as num?)?.toInt() ?? 0,
      gallons: (json['gallons'] as num?)?.toDouble() ?? 0.0,
      fuelType: (json['fuel_type'] ?? 'regular').toString(),
      filledAt: (json['filled_at'] ?? '').toString(),
      costUsd: (json['cost_usd'] as num?)?.toDouble(),
      station: json['station']?.toString(),
      fullTank: json['full_tank'] == null
          ? true
          : (json['full_tank'] == true || json['full_tank'] == 1),
      kmSinceLast: (json['km_since_last'] as num?)?.toInt(),
      kmPerGallon: (json['km_per_gallon'] as num?)?.toDouble(),
      notes: json['notes']?.toString(),
      vehicle: json['vehicle'] is Map<String, dynamic>
          ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      driverName: (driver?['name'] ?? recorder?['name'])?.toString(),
    );
  }
}
