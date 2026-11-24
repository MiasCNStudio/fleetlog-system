import 'assignment.dart';
import 'incident_entry.dart';

class ActiveTripSummary {
  const ActiveTripSummary({
    required this.vehicleId,
    required this.licensePlate,
    required this.brand,
    required this.model,
    this.destination,
    this.destinationAddress,
    this.latitude,
    this.longitude,
    this.recordedAt,
    this.driverId,
    this.driverName,
    this.odometerKm,
  });

  final int vehicleId;
  final String licensePlate;
  final String brand;
  final String model;
  final String? destination;
  final String? destinationAddress;
  final double? latitude;
  final double? longitude;
  final String? recordedAt;
  final int? driverId;
  final String? driverName;
  final int? odometerKm;

  factory ActiveTripSummary.fromJson(Map<String, dynamic> json) {
    return ActiveTripSummary(
      vehicleId: (json['vehicle_id'] as num).toInt(),
      licensePlate: (json['license_plate'] ?? '').toString(),
      brand: (json['brand'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      destination: json['destination']?.toString(),
      destinationAddress: json['destination_address']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      recordedAt: json['recorded_at']?.toString(),
      driverId: (json['driver_id'] as num?)?.toInt(),
      driverName: json['driver_name']?.toString(),
      odometerKm: (json['odometer_km'] as num?)?.toInt(),
    );
  }
}

class DashboardSummary {
  const DashboardSummary({
    this.activeTrips = 0,
    this.availableVehicles = 0,
    this.driversInRoute = 0,
    this.incidentsToday = 0,
    this.openIncidents = 0,
    this.maintenanceVehicles = 0,
    this.totalVehicles = 0,
    this.pendingAssignments = 0,
    this.emergencyReassignmentsToday = 0,
  });

  final int activeTrips;
  final int availableVehicles;
  final int driversInRoute;
  final int incidentsToday;
  final int openIncidents;
  final int maintenanceVehicles;
  final int totalVehicles;
  final int pendingAssignments;
  final int emergencyReassignmentsToday;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      activeTrips: (json['viajes_activos'] as num?)?.toInt() ?? 0,
      availableVehicles: (json['unidades_disponibles'] as num?)?.toInt() ?? 0,
      driversInRoute: (json['conductores_en_ruta'] as num?)?.toInt() ?? 0,
      incidentsToday: (json['incidencias_hoy'] as num?)?.toInt() ?? 0,
      openIncidents: (json['incidencias_abiertas'] as num?)?.toInt() ?? 0,
      maintenanceVehicles: (json['unidades_mantenimiento'] as num?)?.toInt() ?? 0,
      totalVehicles: (json['total_vehiculos'] as num?)?.toInt() ?? 0,
      pendingAssignments: (json['asignaciones_pendientes'] as num?)?.toInt() ?? 0,
      emergencyReassignmentsToday: (json['reasignaciones_emergencia_hoy'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardData {
  const DashboardData({
    required this.summary,
    this.activeTrips = const [],
    this.recentIncidents = const [],
    this.upcomingAssignments = const [],
    this.myAssignments = const [],
    this.myActiveTrip,
  });

  final DashboardSummary summary;
  final List<ActiveTripSummary> activeTrips;
  final List<IncidentEntry> recentIncidents;
  final List<Assignment> upcomingAssignments;
  final List<Assignment> myAssignments;
  final ActiveTripSummary? myActiveTrip;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final activeRaw = json['active_trips'] as List<dynamic>? ?? const [];
    final incidentsRaw = json['recent_incidents'] as List<dynamic>? ?? const [];
    final upcomingRaw = json['upcoming_assignments'] as List<dynamic>? ?? const [];
    final mineRaw = json['my_assignments'] as List<dynamic>? ?? const [];

    return DashboardData(
      summary: DashboardSummary.fromJson(
        (json['summary'] as Map<String, dynamic>?) ?? const {},
      ),
      activeTrips: activeRaw
          .whereType<Map<String, dynamic>>()
          .map(ActiveTripSummary.fromJson)
          .toList(),
      recentIncidents: incidentsRaw
          .whereType<Map<String, dynamic>>()
          .map(IncidentEntry.fromJson)
          .toList(),
      upcomingAssignments: upcomingRaw
          .whereType<Map<String, dynamic>>()
          .map(Assignment.fromJson)
          .toList(),
      myAssignments: mineRaw
          .whereType<Map<String, dynamic>>()
          .map(Assignment.fromJson)
          .toList(),
      myActiveTrip: json['my_active_trip'] is Map<String, dynamic>
          ? ActiveTripSummary.fromJson(json['my_active_trip'] as Map<String, dynamic>)
          : null,
    );
  }
}
