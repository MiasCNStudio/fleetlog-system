import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdentity {
  const DeviceIdentity({
    required this.uuid,
    required this.name,
    required this.platform,
  });

  final String uuid;
  final String name;
  final String platform;
}

class DeviceIdentityService {
  static const _uuidKey = 'fleetlog_device_uuid';
  static const _nameKey = 'fleetlog_device_name';
  static const _platformKey = 'fleetlog_device_platform';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  DeviceIdentity? _cached;

  Future<DeviceIdentity> getIdentity() async {
    if (_cached != null) return _cached!;

    final prefs = await SharedPreferences.getInstance();
    var uuid = await _secure.read(key: _uuidKey) ?? prefs.getString(_uuidKey);

    if (uuid == null || uuid.trim().isEmpty) {
      final raw = const Uuid().v4();
      final prefix = !kIsWeb && Platform.isAndroid ? 'android' : 'mobile';
      uuid = '$prefix-$raw';
      await _secure.write(key: _uuidKey, value: uuid);
    }
    await prefs.setString(_uuidKey, uuid);

    var name = 'Dispositivo Android';
    var platform = 'android';

    try {
      final info = DeviceInfoPlugin();
      if (!kIsWeb && Platform.isAndroid) {
        final android = await info.androidInfo;
        final brand = android.brand.trim();
        final model = android.model.trim();
        name = model.toLowerCase().startsWith(brand.toLowerCase())
            ? model
            : '$brand $model'.trim();
        platform = 'android-${android.version.release}';
      } else if (!kIsWeb && Platform.isIOS) {
        final ios = await info.iosInfo;
        name = ios.utsname.machine;
        platform = 'ios';
      }
    } catch (_) {
      /* fallback seguro */
    }

    await prefs.setString(_nameKey, name);
    await prefs.setString(_platformKey, platform);

    _cached = DeviceIdentity(uuid: uuid, name: name, platform: platform);
    return _cached!;
  }
}
