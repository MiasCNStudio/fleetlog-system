class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.userType,
    this.driverCode,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? userType;
  final String? driverCode;

  bool get isAdmin => role == 'admin';
  bool get isDispatcher => role == 'despachador';
  bool get isDriver => role == 'motorista';
  bool get canManageFleet => isAdmin || isDispatcher;

  String get roleLabel => switch (role) {
    'admin' => 'Administrador',
    'despachador' => 'Jefe de motoristas',
    _ => 'Motorista',
  };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'motorista').toString(),
      userType: json['user_type']?.toString(),
      driverCode: json['driver_code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'user_type': userType,
    'driver_code': driverCode,
  };
}
