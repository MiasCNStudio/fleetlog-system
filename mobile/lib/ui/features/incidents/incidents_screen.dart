import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../data/models/incident_entry.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/repositories/fleet_repository.dart';
import '../../core/date_formatter.dart';
import '../../core/widgets/status_badge.dart';
import '../auth/auth_controller.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  List<IncidentEntry> _items = const [];
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
      final res = await context.read<FleetRepository>().fetchIncidents();
      if (!mounted) return;
      setState(() => _items = res.items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openReportModal() async {
    if (_vehicles.isEmpty) await _init();
    if (!mounted) return;

    int? vehicleId = _vehicles.isNotEmpty ? _vehicles.first.id : null;
    var severity = 'media';
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? photoPath;
    final picker = ImagePicker();

    final created = await showModalBottomSheet<bool>(
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
                  'Reportar incidencia',
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
                        child: Text('${v.licensePlate} · ${v.brand}'),
                      ),
                  ],
                  onChanged: (v) => setDlg(() => vehicleId = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título / falla breve *',
                    hintText: 'Ej. Falla de freno, llanta ponchada…',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: severity,
                  decoration: const InputDecoration(labelText: 'Gravedad'),
                  items: const [
                    DropdownMenuItem(value: 'baja', child: Text('Baja')),
                    DropdownMenuItem(value: 'media', child: Text('Media')),
                    DropdownMenuItem(value: 'alta', child: Text('Alta')),
                    DropdownMenuItem(value: 'critica', child: Text('Crítica (envía a mantenimiento)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDlg(() => severity = v);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descripción detallada *'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final img = await picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 80,
                          );
                          if (img != null) setDlg(() => photoPath = img.path);
                        },
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Cámara'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final img = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                          );
                          if (img != null) setDlg(() => photoPath = img.path);
                        },
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text('Galería'),
                      ),
                    ),
                  ],
                ),
                if (photoPath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Foto adjunta: ${photoPath!.split('/').last}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF059669)),
                    ),
                  ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () async {
                    if (vehicleId == null ||
                        titleCtrl.text.trim().isEmpty ||
                        descCtrl.text.trim().isEmpty) {
                      return;
                    }
                    try {
                      await context.read<FleetRepository>().createIncident(
                        vehicleId: vehicleId!,
                        title: titleCtrl.text,
                        description: descCtrl.text,
                        severity: severity,
                        photoPath: photoPath,
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
                  child: const Text('Enviar reporte'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (created == true) {
      await _load();
    }
  }

  Future<void> _updateStatus(IncidentEntry inc, String status) async {
    try {
      await context.read<FleetRepository>().updateIncidentStatus(inc.id, status);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.watch<AuthController>().user?.canManageFleet ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Incidencias')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openReportModal,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Reportar'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _items.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('Reintentar')),
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(32),
                        children: const [
                          Text(
                            'Sin incidencias reportadas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                        itemCount: _items.length,
                        itemBuilder: (_, idx) {
                          final inc = _items[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      PlateChip(inc.vehicle?.licensePlate ?? '—'),
                                      Row(
                                        children: [
                                          StatusBadge(kind: 'incidentSeverity', value: inc.severity),
                                          const SizedBox(width: 6),
                                          StatusBadge(kind: 'incidentStatus', value: inc.status),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    inc.title,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                  if (inc.description != null && inc.description!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(inc.description!, style: const TextStyle(fontSize: 13)),
                                    ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Reportó: ${inc.reporter?.name ?? '—'} · ${DateFormatter.dateTime(inc.reportedAt)}',
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  ),
                                  if (canManage) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        if (inc.status != 'en_revision')
                                          OutlinedButton(
                                            onPressed: () => _updateStatus(inc, 'en_revision'),
                                            child: const Text('En revisión'),
                                          ),
                                        if (inc.status != 'resuelta')
                                          FilledButton(
                                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                                            onPressed: () => _updateStatus(inc, 'resuelta'),
                                            child: const Text('Marcar resuelta'),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
