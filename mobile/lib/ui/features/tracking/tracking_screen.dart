import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../data/models/tracking_models.dart';
import '../../../data/repositories/tracking_repository.dart';
import '../../../data/services/external_maps_launcher.dart';
import '../../core/date_formatter.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/trip_route_summary_sheet.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  List<TripTrackingSession> _active = const [];
  List<TripTrackingSession> _history = const [];
  bool _loading = true;
  String? _error;

  String _statusFilter = '';
  bool _sosOnly = false;
  int _page = 1;
  int _lastPage = 1;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadActive());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadActive() async {
    try {
      final list = await context.read<TrackingRepository>().fetchActiveFleet();
      if (!mounted) return;
      setState(() => _active = list);
    } catch (_) {}
  }

  Future<void> _loadAll([int page = 1]) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = context.read<TrackingRepository>();
    try {
      final results = await Future.wait([
        repo.fetchActiveFleet(),
        repo.fetchSessions(
          page: page,
          status: _statusFilter,
          sosOnly: _sosOnly,
        ),
      ]);
      if (!mounted) return;
      final paged = results[1] as PaginatedResult<TripTrackingSession>;
      setState(() {
        _active = results[0] as List<TripTrackingSession>;
        _history = paged.items;
        _page = paged.currentPage;
        _lastPage = paged.lastPage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openDetail(int sessionId) {
    showTripRouteSummarySheet(
      context: context,
      trackingRepository: context.read<TrackingRepository>(),
      sessionId: sessionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final positioned = _active
        .where((s) => s.lastLatitude != null && s.lastLongitude != null)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastreo GPS y rutas'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => _loadAll(_page),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadAll(_page),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Unidades en ruta ahora',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                StatusBadge(kind: 'trackingStatus', value: 'activa'),
              ],
            ),
            const SizedBox(height: 10),
            if (positioned.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 230,
                  child: _buildLiveFleetMap(positioned),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_active.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'No hay misiones activas transmitiendo ubicación en este momento.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              )
            else
              for (final s in _active)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: s.hasSosAlert
                      ? const Color(0xFFE11D48).withValues(alpha: 0.08)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                PlateChip(s.vehicle?.licensePlate ?? '—'),
                                const SizedBox(width: 8),
                                if (s.hasSosAlert)
                                  const StatusBadge(kind: 'logAction', value: 'sos_alert')
                                else
                                  StatusBadge(kind: 'trackingStatus', value: s.status),
                              ],
                            ),
                            Text(
                              '${s.gpsDistanceKm} km${s.lastBatteryLevel != null ? ' · ${s.lastBatteryLevel}%' : ''}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.driver?.name ?? 'Conductor',
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Destino: ${s.salidaBitacora?.destination ?? 'Sin destino'}',
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Celular: ${s.deviceName} · Último ping: ${DateFormatter.dateTime(s.lastPingAt)}',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _openDetail(s.id),
                                icon: const Icon(Icons.route_outlined, size: 17),
                                label: const Text('Ver recorrido'),
                              ),
                            ),
                            if (s.lastLatitude != null && s.lastLongitude != null) ...[
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => ExternalMapsLauncher.openGoogleMaps(
                                  latitude: s.lastLatitude,
                                  longitude: s.lastLongitude,
                                ),
                                icon: const Icon(Icons.map_outlined, size: 17),
                                label: const Text('Maps'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            const Text(
              'Historial y resúmenes finales',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _statusFilter,
                    decoration: const InputDecoration(labelText: 'Estado', isDense: true),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Todos')),
                      DropdownMenuItem(value: 'activa', child: Text('En misión')),
                      DropdownMenuItem(value: 'finalizada', child: Text('Finalizada')),
                    ],
                    onChanged: (v) {
                      setState(() => _statusFilter = v ?? '');
                      _loadAll(1);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                FilterChip(
                  selected: _sosOnly,
                  label: const Text('Solo SOS'),
                  onSelected: (v) {
                    setState(() => _sosOnly = v);
                    _loadAll(1);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading && _history.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _history.isEmpty)
              Text(_error!, textAlign: TextAlign.center)
            else if (_history.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Aún no hay sesiones de rastreo registradas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              )
            else ...[
              for (final s in _history)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    onTap: () => _openDetail(s.id),
                    title: Row(
                      children: [
                        PlateChip(s.vehicle?.licensePlate ?? '—'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.driver?.name ?? '—',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${s.salidaBitacora?.destination ?? 'Sin destino'} · ${DateFormatter.dateTime(s.startedAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            '${s.deviceName} · ${s.gpsDistanceKm} km GPS · ${s.stopsCount} paradas',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        StatusBadge(kind: 'trackingStatus', value: s.status),
                        const SizedBox(height: 4),
                        const Text(
                          'Ver mapa ›',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF465FFF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_lastPage > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _page > 1 ? () => _loadAll(_page - 1) : null,
                      child: const Text('Anterior'),
                    ),
                    Text('Página $_page de $_lastPage'),
                    TextButton(
                      onPressed: _page < _lastPage ? () => _loadAll(_page + 1) : null,
                      child: const Text('Siguiente'),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLiveFleetMap(List<TripTrackingSession> positioned) {
    final allPoints = <LatLng>[];
    final polylines = <Polyline>[];
    final markers = <Marker>[];

    for (final s in positioned) {
      final trail = s.recentTrail
          .map((pt) => LatLng(pt.latitude, pt.longitude))
          .toList();
      if (trail.length > 1) {
        polylines.add(
          Polyline(
            points: trail,
            color: s.hasSosAlert ? const Color(0xFFE11D48) : const Color(0xFF465FFF),
            strokeWidth: 3.5,
          ),
        );
        allPoints.addAll(trail);
      }

      final pos = LatLng(s.lastLatitude!, s.lastLongitude!);
      allPoints.add(pos);
      markers.add(
        Marker(
          point: pos,
          width: 96,
          height: 36,
          child: GestureDetector(
            onTap: () => _openDetail(s.id),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: s.hasSosAlert ? const Color(0xFFE11D48) : const Color(0xFF465FFF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  s.vehicle?.licensePlate ?? 'Unidad',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: allPoints.first,
        initialZoom: 13,
        initialCameraFit: allPoints.length > 1
            ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(allPoints),
                padding: const EdgeInsets.all(36),
              )
            : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'org.miascn.fleetlog.fleetlog_mobile',
        ),
        PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
