import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/tracking_models.dart';
import '../../../data/repositories/tracking_repository.dart';
import '../../../data/services/external_maps_launcher.dart';
import '../date_formatter.dart';
import 'status_badge.dart';

Future<void> showTripRouteSummarySheet({
  required BuildContext context,
  required TrackingRepository trackingRepository,
  required int sessionId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TripRouteSummarySheet(
      trackingRepository: trackingRepository,
      sessionId: sessionId,
    ),
  );
}

class _TripRouteSummarySheet extends StatefulWidget {
  const _TripRouteSummarySheet({
    required this.trackingRepository,
    required this.sessionId,
  });

  final TrackingRepository trackingRepository;
  final int sessionId;

  @override
  State<_TripRouteSummarySheet> createState() => _TripRouteSummarySheetState();
}

class _TripRouteSummarySheetState extends State<_TripRouteSummarySheet> {
  TripTrackingDetail? _detail;
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
      final res = await widget.trackingRepository.fetchSessionDetail(widget.sessionId);
      if (!mounted) return;
      setState(() => _detail = res);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = _detail;
    final session = detail?.session;
    final summary = detail?.summary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.93,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session != null
                            ? 'Ruta ${session.vehicle?.licensePlate ?? ''} · ${session.salidaBitacora?.destination ?? 'Misión'}'
                            : 'Resumen de misión y ruta',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      if (session != null)
                        Text(
                          '${session.driver?.name ?? 'Conductor'} · ${DateFormatter.dateTime(session.startedAt)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _load,
                  tooltip: 'Actualizar',
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading && detail == null
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              FilledButton(onPressed: _load, child: const Text('Reintentar')),
                            ],
                          ),
                        ),
                      )
                    : detail == null || session == null || summary == null
                        ? const SizedBox.shrink()
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (session.hasSosAlert) ...[
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE11D48).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFE11D48).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48)),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'ALERTA SOS ACTIVADA EN ESTA MISIÓN. Revisa el punto rojo en el mapa.',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                            color: Color(0xFFE11D48),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              _buildRouteMap(detail),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (summary.googleMapsRouteUrl != null)
                                    FilledButton.icon(
                                      onPressed: () => ExternalMapsLauncher.openUrl(
                                        summary.googleMapsRouteUrl!,
                                      ),
                                      icon: const Icon(Icons.map_outlined, size: 18),
                                      label: const Text('Abrir ruta en Google Maps'),
                                    ),
                                  if (summary.googleMapsLastUrl != null)
                                    OutlinedButton.icon(
                                      onPressed: () => ExternalMapsLauncher.openUrl(
                                        summary.googleMapsLastUrl!,
                                      ),
                                      icon: const Icon(Icons.my_location, size: 18),
                                      label: const Text('Último punto en Maps'),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildDeviceSecurityCard(session),
                              const SizedBox(height: 14),
                              _buildMetricsGrid(summary, session),
                              if (summary.stops.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                _buildStopsCard(summary.stops),
                              ],
                              const SizedBox(height: 14),
                              _buildTimelineCard(summary.timeline),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteMap(TripTrackingDetail detail) {
    final pts = detail.points;
    if (pts.isEmpty) {
      return Container(
        height: 170,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
        ),
        child: const Text(
          'Aún no hay coordenadas GPS recibidas para esta sesión.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      );
    }

    final routeLatLngs = pts.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final first = routeLatLngs.first;
    final last = routeLatLngs.last;
    final stops = detail.summary.stops;
    final sosPts = pts.where((p) => p.source == 'sos').toList();

    final markers = <Marker>[
      Marker(
        point: first,
        width: 34,
        height: 34,
        child: _pinDot(const Color(0xFF10B981), 'I'),
      ),
      Marker(
        point: last,
        width: 34,
        height: 34,
        child: _pinDot(
          detail.session.isActive ? const Color(0xFF465FFF) : const Color(0xFF0F172A),
          detail.session.isActive ? '•' : 'F',
        ),
      ),
      for (var i = 0; i < stops.length; i++)
        Marker(
          point: LatLng(stops[i].latitude, stops[i].longitude),
          width: 34,
          height: 34,
          child: Tooltip(
            message: 'Parada #${i + 1}: ${stops[i].durationMinutes} min',
            child: _pinDot(const Color(0xFFF59E0B), '${i + 1}'),
          ),
        ),
      for (final sp in sosPts)
        Marker(
          point: LatLng(sp.latitude, sp.longitude),
          width: 40,
          height: 40,
          child: _pinDot(const Color(0xFFE11D48), 'SOS'),
        ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 260,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: last,
            initialZoom: 14,
            initialCameraFit: routeLatLngs.length > 1
                ? CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(routeLatLngs),
                    padding: const EdgeInsets.all(36),
                  )
                : null,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'org.miascn.fleetlog.fleetlog_mobile',
            ),
            if (routeLatLngs.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routeLatLngs,
                    color: const Color(0xFF465FFF),
                    strokeWidth: 4.2,
                  ),
                ],
              ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }

  Widget _pinDot(Color color, String text) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          shape: text.length <= 2 ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: text.length <= 2 ? null : BorderRadius.circular(999),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceSecurityCard(TripTrackingSession s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dispositivo exclusivo rastreado',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                StatusBadge(kind: 'trackingStatus', value: s.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Celular: ${s.deviceName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(
              'ID dispositivo: ${s.deviceUuid}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            Text(
              'Cuenta que inició: ${s.startedByUser?.name ?? s.driver?.name ?? '—'}${s.lastBatteryLevel != null ? ' · Batería: ${s.lastBatteryLevel}%' : ''}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(TripRouteSummary summary, TripTrackingSession session) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.05,
      children: [
        _metricTile(
          'Distancia GPS',
          '${summary.gpsDistanceKm.toStringAsFixed(1)} km',
          summary.declaredDistanceKm != null ? 'Odómetro: ${summary.declaredDistanceKm} km' : 'Medida satelital',
        ),
        _metricTile(
          'Duración',
          DateFormatter.durationMinutes(summary.durationMinutes),
          '${summary.pointsCount} puntos GPS',
        ),
        _metricTile(
          'Velocidad máxima',
          '${summary.maxSpeedKmh.toStringAsFixed(1)} km/h',
          'Prom: ${summary.avgSpeedKmh.toStringAsFixed(1)} km/h',
        ),
        _metricTile(
          'Paradas (≥3 min)',
          '${summary.stops.length}',
          'Detenciones en ruta',
        ),
      ],
    );
  }

  Widget _metricTile(String label, String value, String sub) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildStopsCard(List<TripStopSummary> stops) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalle de paradas detectadas',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < stops.length; i++) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: _pinDot(const Color(0xFFF59E0B), '${i + 1}'),
                title: Text(
                  '${stops[i].durationMinutes} minutos detenido',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                subtitle: Text(
                  '${DateFormatter.shortTime(stops[i].startedAt)} – ${DateFormatter.shortTime(stops[i].endedAt)} · ${stops[i].latitude.toStringAsFixed(5)}, ${stops[i].longitude.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 11.5),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  tooltip: 'Ver parada en Google Maps',
                  onPressed: () => ExternalMapsLauncher.openGoogleMaps(
                    latitude: stops[i].latitude,
                    longitude: stops[i].longitude,
                  ),
                ),
              ),
              if (i < stops.length - 1) const Divider(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(List<TripTimelineEvent> timeline) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cronología completa de la misión',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (timeline.isEmpty)
              const Text('Sin eventos registrados.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))
            else
              for (final ev in timeline) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _eventColor(ev.type),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    ev.title,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Text(
                                  DateFormatter.dateTime(ev.at),
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                            if (ev.detail != null && ev.detail!.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  ev.detail!,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ),
                          ],
                        ),
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

  Color _eventColor(String type) => switch (type) {
    'salida' => const Color(0xFF10B981),
    'regreso' => const Color(0xFF465FFF),
    'stop' => const Color(0xFFF59E0B),
    'sos' || 'incident' || 'emergency' => const Color(0xFFE11D48),
    _ => const Color(0xFF64748B),
  };
}
