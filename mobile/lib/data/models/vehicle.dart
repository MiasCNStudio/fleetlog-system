class Vehicle {
  const Vehicle({
    required this.id,
    required this.licensePlate,
    required this.brand,
    required this.model,
    required this.color,
    required this.status,
    required this.currentOdometer,
    this.photoUrl,
  });

  final int id;
  final String licensePlate;
  final String brand;
  final String model;
  final String color;
  final String status;
  final int currentOdometer;
  final String? photoUrl;

  bool get isAvailable => status == 'disponible';
  bool get isInRoute => status == 'en_ruta';
  bool get isMaintenance => status == 'mantenimiento';

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: (json['id'] as num).toInt(),
      licensePlate: (json['license_plate'] ?? '').toString(),
      brand: (json['brand'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      color: (json['color'] ?? '').toString(),
      status: (json['status'] ?? 'disponible').toString(),
      currentOdometer: (json['current_odometer'] as num?)?.toInt() ?? 0,
      photoUrl: json['photo_url']?.toString(),
    );
  }
}
