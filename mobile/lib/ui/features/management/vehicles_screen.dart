import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/vehicle.dart';
import '../../../data/repositories/fleet_repository.dart';
import '../../core/widgets/status_badge.dart';
import '../auth/auth_controller.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  static const _svTypes = [
    ('P', 'P · Particular'),
    ('CD', 'CD · Cuerpo Diplomático'),
    ('MI', 'MI · Misión Internacional'),
    ('N', 'N · Nacional'),
    ('CC', 'CC · Cuerpo Consular'),
    ('A', 'A · Alquiler'),
    ('C', 'C · Comercial'),
    ('M', 'M · Motocicleta'),
    ('AB', 'AB · Autobús'),
    ('MB', 'MB · Microbús'),
    ('CUSTOM', 'Otra / Personalizada'),
  ];

  List<Vehicle> _items = const [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await context.read<FleetRepository>().fetchVehicles(
        search: _searchCtrl.text,
      );
      if (!mounted) return;
      setState(() => _items = res.items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor([Vehicle? existing]) async {
    var plateType = existing?.plateType ?? 'P';
    if (existing != null && (existing.plateType == null || existing.plateType!.isEmpty)) {
      plateType = 'CUSTOM';
    }
    final plateNumCtrl = TextEditingController(text: existing?.plateNumber ?? '');
    final plateCtrl = TextEditingController(text: existing?.licensePlate ?? '');
    final brandCtrl = TextEditingController(text: existing?.brand ?? '');
    final modelCtrl = TextEditingController(text: existing?.model ?? '');
    final colorCtrl = TextEditingController(text: existing?.color ?? 'Blanco');
    final odomCtrl = TextEditingController(text: '${existing?.currentOdometer ?? 0}');
    final nextMaintCtrl = TextEditingController(
      text: existing?.nextMaintenanceOdometer != null
          ? '${existing!.nextMaintenanceOdometer}'
          : '',
    );
    final intervalCtrl = TextEditingController(
      text: '${existing?.maintenanceIntervalKm ?? 5000}',
    );
    var status = existing?.status ?? 'disponible';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final previewRaw = plateType == 'CUSTOM'
              ? plateCtrl.text.trim().toUpperCase()
              : '$plateType${plateNumCtrl.text.trim().toUpperCase()}';
          return Padding(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existing == null ? 'Nuevo vehículo' : 'Editar ${existing.licensePlate}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      if (previewRaw.isNotEmpty)
                        PlateChip(
                          previewRaw,
                          plateType: plateType == 'CUSTOM' ? null : plateType,
                          plateNumber: plateType == 'CUSTOM' ? null : plateNumCtrl.text,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: plateType,
                    decoration: const InputDecoration(labelText: 'Tipo de placa (El Salvador)'),
                    items: _svTypes
                        .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDlg(() => plateType = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  if (plateType != 'CUSTOM')
                    TextField(
                      controller: plateNumCtrl,
                      onChanged: (_) => setDlg(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Número / letras de placa *',
                        hintText: 'Ej. 123456, 745ABC o 1234',
                      ),
                    )
                  else
                    TextField(
                      controller: plateCtrl,
                      onChanged: (_) => setDlg(() {}),
                      decoration: const InputDecoration(labelText: 'Placa completa *'),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: brandCtrl,
                          decoration: const InputDecoration(labelText: 'Marca *'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: modelCtrl,
                          decoration: const InputDecoration(labelText: 'Modelo *'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: colorCtrl,
                          decoration: const InputDecoration(labelText: 'Color *'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: odomCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Odómetro (km)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nextMaintCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Próx. mant. (km)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: intervalCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Intervalo (km)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: const [
                      DropdownMenuItem(value: 'disponible', child: Text('Disponible')),
                      DropdownMenuItem(value: 'en_ruta', child: Text('En ruta')),
                      DropdownMenuItem(value: 'mantenimiento', child: Text('Mantenimiento')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDlg(() => status = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () async {
                      final isSv = plateType != 'CUSTOM';
                      final cleanNum = plateNumCtrl.text.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
                      final fullPlate = isSv ? '$plateType$cleanNum' : plateCtrl.text.trim().toUpperCase();
                      if (fullPlate.isEmpty) return;

                      try {
                        await context.read<FleetRepository>().saveVehicle(
                          id: existing?.id,
                          licensePlate: fullPlate,
                          plateType: isSv ? plateType : null,
                          plateNumber: isSv ? cleanNum : null,
                          brand: brandCtrl.text,
                          model: modelCtrl.text,
                          color: colorCtrl.text,
                          status: status,
                          currentOdometer: int.tryParse(odomCtrl.text.trim()) ?? 0,
                          nextMaintenanceOdometer: int.tryParse(nextMaintCtrl.text.trim()),
                          maintenanceIntervalKm: int.tryParse(intervalCtrl.text.trim()) ?? 5000,
                          maintenanceAlertBeforeKm: 500,
                        );
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      }
                    },
                    child: const Text('Guardar vehículo'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (saved == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.watch<AuthController>().user?.canManageFleet ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Vehículos')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Unidad'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Buscar por placa, marca o modelo…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading && _items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _items.isEmpty
                      ? Center(child: Text(_error!))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                          itemCount: _items.length,
                          itemBuilder: (_, idx) {
                            final v = _items[idx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                onTap: canManage ? () => _openEditor(v) : null,
                                leading: PlateChip(
                                  v.licensePlate,
                                  plateType: v.plateType,
                                  plateNumber: v.plateNumber,
                                ),
                                title: Text(
                                  '${v.brand} ${v.model}',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${v.color} · ${v.currentOdometer} km'),
                                    if (v.kmToMaintenance != null)
                                      Text(
                                        v.kmToMaintenance! <= 0
                                            ? '¡Mant. pasado por ${v.kmToMaintenance!.abs()} km!'
                                            : 'Próx. mant. en ${v.kmToMaintenance} km',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: v.maintenanceStatus == 'vencido'
                                              ? const Color(0xFFE11D48)
                                              : v.maintenanceStatus == 'pronto'
                                                  ? const Color(0xFFD97706)
                                                  : const Color(0xFF64748B),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    StatusBadge(kind: 'vehicleStatus', value: v.status),
                                    if (v.hasMaintenanceAlert) ...[
                                      const SizedBox(height: 4),
                                      StatusBadge(
                                        kind: 'maintenanceStatus',
                                        value: v.maintenanceStatus,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
