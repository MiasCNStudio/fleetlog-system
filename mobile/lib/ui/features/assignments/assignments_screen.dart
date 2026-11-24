import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/app_user.dart';
import '../../../data/models/assignment.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/repositories/fleet_repository.dart';
import '../../../data/services/background_tracking_service.dart';
import '../../../data/services/external_maps_launcher.dart';
import '../../core/widgets/location_picker_sheet.dart';
import '../../core/widgets/status_badge.dart';
import '../auth/auth_controller.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  List<Assignment> _items = const [];
  List<Vehicle> _vehicles = const [];
  List<AppUser> _drivers = const [];
  bool _loading = true;
  String? _error;

  String _range = 'all';
  String _filterStatus = '';
  int? _filterDriverId;
  int? _filterVehicleId;
  bool _onlyMine = false;
  int _page = 1;
  int _lastPage = 1;

  int get _activeFilterCount =>
      (_filterStatus.isNotEmpty ? 1 : 0) +
      (_filterDriverId != null ? 1 : 0) +
      (_filterVehicleId != null ? 1 : 0) +
      (_onlyMine ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final repo = context.read<FleetRepository>();
    try {
      final results = await Future.wait([
        repo.fetchVehicleOptions(),
        repo.fetchDriverOptions(),
      ]);
      if (mounted) {
        setState(() {
          _vehicles = results[0] as List<Vehicle>;
          _drivers = results[1] as List<AppUser>;
        });
      }
    } catch (_) {}
    await _load(1);
  }

  Future<void> _load([int page = 1]) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await context.read<FleetRepository>().fetchAssignments(
        page: page,
        range: _range,
        status: _filterStatus,
        driverId: _filterDriverId,
        vehicleId: _filterVehicleId,
        mine: _onlyMine,
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

  Future<void> _openFilterModal() async {
    var status = _filterStatus;
    var driverId = _filterDriverId;
    var vehicleId = _filterVehicleId;
    var onlyMine = _onlyMine;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtrar asignaciones',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Todos')),
                  DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                  DropdownMenuItem(value: 'en_curso', child: Text('En curso')),
                  DropdownMenuItem(value: 'completada', child: Text('Completada')),
                  DropdownMenuItem(value: 'cancelada', child: Text('Cancelada')),
                ],
                onChanged: (v) => setModalState(() => status = v ?? ''),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: driverId,
                decoration: const InputDecoration(labelText: 'Motorista'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Todos los motoristas')),
                  for (final d in _drivers)
                    DropdownMenuItem<int?>(value: d.id, child: Text(d.name)),
                ],
                onChanged: (v) => setModalState(() => driverId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: vehicleId,
                decoration: const InputDecoration(labelText: 'Vehículo'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Todos los vehículos')),
                  for (final v in _vehicles)
                    DropdownMenuItem<int?>(
                      value: v.id,
                      child: Text('${v.licensePlate} · ${v.brand}'),
                    ),
                ],
                onChanged: (v) => setModalState(() => vehicleId = v),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mostrar solo mis viajes asignados'),
                value: onlyMine,
                onChanged: (v) => setModalState(() => onlyMine = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _filterStatus = '';
                          _filterDriverId = null;
                          _filterVehicleId = null;
                          _onlyMine = false;
                        });
                        Navigator.pop(ctx, true);
                      },
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _filterStatus = status;
                          _filterDriverId = driverId;
                          _filterVehicleId = vehicleId;
                          _onlyMine = onlyMine;
                        });
                        Navigator.pop(ctx, true);
                      },
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (applied == true) {
      await _load(1);
    }
  }

  Future<void> _openCreateAssignmentSheet() async {
    if (_vehicles.isEmpty || _drivers.isEmpty) {
      await _init();
    }
    if (!mounted) return;

    int? vehicleId = _vehicles.isNotEmpty ? _vehicles.first.id : null;
    int? driverId = _drivers.isNotEmpty ? _drivers.first.id : null;
    var startDate = DateTime.now().toIso8601String().split('T').first;
    var endDate = '';
    final timeCtrl = TextEditingController(text: '08:00');
    final companionsCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final instrCtrl = TextEditingController();
    PickedLocation? picked;

    final repo = context.read<FleetRepository>();

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => Padding(
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
                  'Programar asignación',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: driverId,
                  decoration: const InputDecoration(labelText: 'Motorista *'),
                  items: [
                    for (final d in _drivers)
                      DropdownMenuItem(value: d.id, child: Text(d.name)),
                  ],
                  onChanged: (v) => setDlgState(() => driverId = v),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int?>(
                  initialValue: vehicleId,
                  decoration: const InputDecoration(labelText: 'Vehículo *'),
                  items: [
                    for (final v in _vehicles)
                      DropdownMenuItem(
                        value: v.id,
                        child: Text('${v.licensePlate} · ${v.brand} ${v.model}'),
                      ),
                  ],
                  onChanged: (v) => setDlgState(() => vehicleId = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: startDate,
                        decoration: const InputDecoration(labelText: 'Fecha inicio (YYYY-MM-DD)'),
                        onChanged: (v) => startDate = v.trim(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: endDate,
                        decoration: const InputDecoration(labelText: 'Fecha fin (lote opc.)'),
                        onChanged: (v) => endDate = v.trim(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: timeCtrl,
                  decoration: const InputDecoration(labelText: 'Hora programada (HH:MM)'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final res = await showLocationPickerSheet(
                      context: ctx,
                      fleetRepository: repo,
                      initialDestination: picked?.destination,
                      initialLat: picked?.latitude,
                      initialLng: picked?.longitude,
                    );
                    if (res != null) {
                      setDlgState(() => picked = res);
                    }
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: Text(
                    picked == null
                        ? 'Elegir destino en mapa *'
                        : 'Destino: ${picked!.destination}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: companionsCtrl,
                  decoration: const InputDecoration(labelText: 'Personas asignadas / acompañantes'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: instrCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Instrucción oficial (obligatoria en ruta)',
                    hintText: 'Ej. Esperar al equipo hasta las 16:00',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descripción de misión'),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () async {
                    if (vehicleId == null || driverId == null || picked == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Completa motorista, vehículo y destino en el mapa.')),
                      );
                      return;
                    }
                    try {
                      await repo.createAssignment({
                        'vehicle_id': vehicleId,
                        'driver_id': driverId,
                        'scheduled_date': startDate,
                        if (endDate.isNotEmpty) 'end_date': endDate,
                        'scheduled_time': timeCtrl.text.trim(),
                        'destination': picked!.destination,
                        'destination_address': picked!.address,
                        'latitude': picked!.latitude,
                        'longitude': picked!.longitude,
                        if (picked!.placeId != null) 'place_id': picked!.placeId,
                        if (companionsCtrl.text.trim().isNotEmpty)
                          'companions': companionsCtrl.text.trim(),
                        if (instrCtrl.text.trim().isNotEmpty)
                          'official_instruction': instrCtrl.text.trim(),
                        if (descCtrl.text.trim().isNotEmpty)
                          'description': descCtrl.text.trim(),
                      });
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                  child: const Text('Guardar asignación'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (created == true) {
      await _load(1);
    }
  }

  Future<void> _startTrip(Assignment a) async {
    await BackgroundTrackingService.requestLocationPermissions();
    if (!mounted) return;
    final auth = context.read<AuthController>();
    final repo = context.read<FleetRepository>();
    try {
      await repo.createBitacora({
        'assignment_id': a.id,
        'vehicle_id': a.vehicleId,
        'odometer_km': a.vehicle?.currentOdometer,
      });
      await auth.syncActiveMissionTracking();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Viaje iniciado con rastreo GPS activo.')),
      );
      await _load(_page);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _emergencyReassign(Assignment a) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tomar viaje por emergencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Titular actual: ${a.driver?.name ?? 'Motorista'}\nDestino: ${a.destination}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Razón justificada *',
                hintText: 'Ej. Titular incapacitado o atendiendo otra ruta urgente',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar emergencia'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    if (reasonCtrl.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica una razón justificada (mínimo 5 caracteres).')),
      );
      return;
    }

    try {
      await context.read<FleetRepository>().emergencyReassign(
        assignmentId: a.id,
        reason: reasonCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reasignación de emergencia registrada y auditada.')),
      );
      await _load(_page);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _registerReturn(Assignment a) async {
    final odomCtrl = TextEditingController(
      text: a.vehicle?.currentOdometer.toString() ?? '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar regreso'),
        content: TextField(
          controller: odomCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Odómetro final (km)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final auth = context.read<AuthController>();
    final repo = context.read<FleetRepository>();
    try {
      await repo.createBitacora({
        'assignment_id': a.id,
        'vehicle_id': a.vehicleId,
        'odometer_km': int.tryParse(odomCtrl.text.trim()),
      });
      await auth.syncActiveMissionTracking();
      if (!mounted) return;
      await _load(_page);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final canManage = user?.canManageFleet ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignaciones'),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                tooltip: 'Filtros',
                onPressed: _openFilterModal,
                icon: const Icon(Icons.tune_rounded),
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF465FFF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_activeFilterCount',
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _openCreateAssignmentSheet,
              icon: const Icon(Icons.add),
              label: const Text('Asignar'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'today', label: Text('Hoy')),
                ButtonSegment(value: 'week', label: Text('Semana')),
                ButtonSegment(value: 'month', label: Text('Mes')),
                ButtonSegment(value: 'all', label: Text('Todas')),
              ],
              selected: {_range},
              onSelectionChanged: (s) {
                setState(() => _range = s.first);
                _load(1);
              },
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
                                  'No hay asignaciones registradas en este rango.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
                              itemCount: _items.length + (_lastPage > 1 ? 1 : 0),
                              itemBuilder: (ctx, idx) {
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
                                final a = _items[idx];
                                final isMine = user != null && a.driverId == user.id;
                                final canStart = a.isPending && (canManage || isMine);

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
                                            Text(
                                              '${a.scheduledDate}${a.scheduledTime != null ? ' · ${a.scheduledTime}' : ''}',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                            ),
                                            StatusBadge(kind: 'assignmentStatus', value: a.status),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          a.destination,
                                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            PlateChip(a.vehicle?.licensePlate ?? '—'),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                a.driver?.name ?? '—',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (a.officialInstruction != null && a.officialInstruction!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                'Instrucción oficial: ${a.officialInstruction}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFFB45309),
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (a.isEmergencyReassigned)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Text(
                                              'Emergencia (sustituyó a ${a.originalDriver?.name ?? 'titular'}): ${a.reassignmentReason ?? ''}',
                                              style: const TextStyle(fontSize: 11.5, color: Color(0xFFE11D48)),
                                            ),
                                          ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: () => ExternalMapsLauncher.openGoogleMaps(
                                                latitude: a.latitude,
                                                longitude: a.longitude,
                                                destination: a.destination,
                                                address: a.destinationAddress,
                                              ),
                                              icon: const Icon(Icons.map_outlined, size: 16),
                                              label: const Text('Maps'),
                                            ),
                                            OutlinedButton.icon(
                                              onPressed: () => ExternalMapsLauncher.openWaze(
                                                latitude: a.latitude,
                                                longitude: a.longitude,
                                                destination: a.destination,
                                                address: a.destinationAddress,
                                              ),
                                              icon: const Icon(Icons.navigation_outlined, size: 16),
                                              label: const Text('Waze'),
                                            ),
                                            if (canStart)
                                              FilledButton.icon(
                                                onPressed: () => _startTrip(a),
                                                icon: const Icon(Icons.play_arrow, size: 18),
                                                label: const Text('Iniciar'),
                                              ),
                                            if (a.isPending && !isMine)
                                              OutlinedButton.icon(
                                                onPressed: () => _emergencyReassign(a),
                                                icon: const Icon(Icons.warning_amber, size: 16, color: Color(0xFFD97706)),
                                                label: const Text('Emergencia'),
                                              ),
                                            if (a.isInProgress && (canManage || isMine))
                                              FilledButton.icon(
                                                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                                                onPressed: () => _registerReturn(a),
                                                icon: const Icon(Icons.check, size: 18),
                                                label: const Text('Regreso'),
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
          ),
        ],
      ),
    );
  }
}
