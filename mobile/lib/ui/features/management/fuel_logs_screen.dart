import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/maintenance_fuel_models.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/repositories/fleet_repository.dart';
import '../../core/date_formatter.dart';
import '../../core/widgets/status_badge.dart';

class FuelLogsScreen extends StatefulWidget {
  const FuelLogsScreen({super.key});

  @override
  State<FuelLogsScreen> createState() => _FuelLogsScreenState();
}

class _FuelLogsScreenState extends State<FuelLogsScreen> {
  List<FuelLogEntry> _items = const [];
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
      final res = await context.read<FleetRepository>().fetchFuelLogs();
      if (!mounted) return;
      setState(() => _items = res.items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreateModal() async {
    if (_vehicles.isEmpty) await _init();
    if (!mounted) return;

    int? vehicleId = _vehicles.isNotEmpty ? _vehicles.first.id : null;
    var fuelType = 'regular';
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
                  decoration: const InputDecoration(labelText: 'Gasolinera'),
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
                      await context.read<FleetRepository>().createFuelLog({
                        'vehicle_id': vehicleId,
                        'odometer_km': odom,
                        'gallons': gallons,
                        'fuel_type': fuelType,
                        if (double.tryParse(costCtrl.text.trim()) != null)
                          'cost_usd': double.parse(costCtrl.text.trim()),
                        if (stationCtrl.text.trim().isNotEmpty) 'station': stationCtrl.text.trim(),
                        if (notesCtrl.text.trim().isNotEmpty) 'notes': notesCtrl.text.trim(),
                      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Combustible')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateModal,
        icon: const Icon(Icons.local_gas_station_outlined),
        label: const Text('Echar gas'),
      ),
      body: RefreshIndicator(
        onRefresh: _init,
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _items.isEmpty
                ? Center(child: Text(_error!))
                : _items.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(32),
                        children: const [
                          Text(
                            'Sin cargas de combustible registradas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                        itemCount: _items.length,
                        itemBuilder: (_, idx) {
                          final f = _items[idx];
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
