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
    this.bitacoraId,
    this.costUsd,
    this.station,
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.receiptUrl,
    this.receiptName,
    this.fullTank = true,
    this.kmSinceLast,
    this.kmPerGallon,
    this.notes,
    this.vehicle,
    this.driverName,
  });

  final int id;
  final int vehicleId;
  final int? bitacoraId;
  final int odometerKm;
  final double gallons;
  final String fuelType;
  final String filledAt;
  final double? costUsd;
  final String? station;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  final String? receiptUrl;
  final String? receiptName;
  final bool fullTank;
  final int? kmSinceLast;
  final double? kmPerGallon;
  final String? notes;
  final Vehicle? vehicle;
  final String? driverName;

  bool get hasGps => latitude != null && longitude != null;
  bool get hasReceipt => receiptUrl != null && receiptUrl!.isNotEmpty;

  factory FuelLogEntry.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] as Map<String, dynamic>?;
    final recorder = json['recorder'] as Map<String, dynamic>?;
    return FuelLogEntry(
      id: (json['id'] as num).toInt(),
      vehicleId: (json['vehicle_id'] as num?)?.toInt() ?? 0,
      bitacoraId: (json['bitacora_id'] as num?)?.toInt(),
      odometerKm: (json['odometer_km'] as num?)?.toInt() ?? 0,
      gallons: (json['gallons'] as num?)?.toDouble() ?? 0.0,
      fuelType: (json['fuel_type'] ?? 'regular').toString(),
      filledAt: (json['filled_at'] ?? '').toString(),
      costUsd: (json['cost_usd'] as num?)?.toDouble(),
      station: json['station']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationAddress: json['location_address']?.toString(),
      receiptUrl: json['receipt_url']?.toString(),
      receiptName: json['receipt_name']?.toString(),
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

class FuelSummaryTotals {
  const FuelSummaryTotals({
    this.kmTraveled = 0,
    this.gallons = 0,
    this.costUsd = 0,
    this.costPerKm,
    this.kmPerGallon,
    this.refillsCount = 0,
  });

  final int kmTraveled;
  final double gallons;
  final double costUsd;
  final double? costPerKm;
  final double? kmPerGallon;
  final int refillsCount;

  factory FuelSummaryTotals.fromJson(Map<String, dynamic> json) {
    return FuelSummaryTotals(
      kmTraveled: (json['km_traveled'] as num?)?.toInt() ?? 0,
      gallons: (json['gallons'] as num?)?.toDouble() ?? 0,
      costUsd: (json['cost_usd'] as num?)?.toDouble() ?? 0,
      costPerKm: (json['cost_per_km'] as num?)?.toDouble(),
      kmPerGallon: (json['km_per_gallon'] as num?)?.toDouble(),
      refillsCount: (json['refills_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class FuelVehicleSummary {
  const FuelVehicleSummary({
    required this.vehicleId,
    required this.licensePlate,
    this.plateType,
    this.plateNumber,
    this.brand = '',
    this.model = '',
    this.kmTraveled = 0,
    this.gallons = 0,
    this.costUsd = 0,
    this.costPerKm,
    this.kmPerGallon,
    this.refillsCount = 0,
  });

  final int vehicleId;
  final String licensePlate;
  final String? plateType;
  final String? plateNumber;
  final String brand;
  final String model;
  final int kmTraveled;
  final double gallons;
  final double costUsd;
  final double? costPerKm;
  final double? kmPerGallon;
  final int refillsCount;

  factory FuelVehicleSummary.fromJson(Map<String, dynamic> json) {
    return FuelVehicleSummary(
      vehicleId: (json['vehicle_id'] as num?)?.toInt() ?? 0,
      licensePlate: (json['license_plate'] ?? '').toString(),
      plateType: json['plate_type']?.toString(),
      plateNumber: json['plate_number']?.toString(),
      brand: (json['brand'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      kmTraveled: (json['km_traveled'] as num?)?.toInt() ?? 0,
      gallons: (json['gallons'] as num?)?.toDouble() ?? 0,
      costUsd: (json['cost_usd'] as num?)?.toDouble() ?? 0,
      costPerKm: (json['cost_per_km'] as num?)?.toDouble(),
      kmPerGallon: (json['km_per_gallon'] as num?)?.toDouble(),
      refillsCount: (json['refills_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class FuelSummaryReport {
  const FuelSummaryReport({
    required this.range,
    required this.totals,
    required this.byVehicle,
  });

  final String range;
  final FuelSummaryTotals totals;
  final List<FuelVehicleSummary> byVehicle;

  factory FuelSummaryReport.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>? ?? const {};
    final totalsMap = json['totals'] as Map<String, dynamic>? ?? const {};
    final rawVehicles = json['by_vehicle'] as List<dynamic>? ?? const [];
    return FuelSummaryReport(
      range: (period['range'] ?? 'week').toString(),
      totals: FuelSummaryTotals.fromJson(totalsMap),
      byVehicle: rawVehicles
          .whereType<Map<String, dynamic>>()
          .map(FuelVehicleSummary.fromJson)
          .toList(),
    );
  }
}
