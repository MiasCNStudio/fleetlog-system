class Vehicle {
  const Vehicle({
    required this.id,
    required this.licensePlate,
    required this.brand,
    required this.model,
    required this.color,
    required this.status,
    required this.currentOdometer,
    this.plateType,
    this.plateNumber,
    this.maintenanceIntervalKm = 5000,
    this.nextMaintenanceOdometer,
    this.maintenanceAlertBeforeKm = 500,
    this.maintenanceStatus = 'sin_programar',
    this.kmToMaintenance,
    this.photoUrl,
  });

  final int id;
  final String licensePlate;
  final String? plateType;
  final String? plateNumber;
  final String brand;
  final String model;
  final String color;
  final String status;
  final int currentOdometer;
  final int maintenanceIntervalKm;
  final int? nextMaintenanceOdometer;
  final int maintenanceAlertBeforeKm;
  final String maintenanceStatus;
  final int? kmToMaintenance;
  final String? photoUrl;

  bool get isAvailable => status == 'disponible';
  bool get isInRoute => status == 'en_ruta';
  bool get isMaintenance => status == 'mantenimiento';
  bool get hasMaintenanceAlert =>
      maintenanceStatus == 'vencido' || maintenanceStatus == 'pronto';

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: (json['id'] as num).toInt(),
      licensePlate: (json['license_plate'] ?? '').toString(),
      plateType: json['plate_type']?.toString(),
      plateNumber: json['plate_number']?.toString(),
      brand: (json['brand'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      color: (json['color'] ?? '').toString(),
      status: (json['status'] ?? 'disponible').toString(),
      currentOdometer: (json['current_odometer'] as num?)?.toInt() ?? 0,
      maintenanceIntervalKm: (json['maintenance_interval_km'] as num?)?.toInt() ?? 5000,
      nextMaintenanceOdometer: (json['next_maintenance_odometer'] as num?)?.toInt(),
      maintenanceAlertBeforeKm: (json['maintenance_alert_before_km'] as num?)?.toInt() ?? 500,
      maintenanceStatus: (json['maintenance_status'] ?? 'sin_programar').toString(),
      kmToMaintenance: (json['km_to_maintenance'] as num?)?.toInt(),
      photoUrl: json['photo_url']?.toString(),
    );
  }
}
