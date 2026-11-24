import 'package:url_launcher/url_launcher.dart';

class ExternalMapsLauncher {
  static Future<bool> openUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> openGoogleMaps({
    double? latitude,
    double? longitude,
    String? destination,
    String? address,
  }) async {
    final String query;
    if (latitude != null && longitude != null) {
      query = '$latitude,$longitude';
    } else {
      query = [destination, address]
          .where((e) => e != null && e.trim().isNotEmpty)
          .join(', ');
    }
    if (query.trim().isEmpty) return false;
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> openWaze({
    double? latitude,
    double? longitude,
    String? destination,
    String? address,
  }) async {
    final Uri uri;
    if (latitude != null && longitude != null) {
      uri = Uri.https('waze.com', '/ul', {
        'll': '$latitude,$longitude',
        'navigate': 'yes',
      });
    } else {
      final query = [destination, address]
          .where((e) => e != null && e.trim().isNotEmpty)
          .join(', ');
      if (query.trim().isEmpty) return false;
      uri = Uri.https('waze.com', '/ul', {
        'q': query,
        'navigate': 'yes',
      });
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
