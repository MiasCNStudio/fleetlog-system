import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/bitacora_entry.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/repositories/fleet_repository.dart';
import '../../../data/repositories/tracking_repository.dart';
import '../../../data/services/background_tracking_service.dart';
import '../../../data/services/external_maps_launcher.dart';
import '../../core/date_formatter.dart';
import '../../core/widgets/location_picker_sheet.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/trip_route_summary_sheet.dart';
import '../auth/auth_controller.dart';

class BitacoraScreen extends StatefulWidget {
  const BitacoraScreen({super.key});

  @override
  State<BitacoraScreen> createState() => _BitacoraScreenState();
}

class _BitacoraScreenState extends State<BitacoraScreen> {
  List<BitacoraEntry> _items = const [];
  List<Vehicle> _vehicles = const [];
  bool _loading = true;
  String? _error;

  String _filterType = '';
  String _filterCategory = '';
  int _page = 1;
  int _lastPage = 1;

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
    await _load(1);
  }

  Future<void> _load([int page = 1]) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await context.read<FleetRepository>().fetchBitacoras(
        page: page,
        type: _filterType,
        tripCategory: _filterCategory,
      );
      if (!mounted) return;
      setState(() {
        _items = res.items;
        _page = res.currentPage;
        _lastPage = res.lastPage;
      });
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

    final user = context.read<AuthController>().user;
    final canManage = user?.canManageFleet ?? false;
    final repo = context.read<FleetRepository>();
    final auth = context.read<AuthController>();

    var category = 'personal';
    int? vehicleId = _vehicles.isNotEmpty ? _vehicles.first.id : null;
    var expectedType = 'salida';
    final odomCtrl = TextEditingController(
      text: _vehicles.isNotEmpty ? '${_vehicles.first.currentOdometer}' : '',
    );
    final notesCtrl = TextEditingController();
    var fuel = '3/4';
    PickedLocation? picked;

    Future<void> refreshVehicleNext(int? vid, StateSetter setDlg) async {
      if (vid == null) return;
      try {
        final next = await repo.fetchNextType(vid);
        setDlg(() {
          expectedType = next.type;
          odomCtrl.text = '${next.currentOdometer}';
        });
      } catch (_) {}
    }

    if (vehicleId != null) {
      try {
        final next = await repo.fetchNextType(vehicleId);
        expectedType = next.type;
        odomCtrl.text = '${next.currentOdometer}';
      } catch (_) {}
    }

    if (!mounted) return;

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
                Text(
                  expectedType == 'regreso' ? 'Registrar regreso' : 'Registrar salida controlada',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Las salidas normales inician desde Asignaciones. Aquí puedes cerrar un regreso o registrar una salida Personal.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: vehicleId,
                  decoration: const InputDecoration(labelText: 'Vehículo *'),
                  items: [
                    for (final v in _vehicles)
                      DropdownMenuItem(
                        value: v.id,
                        child: Text('${v.licensePlate} · ${v.brand} (${v.status})'),
                      ),
                  ],
                  onChanged: (v) {
                    setDlg(() => vehicleId = v);
                    refreshVehicleNext(v, setDlg);
                  },
                ),
                if (expectedType == 'salida') ...[
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: [
                      const ButtonSegment(value: 'personal', label: Text('Personal')),
                      if (canManage)
                        const ButtonSegment(value: 'imprevisto', label: Text('Viaje imprevisto')),
                    ],
                    selected: {category},
                    onSelectionChanged: (s) => setDlg(() => category = s.first),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final res = await showLocationPickerSheet(
                        context: ctx,
                        fleetRepository: repo,
                        initialDestination: picked?.destination,
                        initialLat: picked?.latitude,
                        initialLng: picked?.longitude,
                      );
                      if (res != null) setDlg(() => picked = res);
                    },
                    icon: const Icon(Icons.map_outlined),
                    label: Text(
                      picked == null
                          ? '¿A dónde te diriges? *'
                          : 'Destino: ${picked!.destination}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: odomCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Odómetro (km)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: fuel,
                        decoration: const InputDecoration(labelText: 'Combustible'),
                        items: const ['lleno', '3/4', '1/2', '1/4', 'reserva']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setDlg(() => fuel = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: category == 'imprevisto'
                        ? 'Motivo del viaje imprevisto *'
                        : 'Notas / motivo',
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () async {
                    if (vehicleId == null) return;
                    if (expectedType == 'salida' && picked == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Selecciona el destino en el mapa.')),
                      );
                      return;
                    }
                    await BackgroundTrackingService.requestLocationPermissions();
                    try {
                      await repo.createBitacora({
                        'vehicle_id': vehicleId,
                        if (expectedType == 'salida') 'trip_category': category,
                        if (picked != null) 'destination': picked!.destination,
                        if (picked != null) 'destination_address': picked!.address,
                        if (picked != null) 'latitude': picked!.latitude,
                        if (picked != null) 'longitude': picked!.longitude,
                        'odometer_km': int.tryParse(odomCtrl.text.trim()),
                        'fuel_level': fuel,
                        if (notesCtrl.text.trim().isNotEmpty) 'notes': notesCtrl.text.trim(),
                      });
                      await auth.syncActiveMissionTracking();
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                  child: Text(expectedType == 'regreso' ? 'Guardar regreso' : 'Registrar salida'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved == true) {
      await _load(1);
    }
  }

  void _openDetail(BitacoraEntry entry) {
    final user = context.read<AuthController>().user;
    final canManage = user?.canManageFleet ?? false;
    final trackingRepo = context.read<TrackingRepository>();
    final linkedTracking = entry.linkedTracking;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      PlateChip(entry.vehicle?.licensePlate ?? '—'),
                      const SizedBox(width: 8),
                      StatusBadge(kind: 'bitacoraType', value: entry.type),
                      const SizedBox(width: 6),
                      StatusBadge(kind: 'bitacoraCategory', value: entry.tripCategory),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Fecha: ${DateFormatter.dateTime(entry.recordedAt)}',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Text(
                'Conductor: ${entry.driver?.name ?? entry.user?.name ?? '—'}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                'Registrado por: ${entry.user?.name ?? '—'}',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),
              Text(
                'Destino: ${entry.destination ?? '—'}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              if (entry.destinationAddress != null && entry.destinationAddress!.isNotEmpty)
                Text(
                  entry.destinationAddress!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              const SizedBox(height: 8),
              Text(
                'Odómetro: ${entry.odometerKm ?? '—'} km · Combustible: ${entry.fuelLevel ?? '—'}',
                style: const TextStyle(fontSize: 12.5),
              ),
              if (entry.officialInstruction != null && entry.officialInstruction!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Instrucción oficial: ${entry.officialInstruction}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
                  ),
                ),
              if (entry.notes != null && entry.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Notas: ${entry.notes}', style: const TextStyle(fontSize: 12.5)),
                ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (entry.destination != null || entry.latitude != null)
                    OutlinedButton.icon(
                      onPressed: () => ExternalMapsLauncher.openGoogleMaps(
                        latitude: entry.latitude,
                        longitude: entry.longitude,
                        destination: entry.destination,
                        address: entry.destinationAddress,
                      ),
                      icon: const Icon(Icons.map_outlined, size: 17),
                      label: const Text('Google Maps'),
                    ),
                  if (canManage && linkedTracking != null)
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        showTripRouteSummarySheet(
                          context: context,
                          trackingRepository: trackingRepo,
                          sessionId: linkedTracking.id,
                        );
                      },
                      icon: const Icon(Icons.route_outlined, size: 17),
                      label: Text('Ver ruta GPS (${linkedTracking.gpsDistanceKm} km)'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bitácora'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateModal,
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _filterType,
                    decoration: const InputDecoration(labelText: 'Tipo', isDense: true),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Todos')),
                      DropdownMenuItem(value: 'salida', child: Text('Salidas')),
                      DropdownMenuItem(value: 'regreso', child: Text('Regresos')),
                    ],
                    onChanged: (v) {
                      setState(() => _filterType = v ?? '');
                      _load(1);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _filterCategory,
                    decoration: const InputDecoration(labelText: 'Categoría', isDense: true),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Todas')),
                      DropdownMenuItem(value: 'asignacion', child: Text('Asignación')),
                      DropdownMenuItem(value: 'personal', child: Text('Personal')),
                      DropdownMenuItem(value: 'imprevisto', child: Text('Imprevisto')),
                    ],
                    onChanged: (v) {
                      setState(() => _filterCategory = v ?? '');
                      _load(1);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(_page),
              child: _loading && _items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _items.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            FilledButton(onPressed: () => _load(1), child: const Text('Reintentar')),
                          ],
                        )
                      : _items.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.all(32),
                              children: const [
                                Text(
                                  'Sin registros en bitácora.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                              itemCount: _items.length + (_lastPage > 1 ? 1 : 0),
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (_, idx) {
                                if (idx >= _items.length) {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: _page > 1 ? () => _load(_page - 1) : null,
                                        child: const Text('Anterior'),
                                      ),
                                      Text('Página $_page de $_lastPage'),
                                      TextButton(
                                        onPressed: _page < _lastPage ? () => _load(_page + 1) : null,
                                        child: const Text('Siguiente'),
                                      ),
                                    ],
                                  );
                                }
                                final b = _items[idx];
                                return Card(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _openDetail(b),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  DateFormatter.dateTime(b.recordedAt),
                                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                                                ),
                                                const SizedBox(height: 2),
                                                StatusBadge(kind: 'bitacoraType', value: b.type),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                PlateChip(b.vehicle?.licensePlate ?? '—'),
                                                const SizedBox(height: 3),
                                                Text(
                                                  b.driver?.name ?? b.user?.name ?? '—',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Ver detalle',
                                            onPressed: () => _openDetail(b),
                                            icon: const Icon(Icons.visibility_outlined, color: Color(0xFF465FFF)),
                                          ),
                                        ],
                                      ),
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
