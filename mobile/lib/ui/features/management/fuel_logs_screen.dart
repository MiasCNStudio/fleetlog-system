import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/maintenance_fuel_models.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/repositories/fleet_repository.dart';
import '../../../data/services/external_maps_launcher.dart';
import '../../core/date_formatter.dart';
import '../../core/widgets/status_badge.dart';

class FuelLogsScreen extends StatefulWidget {
  const FuelLogsScreen({super.key});

  @override
  State<FuelLogsScreen> createState() => _FuelLogsScreenState();
}

class _FuelLogsScreenState extends State<FuelLogsScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  List<FuelLogEntry> _items = const [];
  List<Vehicle> _vehicles = const [];
  FuelSummaryReport? _summary;
  String _summaryRange = 'week';
  bool _loading = true;
  int? _uploadingId;
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
      final repo = context.read<FleetRepository>();
      final results = await Future.wait([
        repo.fetchFuelLogs(),
        repo.fetchFuelSummary(range: _summaryRange),
      ]);
      if (!mounted) return;
      final paged = results[0] as dynamic;
      final sum = results[1] as FuelSummaryReport;
      setState(() {
        _items = paged.items as List<FuelLogEntry>;
        _summary = sum;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _pickReceiptPath() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const ListTile(
            title: Text(
              'Adjuntar ticket o factura electrónica',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('Puedes tomar fotografía o elegir imagen/PDF desde tu correo o archivos.'),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Tomar fotografía del ticket'),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Elegir foto de la galería'),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Elegir PDF o documento del teléfono'),
            onTap: () => Navigator.pop(ctx, 'file'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );

    if (choice == null) return null;
    if (choice == 'camera') {
      final img = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      return img?.path;
    }
    if (choice == 'gallery') {
      final img = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      return img?.path;
    }
    final res = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    return res.firstOrNull?.path;
  }

  Future<void> _attachReceiptToExisting(FuelLogEntry entry) async {
    final path = await _pickReceiptPath();
    if (path == null || !mounted) return;

    setState(() => _uploadingId = entry.id);
    try {
      await context.read<FleetRepository>().uploadFuelReceipt(entry.id, path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Factura / foto adjuntada correctamente.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _uploadingId = null);
    }
  }

  Future<void> _openReceiptUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openCreateModal() async {
    if (_vehicles.isEmpty) await _init();
    if (!mounted) return;

    int? vehicleId = _vehicles.isNotEmpty ? _vehicles.first.id : null;
    var fuelType = 'regular';
    var captureGps = true;
    String? receiptPath;
    final odomCtrl = TextEditingController(
      text: _vehicles.isNotEmpty ? '${_vehicles.first.currentOdometer}' : '',
    );
    final galCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final stationCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
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
                  'Registrar carga de combustible',
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
                    final found = _vehicles.where((e) => e.id == v).firstOrNull;
                    setDlg(() {
                      vehicleId = v;
                      if (found != null) odomCtrl.text = '${found.currentOdometer}';
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
                        decoration: const InputDecoration(labelText: 'Odómetro (km) *'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: galCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Galones *'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: fuelType,
                        decoration: const InputDecoration(labelText: 'Combustible'),
                        items: const [
                          DropdownMenuItem(value: 'regular', child: Text('Regular')),
                          DropdownMenuItem(value: 'especial', child: Text('Especial')),
                          DropdownMenuItem(value: 'diesel', child: Text('Diésel')),
                        ],
                        onChanged: (v) {
                          if (v != null) setDlg(() => fuelType = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: costCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Costo (\$ USD)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: stationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Gasolinera (opcional si activas GPS)',
                    hintText: 'Ej. Puma, Texaco, Uno',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: captureGps,
                  title: const Text(
                    'Detectar gasolinera por GPS del teléfono',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Guarda ubicación exacta en Google Maps.',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  onChanged: (v) => setDlg(() => captureGps = v),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await _pickReceiptPath();
                    if (picked != null) {
                      setDlg(() => receiptPath = picked);
                    }
                  },
                  icon: Icon(
                    receiptPath != null ? Icons.check_circle_outline : Icons.attach_file,
                    size: 18,
                  ),
                  label: Text(
                    receiptPath != null
                        ? 'Adjunto: ${receiptPath!.split(Platform.pathSeparator).last}'
                        : 'Tomar foto / adjuntar factura (opcional)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () async {
                    final gallons = double.tryParse(galCtrl.text.trim());
                    final odom = int.tryParse(odomCtrl.text.trim());
                    if (vehicleId == null || gallons == null || gallons <= 0 || odom == null) {
                      return;
                    }
                    try {
                      await context.read<FleetRepository>().createFuelLog(
                        {
                          'vehicle_id': vehicleId,
                          'odometer_km': odom,
                          'gallons': gallons,
                          'fuel_type': fuelType,
                          if (double.tryParse(costCtrl.text.trim()) != null)
                            'cost_usd': double.parse(costCtrl.text.trim()),
                          if (stationCtrl.text.trim().isNotEmpty) 'station': stationCtrl.text.trim(),
                          if (notesCtrl.text.trim().isNotEmpty) 'notes': notesCtrl.text.trim(),
                        },
                        receiptFilePath: receiptPath,
                        captureGps: captureGps,
                      );
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                  child: const Text('Guardar carga'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved == true) await _init();
  }

  Widget _buildSummarySection() {
    final s = _summary;
    final totals = s?.totals ?? const FuelSummaryTotals();

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
                const Text(
                  'Resumen y \$/km',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'week', label: Text('7d')),
                    ButtonSegment(value: 'month', label: Text('30d')),
                    ButtonSegment(value: 'all', label: Text('Todo')),
                  ],
                  selected: {_summaryRange},
                  onSelectionChanged: (sel) {
                    setState(() => _summaryRange = sel.first);
                    _load();
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _metricBox('Km período', '${totals.kmTraveled} km'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricBox('Galones', '${totals.gallons.toStringAsFixed(1)} gal'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricBox('Gasto', '\$${totals.costUsd.toStringAsFixed(2)}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _metricBox(
                    'Costo / km',
                    totals.costPerKm != null ? '\$${totals.costPerKm!.toStringAsFixed(2)}/km' : '—',
                    highlight: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricBox(
                    'Rendimiento',
                    totals.kmPerGallon != null ? '${totals.kmPerGallon!.toStringAsFixed(1)} km/gal' : '—',
                  ),
                ),
              ],
            ),
            if ((s?.byVehicle ?? const []).isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Por unidad',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              for (final v in s!.byVehicle)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${v.licensePlate} · ${v.kmTraveled} km',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '\$${v.costUsd.toStringAsFixed(2)}${v.costPerKm != null ? ' (\$${v.costPerKm!.toStringAsFixed(2)}/km)' : ''}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF465FFF)),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricBox(String label, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF465FFF).withValues(alpha: 0.12)
            : const Color(0xFF64748B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: highlight ? const Color(0xFF465FFF) : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Combustible')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateModal,
        icon: const Icon(Icons.local_gas_station_outlined),
        label: const Text('Registrar carga'),
      ),
      body: RefreshIndicator(
        onRefresh: _init,
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _items.isEmpty
                ? Center(child: Text(_error!))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                    itemCount: _items.isEmpty ? 2 : _items.length + 1,
                    itemBuilder: (_, idx) {
                      if (idx == 0) return _buildSummarySection();
                      if (_items.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Sin cargas de combustible registradas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        );
                      }
                      final f = _items[idx - 1];
                      final isUploading = _uploadingId == f.id;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (f.vehicle != null)
                                    PlateChip(
                                      f.vehicle!.licensePlate,
                                      plateType: f.vehicle!.plateType,
                                      plateNumber: f.vehicle!.plateNumber,
                                    ),
                                  Text(
                                    DateFormatter.dateTime(f.filledAt),
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${f.gallons.toStringAsFixed(2)} gal · ${f.fuelType.toUpperCase()}${f.costUsd != null ? ' · \$${f.costUsd!.toStringAsFixed(2)}' : ''}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${f.odometerKm} km · ${f.driverName ?? '—'}${f.station != null ? ' · ${f.station}' : ''}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                              if (f.locationAddress != null && f.locationAddress!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    f.locationAddress!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  ),
                                ),
                              if (f.kmPerGallon != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Rendimiento: ${f.kmPerGallon!.toStringAsFixed(1)} km/gal (${f.kmSinceLast} km recorridos)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF465FFF),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (f.hasGps)
                                    OutlinedButton.icon(
                                      onPressed: () => ExternalMapsLauncher.openGoogleMaps(
                                        latitude: f.latitude,
                                        longitude: f.longitude,
                                        destination: f.station ?? 'Gasolinera',
                                        address: f.locationAddress,
                                      ),
                                      icon: const Icon(Icons.location_on_outlined, size: 16),
                                      label: const Text('Mapa GPS'),
                                    ),
                                  if (f.hasReceipt)
                                    OutlinedButton.icon(
                                      onPressed: () => _openReceiptUrl(f.receiptUrl!),
                                      icon: const Icon(Icons.receipt_outlined, size: 16),
                                      label: const Text('Ver factura'),
                                    ),
                                  OutlinedButton.icon(
                                    onPressed: isUploading ? null : () => _attachReceiptToExisting(f),
                                    icon: isUploading
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.attach_file, size: 16),
                                    label: Text(
                                      f.hasReceipt ? 'Cambiar factura' : 'Adjuntar factura / foto',
                                    ),
                                  ),
                                ],
                              ),
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
