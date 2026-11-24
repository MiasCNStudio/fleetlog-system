import 'package:intl/intl.dart';

class DateFormatter {
  static String dateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return raw;
    return DateFormat('dd/MM/yy · HH:mm').format(parsed);
  }

  static String shortTime(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return raw;
    return DateFormat('HH:mm').format(parsed);
  }

  static String durationMinutes(int mins) {
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final rem = mins % 60;
    return '${h}h ${rem}m';
  }
}
