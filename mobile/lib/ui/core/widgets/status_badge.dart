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
          'incidents' => ('Incidencias', const Color(0xFFE11D48)),
          'users' => ('Usuarios', const Color(0xFF7C3AED)),
          'auth' => ('Acceso', const Color(0xFF64748B)),
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
  const PlateChip(this.plate, {super.key});
  final String plate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
}
