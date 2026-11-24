import '../models/app_user.dart';
import '../services/api_client.dart';
import '../services/background_tracking_service.dart';
import '../services/device_identity_service.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required DeviceIdentityService deviceIdentityService,
  }) : _api = apiClient,
       _device = deviceIdentityService;

  final ApiClient _api;
  final DeviceIdentityService _device;

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final identity = await _device.getIdentity();
      final res = await _api.dio.post<Map<String, dynamic>>(
        '/login',
        data: {
          'email': email.trim(),
          'password': password,
          'device_name': identity.name,
        },
      );
      final data = res.data ?? {};
      final token = (data['token'] ?? '').toString();
      if (token.isEmpty) {
        throw ApiException('El servidor no devolvió un token válido.');
      }
      await _api.saveToken(token);
      return AppUser.fromJson(data['user'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<AppUser> fetchMe() async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>('/user');
      return AppUser.fromJson(res.data ?? const {});
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<bool> hasStoredToken() async {
    final token = await _api.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout({bool stopTracking = false}) async {
    try {
      await _api.dio.post('/logout');
    } catch (_) {
      /* ignorar errores de red al cerrar sesión */
    } finally {
      if (stopTracking) {
        await BackgroundTrackingService.stopMission();
      }
      await _api.clearToken();
    }
  }
}
