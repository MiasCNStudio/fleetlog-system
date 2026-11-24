import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/maintenance_fuel_models.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/repositories/fleet_repository.dart';
import '../../core/widgets/status_badge.dart';
import '../auth/auth_controller.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  List<VehicleMaintenanceEntry> _records = const [];
  List<Vehicle> _alerts = const [];
  List<Vehicle> _vehicles = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final vehicles = await context.read<FleetRepository>().fetchVehicleOptions();
      if (mounted) setState(() => _vehicles = vehicles);
    } catch (_) {}
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await context.read<FleetRepository>().fetchMaintenances();
      if (!mounted) return;
      setState(() {
        _records = res.records;
        _alerts = res.alerts;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreateModal([int? preselectedVehicleId]) async {
    if (_vehicles.isEmpty) await _init();
    if (!mounted) return;

    int? vehicleId = preselectedVehicleId ?? (_vehicles.isNotEmpty ? _vehicles.first.id : null);
    var status = 'programado';
    final titleCtrl = TextEditingController();
    final odomCtrl = TextEditingController();
    final intervalCtrl = TextEditingController(text: '5000');
    final alertCtrl = TextEditingController(text: '500');
    final workshopCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    void fillVehicleDefaults(int? vid) {
      final found = _vehicles.where((e) => e.id == vid).firstOrNull;
      if (found == null) return;
      final interval = int.tryParse(intervalCtrl.text) ?? 5000;
      odomCtrl.text = status == 'programado'
          ? '${found.currentOdometer + interval}'
          : '${found.currentOdometer}';
    }

    fillVehicleDefaults(vehicleId);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Mantenimiento por kilometraje',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: vehicleId,
                  decoration: const InputDecoration(labelText: 'Vehículo *'),
                  items: [
                    for (final v in _vehicles)
                      DropdownMenuItem(
                        value: v.id,
                        child: Text('${v.licensePlate} · ${v.currentOdometer} km'),
                      ),
                  ],
                  onChanged: (v) {
                    setDlg(() {
                      vehicleId = v;
                      fillVehicleDefaults(v);
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Servicio / descripción *',
                    hintText: 'Ej. Cambio de aceite y revisión frenos',
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'programado', label: Text('Programar')),
                    ButtonSegment(value: 'completado', label: Text('Ya realizado')),
                  ],
                  selected: {status},
                  onSelectionChanged: (s) {
                    setDlg(() {
                      status = s.first;
                      fillVehicleDefaults(vehicleId);
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: odomCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: status == 'programado' ? 'Km meta *' : 'Km realizado *',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: alertCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Alertar antes (km)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: workshopCtrl,
                        decoration: const InputDecoration(labelText: 'Taller'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: costCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Costo (\$)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () async {
                    if (vehicleId == null || titleCtrl.text.trim().isEmpty) return;
                    final km = int.tryParse(odomCtrl.text.trim());
                    try {
                      await context.read<FleetRepository>().createMaintenance({
                        'vehicle_id': vehicleId,
                        'title': titleCtrl.text.trim(),
                        'status': status,
                        if (status == 'programado') 'scheduled_odometer_km': km,
                        if (status == 'completado') 'completed_odometer_km': km,
                        'alert_before_km': int.tryParse(alertCtrl.text.trim()) ?? 500,
                        'next_interval_km': int.tryParse(intervalCtrl.text.trim()) ?? 5000,
                        if (workshopCtrl.text.trim().isNotEmpty) 'workshop': workshopCtrl.text.trim(),
                        if (double.tryParse(costCtrl.text.trim()) != null)
                          'cost_usd': double.parse(costCtrl.text.trim()),
                      });
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                  child: const Text('Guardar mantenimiento'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok == true) await _init();
  }

  Future<void> _completeItem(VehicleMaintenanceEntry m) async {
    final currentKm = m.vehicle?.currentOdometer ?? m.scheduledOdometerKm ?? 0;
    final interval = m.vehicle?.maintenanceIntervalKm ?? 5000;
    final kmCtrl = TextEditingController(text: '$currentKm');
    final nextCtrl = TextEditingController(text: '${currentKm + interval}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Completar mantenimiento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: kmCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Odómetro actual (km)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nextCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Próximo mantenimiento (km)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Completar')),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    try {
      await context.read<FleetRepository>().completeMaintenance(m.id, {
        'completed_odometer_km': int.tryParse(kmCtrl.text.trim()) ?? currentKm,
        'next_maintenance_odometer': int.tryParse(nextCtrl.text.trim()),
      });
      await _init();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.watch<AuthController>().user?.canManageFleet ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Mantenimiento preventivo')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openCreateModal(),
              icon: const Icon(Icons.build_outlined),
              label: const Text('Programar'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _init,
        child: _loading && _records.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _records.isEmpty
                ? Center(child: Text(_error!))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    children: [
                      if (_alerts.isNotEmpty) ...[
                        const Text(
                          'Alertas de kilometraje',
                          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        for (final v in _alerts)
                          Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            color: v.maintenanceStatus == 'vencido'
                                ? const Color(0xFFE11D48).withValues(alpha: 0.12)
                                : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      PlateChip(
                                        v.licensePlate,
                                        plateType: v.plateType,
                                        plateNumber: v.plateNumber,
                                      ),
                                      StatusBadge(
                                        kind: 'maintenanceStatus',
                                        value: v.maintenanceStatus,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    v.maintenanceStatus == 'vencido'
                                        ? '¡PASADA por ${(v.kmToMaintenance ?? 0).abs()} km! Requiere servicio urgente.'
                                        : 'Necesitará mantenimiento en ${v.kmToMaintenance ?? 0} km.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: v.maintenanceStatus == 'vencido'
                                          ? const Color(0xFFE11D48)
                                          : const Color(0xFFB45309),
                                    ),
                                  ),
                                  Text(
                                    'Odómetro: ${v.currentOdometer} km / Meta: ${v.nextMaintenanceOdometer ?? 0} km',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                      const Text(
                        'Historial y servicios',
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      if (_records.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'Sin registros de mantenimiento.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          ),
                        )
                      else
                        for (final m in _records)
                          Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Row(
                                children: [
                                  if (m.vehicle != null)
                                    PlateChip(
                                      m.vehicle!.licensePlate,
                                      plateType: m.vehicle!.plateType,
                                      plateNumber: m.vehicle!.plateNumber,
                                    ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      m.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '${m.scheduledOdometerKm != null ? 'Meta: ${m.scheduledOdometerKm} km · ' : ''}'
                                  '${m.completedOdometerKm != null ? 'Realizado: ${m.completedOdometerKm} km · ' : ''}'
                                  '${m.workshop ?? ''}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              trailing: m.status == 'programado' && canManage
                                  ? TextButton(
                                      onPressed: () => _completeItem(m),
                                      child: const Text('Completar'),
                                    )
                                  : StatusBadge(kind: 'maintenanceJobStatus', value: m.status),
                            ),
                          ),
                    ],
                  ),
      ),
    );
  }
}
