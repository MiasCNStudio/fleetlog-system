import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/models/assignment.dart';
import '../../../data/models/dashboard_data.dart';
import '../../../data/repositories/fleet_repository.dart';
import '../../../data/repositories/tracking_repository.dart';
import '../../../data/services/background_tracking_service.dart';
import '../../../data/services/external_maps_launcher.dart';
import '../../core/date_formatter.dart';
import '../../core/widgets/status_badge.dart';
import '../auth/auth_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthController>();
      final repo = context.read<FleetRepository>();
      final res = await repo.fetchDashboard();
      await auth.syncActiveMissionTracking();
      if (!mounted) return;
      setState(() => _data = res);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startAssignedTrip(Assignment assignment) async {
    final odomCtrl = TextEditingController(
      text: assignment.vehicle?.currentOdometer.toString() ?? '',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Iniciar misión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unidad: ${assignment.vehicle?.licensePlate ?? ''}\nDestino: ${assignment.destination}',
              style: const TextStyle(fontSize: 13.5),
            ),
            if (assignment.officialInstruction != null &&
                assignment.officialInstruction!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Instrucción oficial: ${assignment.officialInstruction}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: odomCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Odómetro actual (km)',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Al iniciar, este celular activará el rastreo GPS de seguridad hasta que registres el regreso.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Iniciar viaje'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final repo = context.read<FleetRepository>();
    await BackgroundTrackingService.requestLocationPermissions();
    if (!mounted) return;

    try {
      await repo.createBitacora({
        'assignment_id': assignment.id,
        'vehicle_id': assignment.vehicleId,
        'odometer_km': int.tryParse(odomCtrl.text.trim()),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Misión iniciada. Rastreo GPS activo en este celular.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _registerReturn(int vehicleId, int? lastOdometer) async {
    final odomCtrl = TextEditingController(
      text: lastOdometer != null ? '$lastOdometer' : '',
    );
    final notesCtrl = TextEditingController();
    var fuel = '3/4';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Registrar regreso de misión'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: odomCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Odómetro de llegada (km)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: fuel,
                  decoration: const InputDecoration(labelText: 'Nivel de combustible'),
                  items: const ['lleno', '3/4', '1/2', '1/4', 'reserva']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDlgState(() => fuel = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Observaciones / novedades'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Finalizar misión'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;
    try {
      await context.read<FleetRepository>().createBitacora({
        'vehicle_id': vehicleId,
        'odometer_km': int.tryParse(odomCtrl.text.trim()),
        'fuel_level': fuel,
        if (notesCtrl.text.trim().isNotEmpty) 'notes': notesCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Regreso registrado y resumen final generado.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _sendSosAlert(int sessionId) async {
    final msgCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enviar Alerta SOS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Se enviará tu ubicación GPS exacta y alerta crítica al administrador y jefe de motoristas.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              decoration: const InputDecoration(
                labelText: 'Mensaje breve (opcional)',
                hintText: 'Ej. Falla en zona desolada / emergencia',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE11D48)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ENVIAR SOS AHORA'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    try {
      await context.read<TrackingRepository>().sendSos(
        sessionId: sessionId,
        message: msgCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE11D48),
          content: Text('Alerta SOS enviada con tu ubicación GPS exacta.'),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(user.isDriver ? 'Mi panel de conductor' : 'Dashboard Fleetlog'),
        actions: [
          IconButton(
            tooltip: auth.darkMode ? 'Modo claro' : 'Modo oscuro',
            onPressed: auth.toggleDarkMode,
            icon: Icon(auth.darkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: auth.logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _data == null
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _data == null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('Reintentar')),
                    ],
                  )
                : user.isDriver
                    ? _buildDriverDashboard(auth)
                    : _buildManagerDashboard(auth),
      ),
    );
  }

  Widget _buildDriverDashboard(AuthController auth) {
    final data = _data!;
    final activeTrip = data.myActiveTrip;
    final activeSession = auth.myActiveSession;
    final pendingMine = data.myAssignments.where((a) => a.isPending).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (auth.trackingWarning != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
            ),
            child: Text(
              auth.trackingWarning!,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
        if (activeTrip != null || activeSession != null) ...[
          _activeMissionBanner(auth, activeTrip),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                'Unidades libres',
                '${data.summary.availableVehicles}',
                'De ${data.summary.totalVehicles}',
                const Color(0xFF059669),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                'Viajes pendientes',
                '${pendingMine.length}',
                'Asignados a ti',
                const Color(0xFF465FFF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Mis próximos viajes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (pendingMine.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Text(
                    'No tienes asignaciones pendientes.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Si debes cubrir el viaje de otro compañero, entra a Asignaciones y usa Emergencia.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => context.go('/asignaciones'),
                    child: const Text('Ver todas las asignaciones'),
                  ),
                ],
              ),
            ),
          )
        else
          for (final a in pendingMine)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PlateChip(a.vehicle?.licensePlate ?? '—'),
                        Text(
                          '${a.scheduledDate}${a.scheduledTime != null ? ' · ${a.scheduledTime}' : ''}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.destination,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    if (a.officialInstruction != null && a.officialInstruction!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Instrucción oficial: ${a.officialInstruction}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _startAssignedTrip(a),
                            icon: const Icon(Icons.play_arrow_rounded, size: 20),
                            label: const Text('Iniciar viaje'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          tooltip: 'Google Maps',
                          onPressed: () => ExternalMapsLauncher.openGoogleMaps(
                            latitude: a.latitude,
                            longitude: a.longitude,
                            destination: a.destination,
                            address: a.destinationAddress,
                          ),
                          icon: const Icon(Icons.map_outlined),
                        ),
                        IconButton.outlined(
                          tooltip: 'Waze',
                          onPressed: () => ExternalMapsLauncher.openWaze(
                            latitude: a.latitude,
                            longitude: a.longitude,
                            destination: a.destination,
                            address: a.destinationAddress,
                          ),
                          icon: const Icon(Icons.navigation_outlined),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 14),
        const Text(
          'Acciones rápidas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/bitacora'),
                icon: const Icon(Icons.person_pin_circle_outlined, size: 18),
                label: const Text('Salida personal'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/incidencias'),
                icon: const Icon(Icons.report_problem_outlined, size: 18),
                label: const Text('Incidencia'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _activeMissionBanner(AuthController auth, ActiveTripSummary? activeTrip) {
    final session = auth.myActiveSession;
    final plate = session?.vehicle?.licensePlate ?? activeTrip?.licensePlate ?? 'Unidad';
    final dest = session?.salidaBitacora?.destination ?? activeTrip?.destination ?? 'En ruta';
    final lat = session?.salidaBitacora?.latitude ?? activeTrip?.latitude;
    final lng = session?.salidaBitacora?.longitude ?? activeTrip?.longitude;
    final addr = session?.salidaBitacora?.destinationAddress ?? activeTrip?.destinationAddress;
    final vehicleId = session?.vehicleId ?? activeTrip?.vehicleId;
    final odom = activeTrip?.odometerKm ?? session?.vehicle?.currentOdometer;

    return Card(
      color: const Color(0xFF131C31),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.gps_fixed, size: 14, color: Color(0xFF34D399)),
                      SizedBox(width: 6),
                      Text(
                        'MISIÓN ACTIVA · GPS EN VIVO',
                        style: TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (session != null)
                  Text(
                    '${auth.liveDistanceKm.toStringAsFixed(1)} km · ${auth.livePointsCount} pts',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$plate · $dest',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (session != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Celular vinculado: ${session.deviceName}${auth.pendingOfflinePoints > 0 ? ' (${auth.pendingOfflinePoints} pts pendientes de red)' : ''}',
                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    onPressed: () => ExternalMapsLauncher.openGoogleMaps(
                      latitude: lat,
                      longitude: lng,
                      destination: dest,
                      address: addr,
                    ),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Google Maps'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    onPressed: () => ExternalMapsLauncher.openWaze(
                      latitude: lat,
                      longitude: lng,
                      destination: dest,
                      address: addr,
                    ),
                    icon: const Icon(Icons.navigation_outlined, size: 18),
                    label: const Text('Waze'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (vehicleId != null)
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                      ),
                      onPressed: () => _registerReturn(vehicleId, odom),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Registrar regreso'),
                    ),
                  ),
                if (session != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                      ),
                      onPressed: () => _sendSosAlert(session.id),
                      icon: const Icon(Icons.sos, size: 18),
                      label: const Text('SOS'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagerDashboard(AuthController auth) {
    final data = _data!;
    final s = data.summary;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.9,
          children: [
            _kpiCard('Viajes activos', '${s.activeTrips}', 'Flota total: ${s.totalVehicles}', const Color(0xFFD97706)),
            _kpiCard('Disponibles', '${s.availableVehicles}', 'Listas para salir', const Color(0xFF059669)),
            _kpiCard('Pendientes hoy', '${s.pendingAssignments}', 'Emergencias: ${s.emergencyReassignmentsToday}', const Color(0xFF465FFF)),
            _kpiCard('Incidencias', '${s.openIncidents}', 'Mant.: ${s.maintenanceVehicles}', const Color(0xFFE11D48)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => context.go('/rastreo'),
                icon: const Icon(Icons.gps_fixed, size: 18),
                label: const Text('Rastreo en vivo'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/asignaciones'),
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: const Text('Asignaciones'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Unidades en ruta ahora',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (data.activeTrips.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Todas las unidades están en base.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          )
        else
          for (final t in data.activeTrips)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: PlateChip(t.licensePlate),
                title: Text(t.driverName ?? 'Conductor', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${t.destination ?? 'En ruta'} · ${DateFormatter.dateTime(t.recordedAt)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.gps_fixed, color: Color(0xFF465FFF)),
                  onPressed: () => context.go('/rastreo'),
                ),
              ),
            ),
      ],
    );
  }

  Widget _kpiCard(String label, String value, String sub, Color accent) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}
