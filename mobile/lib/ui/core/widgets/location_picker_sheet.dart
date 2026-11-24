import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/place_suggestion.dart';
import '../../../data/repositories/fleet_repository.dart';

class PickedLocation {
  const PickedLocation({
    required this.destination,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeId,
  });

  final String destination;
  final String address;
  final double latitude;
  final double longitude;
  final String? placeId;
}

Future<PickedLocation?> showLocationPickerSheet({
  required BuildContext context,
  required FleetRepository fleetRepository,
  String? initialDestination,
  double? initialLat,
  double? initialLng,
}) {
  return showModalBottomSheet<PickedLocation>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _LocationPickerSheet(
      fleetRepository: fleetRepository,
      initialDestination: initialDestination,
      initialLat: initialLat,
      initialLng: initialLng,
    ),
  );
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet({
    required this.fleetRepository,
    this.initialDestination,
    this.initialLat,
    this.initialLng,
  });

  final FleetRepository fleetRepository;
  final String? initialDestination;
  final double? initialLat;
  final double? initialLng;

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final _searchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _mapCtrl = MapController();

  List<PlaceSuggestion> _results = const [];
  bool _searching = false;
  LatLng _selectedPoint = const LatLng(13.6978, -89.1914);
  bool _hasPin = false;
  String _address = '';
  String? _placeId;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.initialDestination ?? '';
    _searchCtrl.text = widget.initialDestination ?? '';
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedPoint = LatLng(widget.initialLat!, widget.initialLng!);
      _hasPin = true;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.length < 2) return;
    setState(() => _searching = true);
    try {
      final list = await widget.fleetRepository.searchPlaces(q);
      if (!mounted) return;
      setState(() => _results = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _results = const []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _selectSuggestion(PlaceSuggestion item) {
    final point = LatLng(item.latitude, item.longitude);
    setState(() {
      _results = const [];
      _selectedPoint = point;
      _hasPin = true;
      _nameCtrl.text = item.name;
      _searchCtrl.text = item.name;
      _address = item.address;
      _placeId = item.placeId;
    });
    _mapCtrl.move(point, 16);
  }

  Future<void> _onMapTap(LatLng latLng) async {
    setState(() {
      _selectedPoint = latLng;
      _hasPin = true;
    });
    final rev = await widget.fleetRepository.reversePlace(
      latLng.latitude,
      latLng.longitude,
    );
    if (!mounted || rev == null) return;
    setState(() {
      _address = rev.address;
      _placeId = rev.placeId;
      if (_nameCtrl.text.trim().isEmpty && rev.name.isNotEmpty) {
        _nameCtrl.text = rev.name;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccionar destino en mapa',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Busca un lugar o toca en el mapa para fijar el pin exacto.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      hintText: 'Ej. Centro Histórico de El Salvador…',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _searching ? null : _search,
                  child: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Buscar'),
                ),
              ],
            ),
          ),
          if (_results.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              constraints: const BoxConstraints(maxHeight: 170),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, idx) {
                  final item = _results[idx];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place, color: Color(0xFF465FFF)),
                    title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(item.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => _selectSuggestion(item),
                  );
                },
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    initialCenter: _selectedPoint,
                    initialZoom: _hasPin ? 16 : 12,
                    onTap: (_, latLng) => _onMapTap(latLng),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'org.miascn.fleetlog.fleetlog_mobile',
                    ),
                    if (_hasPin)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPoint,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFF465FFF),
                              size: 38,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre visible del destino *',
                  ),
                ),
                if (_address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    final dest = _nameCtrl.text.trim();
                    if (dest.isEmpty) return;
                    Navigator.pop(
                      context,
                      PickedLocation(
                        destination: dest,
                        address: _address.isNotEmpty ? _address : dest,
                        latitude: _selectedPoint.latitude,
                        longitude: _selectedPoint.longitude,
                        placeId: _placeId,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar ubicación'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
