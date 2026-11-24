import 'package:battery_plus/battery_plus.dart';
import 'package:dio/dio.dart';

import '../models/app_user.dart';
import '../models/assignment.dart';
import '../models/bitacora_entry.dart';
import '../models/dashboard_data.dart';
import '../models/incident_entry.dart';
import '../models/maintenance_fuel_models.dart';
import '../models/place_suggestion.dart';
import '../models/system_log_entry.dart';
import '../models/vehicle.dart';
import '../services/api_client.dart';
import '../services/background_tracking_service.dart';
import '../services/device_identity_service.dart';
import 'tracking_repository.dart';

class FleetRepository {
  FleetRepository({
    required ApiClient apiClient,
    required DeviceIdentityService deviceIdentityService,
  }) : _api = apiClient,
       _device = deviceIdentityService;

  final ApiClient _api;
  final DeviceIdentityService _device;

  Future<DashboardData> fetchDashboard({String period = '7d'}) async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(
        '/dashboard',
        queryParameters: {'period': period},
      );
      return DashboardData.fromJson(res.data ?? const {});
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    if (query.trim().length < 2) return const [];
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(
        '/places/search',
        queryParameters: {'q': query.trim()},
      );
      final raw = res.data?['data'] as List<dynamic>? ?? const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(PlaceSuggestion.fromJson)
          .toList();
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<PlaceSuggestion?> reversePlace(double lat, double lng) async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(
        '/places/reverse',
        queryParameters: {'lat': lat, 'lng': lng},
      );
      final raw = res.data?['data'];
      if (raw is Map<String, dynamic>) {
        return PlaceSuggestion.fromJson(raw);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Vehicle>> fetchVehicleOptions() async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>('/vehicles/options');
      final raw = res.data?['data'] as List<dynamic>? ?? const [];
      return raw.whereType<Map<String, dynamic>>().map(Vehicle.fromJson).toList();
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<List<AppUser>> fetchDriverOptions() async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>('/drivers/options');
      final raw = res.data?['data'] as List<dynamic>? ?? const [];
      return raw.whereType<Map<String, dynamic>>().map(AppUser.fromJson).toList();
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<List<Assignment>> fetchAssignmentOptions() async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>('/assignments/options');
      final raw = res.data?['data'] as List<dynamic>? ?? const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(Assignment.fromJson)
          .toList();
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<({String type, String status, int currentOdometer})> fetchNextType(
    int vehicleId,
  ) async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(
        '/vehicles/$vehicleId/siguiente-tipo-bitacora',
      );
      final data = res.data ?? const {};
      return (
        type: (data['type'] ?? 'salida').toString(),
        status: (data['status'] ?? 'disponible').toString(),
        currentOdometer: (data['current_odometer'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<PaginatedResult<Assignment>> fetchAssignments({
    int page = 1,
    String range = 'all',
    String? status,
    int? driverId,
    int? vehicleId,
    String? dateFrom,
    String? dateTo,
    bool mine = false,
  }) async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(
        '/assignments',
        queryParameters: {
          'page': page,
          if (range != 'all') 'range': range,
          if (status != null && status.isNotEmpty) 'status': status,
          'driver_id': ?driverId,
          'vehicle_id': ?vehicleId,
          if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
          if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
          if (mine) 'mine': 1,
        },
      );
      final body = res.data ?? const {};
      final raw = body['data'] as List<dynamic>? ?? const [];
      return PaginatedResult(
        items: raw
            .whereType<Map<String, dynamic>>()
            .map(Assignment.fromJson)
            .toList(),
        currentPage: (body['current_page'] as num?)?.toInt() ?? 1,
        lastPage: (body['last_page'] as num?)?.toInt() ?? 1,
        total: (body['total'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> createAssignment(Map<String, dynamic> payload) async {
    try {
      await _api.dio.post('/assignments', data: payload);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> deleteAssignment(int id) async {
    try {
      await _api.dio.delete('/assignments/$id');
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<Assignment> emergencyReassign({
    required int assignmentId,
    required String reason,
    int? newDriverId,
  }) async {
    try {
      final res = await _api.dio.post<Map<String, dynamic>>(
        '/assignments/$assignmentId/emergency-reassign',
        data: {
          'reason': reason.trim(),
          'new_driver_id': ?newDriverId,
        },
      );
      final raw = res.data?['data'] ?? res.data;
      return Assignment.fromJson(raw as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<PaginatedResult<BitacoraEntry>> fetchBitacoras({
    int page = 1,
    int? vehicleId,
    String? type,
    String? tripCategory,
    bool mine = false,
  }) async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(
        '/bitacoras',
        queryParameters: {
          'page': page,
          'vehicle_id': ?vehicleId,
          if (type != null && type.isNotEmpty) 'type': type,
          if (tripCategory != null && tripCategory.isNotEmpty)
            'trip_category': tripCategory,
          if (mine) 'mine': 1,
        },
      );
      final body = res.data ?? const {};
      final raw = body['data'] as List<dynamic>? ?? const [];
      return PaginatedResult(
        items: raw
            .whereType<Map<String, dynamic>>()
            .map(BitacoraEntry.fromJson)
            .toList(),
        currentPage: (body['current_page'] as num?)?.toInt() ?? 1,
        lastPage: (body['last_page'] as num?)?.toInt() ?? 1,
        total: (body['total'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<BitacoraEntry> createBitacora(Map<String, dynamic> payload) async {
    try {
      final identity = await _device.getIdentity();
      final pos = await BackgroundTrackingService.tryCurrentPosition();
      int? batteryLevel;
      try {
        batteryLevel = await Battery().batteryLevel;
      } catch (_) {}

      final merged = <String, dynamic>{
        ...payload,
        'device_uuid': identity.uuid,
        'device_name': identity.name,
        'device_platform': identity.platform,
        if (pos != null) 'initial_latitude': pos.latitude,
        if (pos != null) 'initial_longitude': pos.longitude,
        if (pos != null) 'initial_accuracy_m': pos.accuracy,
        'battery_level': ?batteryLevel,
      };

      final res = await _api.dio.post<Map<String, dynamic>>(
        '/bitacoras',
        data: merged,
      );
      final created = BitacoraEntry.fromJson(res.data ?? const {});

      if (created.type == 'salida' && created.trackingSession != null) {
        await BackgroundTrackingService.startMission(
          sessionId: created.trackingSession!.id,
          vehiclePlate: created.vehicle?.licensePlate ?? 'Unidad',
          destination: created.destination,
        );
      } else if (created.type == 'regreso') {
        await BackgroundTrackingService.stopMission();
      }

      return created;
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<PaginatedResult<Vehicle>> fetchVehicles({
    int page = 1,
    String? search,
    String? status,
  }) async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(
        '/vehicles',
        queryParameters: {
          'page': page,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      final body = res.data ?? const {};
      final raw = body['data'] as List<dynamic>? ?? const [];
      return PaginatedResult(
        items: raw.whereType<Map<String, dynamic>>().map(Vehicle.fromJson).toList(),
        currentPage: (body['current_page'] as num?)?.toInt() ?? 1,
        lastPage: (body['last_page'] as num?)?.toInt() ?? 1,
        total: (body['total'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> saveVehicle({
    int? id,
    required String licensePlate,
    String? plateType,
    String? plateNumber,
    required String brand,
    required String model,
    required String color,
    required String status,
    required int currentOdometer,
    int? nextMaintenanceOdometer,
    int? maintenanceIntervalKm,
    int? maintenanceAlertBeforeKm,
  }) async {
    try {
      final data = {
        'license_plate': licensePlate.trim().toUpperCase(),
        'plate_type': ?plateType,
        'plate_number': ?plateNumber,
        'brand': brand.trim(),
        'model': model.trim(),
        'color': color.trim(),
        'status': status,
        'current_odometer': currentOdometer,
        'next_maintenance_odometer': ?nextMaintenanceOdometer,
        'maintenance_interval_km': ?maintenanceIntervalKm,
        'maintenance_alert_before_km': ?maintenanceAlertBeforeKm,
      };
      if (id == null) {
        await _api.dio.post('/vehicles', data: data);
      } else {
        await _api.dio.put('/vehicles/$id', data: data);
      }
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<PaginatedResult<IncidentEntry>> fetchIncidents({
    int page = 1,
    String? status,
    String? severity,
  }) async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(
        '/incidents',
        queryParameters: {
          'page': page,
          if (status != null && status.isNotEmpty) 'status': status,
          if (severity != null && severity.isNotEmpty) 'severity': severity,
        },
      );
      final body = res.data ?? const {};
      final raw = body['data'] as List<dynamic>? ?? const [];
      return PaginatedResult(
        items: raw
            .whereType<Map<String, dynamic>>()
            .map(IncidentEntry.fromJson)
            .toList(),
        currentPage: (body['current_page'] as num?)?.toInt() ?? 1,
        lastPage: (body['last_page'] as num?)?.toInt() ?? 1,
        total: (body['total'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> createIncident({
    required int vehicleId,
    required String title,
    required String description,
    required String severity,
    String? photoPath,
  }) async {
    try {
      final form = FormData.fromMap({
        'vehicle_id': vehicleId,
        'title': title.trim(),
        'description': description.trim(),
        'severity': severity,
        if (photoPath != null && photoPath.isNotEmpty)
          'photo': await MultipartFile.fromFile(photoPath),
      });
      await _api.dio.post('/incidents', data: form);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> updateIncidentStatus(int id, String status) async {
    try {
      await _api.dio.put('/incidents/$id', data: {'status': status});
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<PaginatedResult<SystemLogEntry>> fetchSystemLogs({
    int page = 1,
    String? search,
    String? module,
    String? action,
  }) async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(
        '/system-logs',
        queryParameters: {
          'page': page,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (module != null && module.isNotEmpty) 'module': module,
          if (action != null && action.isNotEmpty) 'action': action,
        },
      );
      final body = res.data ?? const {};
      final raw = body['data'] as List<dynamic>? ?? const [];
      return PaginatedResult(
        items: raw
            .whereType<Map<String, dynamic>>()
            .map(SystemLogEntry.fromJson)
            .toList(),
        currentPage: (body['current_page'] as num?)?.toInt() ?? 1,
        lastPage: (body['last_page'] as num?)?.toInt() ?? 1,
        total: (body['total'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<PaginatedResult<AppUser>> fetchUsers({int page = 1, String? search}) async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(
        '/users',
        queryParameters: {
          'page': page,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );
      final body = res.data ?? const {};
      final raw = body['data'] as List<dynamic>? ?? const [];
      return PaginatedResult(
        items: raw.whereType<Map<String, dynamic>>().map(AppUser.fromJson).toList(),
        currentPage: (body['current_page'] as num?)?.toInt() ?? 1,
        lastPage: (body['last_page'] as num?)?.toInt() ?? 1,
        total: (body['total'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> saveUser({
    int? id,
    required String name,
    required String email,
    required String role,
    String? driverCode,
    String? password,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
        'role': role,
        'user_type': role == 'motorista' ? 'motorista' : 'funcionario',
        if (driverCode != null && driverCode.trim().isNotEmpty)
          'driver_code': driverCode.trim(),
        if (password != null && password.isNotEmpty) 'password': password,
      };
      if (id == null) {
        await _api.dio.post('/users', data: payload);
      } else {
        await _api.dio.put('/users/$id', data: payload);
      }
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<({List<VehicleMaintenanceEntry> records, List<Vehicle> alerts})> fetchMaintenances({
    int page = 1,
    int? vehicleId,
    String? status,
  }) async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(
        '/maintenances',
        queryParameters: {
          'page': page,
          'vehicle_id': ?vehicleId,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      final body = res.data ?? const {};
      final recMap = body['records'] as Map<String, dynamic>? ?? const {};
      final rawRecs = recMap['data'] as List<dynamic>? ?? const [];
      final rawAlerts = body['alerts'] as List<dynamic>? ?? const [];
      return (
        records: rawRecs
            .whereType<Map<String, dynamic>>()
            .map(VehicleMaintenanceEntry.fromJson)
            .toList(),
        alerts: rawAlerts
            .whereType<Map<String, dynamic>>()
            .map(Vehicle.fromJson)
            .toList(),
      );
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> createMaintenance(Map<String, dynamic> payload) async {
    try {
      await _api.dio.post('/maintenances', data: payload);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> completeMaintenance(int id, Map<String, dynamic> payload) async {
    try {
      await _api.dio.post('/maintenances/$id/complete', data: payload);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<PaginatedResult<FuelLogEntry>> fetchFuelLogs({
    int page = 1,
    int? vehicleId,
    String? fuelType,
  }) async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(
        '/fuel-logs',
        queryParameters: {
          'page': page,
          'vehicle_id': ?vehicleId,
          if (fuelType != null && fuelType.isNotEmpty) 'fuel_type': fuelType,
        },
      );
      final body = res.data ?? const {};
      final raw = body['data'] as List<dynamic>? ?? const [];
      return PaginatedResult(
        items: raw
            .whereType<Map<String, dynamic>>()
            .map(FuelLogEntry.fromJson)
            .toList(),
        currentPage: (body['current_page'] as num?)?.toInt() ?? 1,
        lastPage: (body['last_page'] as num?)?.toInt() ?? 1,
        total: (body['total'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<BitacoraEntry> startAssignmentFromFuel({
    required int assignmentId,
    int? odometerKm,
    String? fuelLevel,
    String? notes,
  }) async {
    try {
      final identity = await _device.getIdentity();
      final pos = await BackgroundTrackingService.tryCurrentPosition();
      int? batteryLevel;
      try {
        batteryLevel = await Battery().batteryLevel;
      } catch (_) {}

      final res = await _api.dio.post<Map<String, dynamic>>(
        '/assignments/$assignmentId/start-from-fuel',
        data: {
          'odometer_km': ?odometerKm,
          if (fuelLevel != null && fuelLevel.isNotEmpty) 'fuel_level': fuelLevel,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
          'device_uuid': identity.uuid,
          'device_name': identity.name,
          'device_platform': identity.platform,
          if (pos != null) 'initial_latitude': pos.latitude,
          if (pos != null) 'initial_longitude': pos.longitude,
          if (pos != null) 'initial_accuracy_m': pos.accuracy,
          'battery_level': ?batteryLevel,
        },
      );
      final created = BitacoraEntry.fromJson(res.data ?? const {});
      if (created.trackingSession != null) {
        await BackgroundTrackingService.startMission(
          sessionId: created.trackingSession!.id,
          vehiclePlate: created.vehicle?.licensePlate ?? 'Unidad',
          destination: created.destination,
        );
      }
      return created;
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<FuelSummaryReport> fetchFuelSummary({
    String range = 'week',
    int? vehicleId,
  }) async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(
        '/fuel-logs/summary',
        queryParameters: {
          'range': range,
          'vehicle_id': ?vehicleId,
        },
      );
      return FuelSummaryReport.fromJson(res.data ?? const {});
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> createFuelLog(
    Map<String, dynamic> payload, {
    String? receiptFilePath,
    bool captureGps = true,
  }) async {
    try {
      final data = <String, dynamic>{...payload};
      if (captureGps &&
          data['latitude'] == null &&
          data['longitude'] == null) {
        final pos = await BackgroundTrackingService.tryCurrentPosition();
        if (pos != null) {
          data['latitude'] = pos.latitude;
          data['longitude'] = pos.longitude;
        }
      }

      if (receiptFilePath != null && receiptFilePath.isNotEmpty) {
        final formData = FormData.fromMap({
          ...data.map((k, v) {
            if (v is bool) return MapEntry(k, v ? '1' : '0');
            return MapEntry(k, v);
          })..removeWhere((_, v) => v == null),
          'receipt': await MultipartFile.fromFile(receiptFilePath),
        });
        await _api.dio.post('/fuel-logs', data: formData);
      } else {
        await _api.dio.post('/fuel-logs', data: data);
      }
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<FuelLogEntry> uploadFuelReceipt(int fuelLogId, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'receipt': await MultipartFile.fromFile(filePath),
      });
      final res = await _api.dio.post<Map<String, dynamic>>(
        '/fuel-logs/$fuelLogId/receipt',
        data: formData,
      );
      return FuelLogEntry.fromJson(res.data ?? const {});
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }
}
