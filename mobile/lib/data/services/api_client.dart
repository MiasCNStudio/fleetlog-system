import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'device_identity_service.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    required this._deviceIdentityService,
    this.onUnauthorized,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: defaultBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 25),
        sendTimeout: const Duration(seconds: 25),
        headers: const {
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          final identity = await _deviceIdentityService.getIdentity();
          options.headers['X-Device-UUID'] = identity.uuid;
          options.headers['X-Device-Name'] = identity.name;
          options.headers['X-Device-Platform'] = identity.platform;
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/login')) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  static const String defaultBaseUrl = 'https://fleetlog.miascn.org/api';
  static const String _tokenKey = 'fleetlog_api_token';
  static const String _baseUrlKey = 'fleetlog_api_base_url';

  final DeviceIdentityService _deviceIdentityService;
  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  final void Function()? onUnauthorized;

  late final Dio _dio;
  String? _cachedToken;

  Dio get dio => _dio;

  Future<void> initBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_baseUrlKey);
    if (saved != null && saved.trim().isNotEmpty) {
      _dio.options.baseUrl = _normalizeBaseUrl(saved);
    }
  }

  String get currentBaseUrl => _dio.options.baseUrl;

  Future<void> setBaseUrl(String rawUrl) async {
    final normalized = _normalizeBaseUrl(rawUrl);
    _dio.options.baseUrl = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, normalized);
  }

  String _normalizeBaseUrl(String raw) {
    var url = raw.trim().replaceAll(RegExp(r'/+$'), '');
    if (!url.endsWith('/api')) {
      url = '$url/api';
    }
    return url;
  }

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _secure.read(key: _tokenKey);
    if (_cachedToken != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _cachedToken!);
    }
    return _cachedToken;
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _secure.write(key: _tokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    await _secure.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static ApiException parseError(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final errors = data['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final firstList = errors.values.first;
          if (firstList is List && firstList.isNotEmpty) {
            return ApiException(firstList.first.toString(), statusCode: status);
          }
        }
        final msg = data['message']?.toString();
        if (msg != null && msg.isNotEmpty) {
          return ApiException(msg, statusCode: status);
        }
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return ApiException(
          'Sin conexión con el servidor. Verifica tus datos o Wi-Fi.',
          statusCode: status,
        );
      }
      return ApiException(
        'Error de comunicación (${status ?? 'red'}).',
        statusCode: status,
      );
    }
    return ApiException(error.toString());
  }
}
