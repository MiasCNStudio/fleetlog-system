import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.value,
    this.kind = 'generic',
  });

  final String value;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve(value, kind);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  static (String, Color) _resolve(String val, String kind) {
    switch (kind) {
      case 'vehicleStatus':
        return switch (val) {
          'disponible' => ('Disponible', const Color(0xFF059669)),
          'en_ruta' => ('En ruta', const Color(0xFFD97706)),
          'mantenimiento' => ('Mantenimiento', const Color(0xFFE11D48)),
          _ => (val, const Color(0xFF64748B)),
        };
      case 'assignmentStatus':
        return switch (val) {
          'pendiente' => ('Pendiente', const Color(0xFFD97706)),
          'en_curso' => ('En curso', const Color(0xFF465FFF)),
          'completada' => ('Completada', const Color(0xFF059669)),
          'cancelada' => ('Cancelada', const Color(0xFF64748B)),
          _ => (val, const Color(0xFF64748B)),
        };
      case 'bitacoraType':
        return switch (val) {
          'salida' => ('Salida', const Color(0xFFD97706)),
          'regreso' => ('Regreso', const Color(0xFF059669)),
          _ => (val, const Color(0xFF64748B)),
        };
      case 'bitacoraCategory':
        return switch (val) {
          'asignacion' => ('Asignación', const Color(0xFF465FFF)),
          'personal' => ('Personal', const Color(0xFF7C3AED)),
          'imprevisto' => ('Imprevisto', const Color(0xFFE11D48)),
          _ => (val, const Color(0xFF64748B)),
        };
      case 'trackingStatus':
        return switch (val) {
          'activa' => ('En misión', const Color(0xFF059669)),
          'finalizada' => ('Finalizada', const Color(0xFF465FFF)),
          'interrumpida' => ('Interrumpida', const Color(0xFFE11D48)),
          _ => (val, const Color(0xFF64748B)),
        };
      case 'incidentStatus':
        return switch (val) {
          'abierta' => ('Abierta', const Color(0xFFE11D48)),
          'en_revision' => ('En revisión', const Color(0xFFD97706)),
          'resuelta' => ('Resuelta', const Color(0xFF059669)),
          _ => (val, const Color(0xFF64748B)),
        };
      case 'incidentSeverity':
        return switch (val) {
          'baja' => ('Baja', const Color(0xFF64748B)),
          'media' => ('Media', const Color(0xFF0284C7)),
          'alta' => ('Alta', const Color(0xFFD97706)),
          'critica' => ('Crítica', const Color(0xFFE11D48)),
          _ => (val, const Color(0xFF64748B)),
        };
      case 'logModule':
        return switch (val) {
          'assignments' => ('Asignaciones', const Color(0xFF465FFF)),
          'bitacoras' => ('Bitácora', const Color(0xFFD97706)),
          'tracking' => ('Rastreo GPS', const Color(0xFF0D9488)),
          'vehicles' => ('Vehículos', const Color(0xFF0284C7)),
          'maintenance' => ('Mantenimiento', const Color(0xFFEA580C)),
          'fuel' => ('Combustible', const Color(0xFF059669)),
          'incidents' => ('Incidencias', const Color(0xFFE11D48)),
          'users' => ('Usuarios', const Color(0xFF7C3AED)),
          'auth' => ('Acceso', const Color(0xFF64748B)),
          _ => (val, const Color(0xFF64748B)),
        };
      case 'maintenanceStatus':
        return switch (val) {
          'al_dia' => ('Al día', const Color(0xFF059669)),
          'pronto' => ('Mant. pronto', const Color(0xFFD97706)),
          'vencido' => ('¡MANT. VENCIDO!', const Color(0xFFE11D48)),
          _ => ('Sin meta km', const Color(0xFF64748B)),
        };
      case 'maintenanceJobStatus':
        return switch (val) {
          'programado' => ('Programado', const Color(0xFFD97706)),
          'completado' => ('Completado', const Color(0xFF059669)),
          'cancelado' => ('Cancelado', const Color(0xFF64748B)),
          _ => (val, const Color(0xFF64748B)),
        };
      case 'logAction':
        return switch (val) {
          'sos_alert' => ('Alerta SOS', const Color(0xFFE11D48)),
          'device_mismatch' => ('Otro celular', const Color(0xFFE11D48)),
          'emergency_reassigned' => ('Emergencia', const Color(0xFFE11D48)),
          'personal_trip' => ('Personal', const Color(0xFF7C3AED)),
          'unplanned_trip' => ('Imprevisto', const Color(0xFFD97706)),
          'session_started' => ('Inicio GPS', const Color(0xFF0D9488)),
          'session_finished' => ('Fin GPS', const Color(0xFF465FFF)),
          'created' => ('Creación', const Color(0xFF059669)),
          'updated' => ('Edición', const Color(0xFF0284C7)),
          'deleted' => ('Eliminación', const Color(0xFFE11D48)),
          'login' => ('Ingreso', const Color(0xFF64748B)),
          'logout' => ('Salida', const Color(0xFF64748B)),
          _ => (val, const Color(0xFF64748B)),
        };
      default:
        return (val, const Color(0xFF64748B));
    }
  }
}

class PlateChip extends StatelessWidget {
  const PlateChip(
    this.plate, {
    super.key,
    this.plateType,
    this.plateNumber,
  });

  final String plate;
  final String? plateType;
  final String? plateNumber;

  static const _prefixes = ['CD', 'MI', 'CC', 'AB', 'MB', 'P', 'N', 'A', 'C', 'M'];

  ({bool isSv, String type, String left, String right}) _parse() {
    var type = (plateType ?? '').trim().toUpperCase();
    var num = (plateNumber ?? '').trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    if (type.isEmpty || num.isEmpty) {
      final raw = plate.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      for (final p in _prefixes) {
        if (raw.startsWith(p)) {
          final rest = raw.substring(p.length);
          if (rest.length >= 3 && RegExp(r'\d').hasMatch(rest)) {
            type = p;
            num = rest;
            break;
          }
        }
      }
    }

    if (type.isEmpty || num.isEmpty) {
      return (isSv: false, type: '', left: '', right: '');
    }
    final right = num.length > 3 ? num.substring(num.length - 3) : num;
    final left = num.length > 3 ? num.substring(0, num.length - 3) : '';
    return (isSv: true, type: type, left: left, right: right);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parsed = _parse();

    if (!parsed.isSv) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          plate,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      );
    }

    final prefixColor = switch (parsed.type) {
      'CD' || 'CC' => const Color(0xFF0284C7),
      'MI' => const Color(0xFF4F46E5),
      'N' => const Color(0xFF1E3A8A),
      _ => const Color(0xFF0F47AF),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: prefixColor.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: prefixColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              parsed.type,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 4),
          if (parsed.left.isNotEmpty) ...[
            Text(
              parsed.left,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 3),
          ],
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: const Color(0xFF0F47AF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
            ),
            child: const Icon(Icons.change_history, size: 8, color: Color(0xFFFACC15)),
          ),
          const SizedBox(width: 3),
          Text(
            parsed.right,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
