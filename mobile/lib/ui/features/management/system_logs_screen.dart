import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/system_log_entry.dart';
import '../../../data/repositories/fleet_repository.dart';
import '../../core/date_formatter.dart';
import '../../core/widgets/status_badge.dart';

class SystemLogsScreen extends StatefulWidget {
  const SystemLogsScreen({super.key});

  @override
  State<SystemLogsScreen> createState() => _SystemLogsScreenState();
}

class _SystemLogsScreenState extends State<SystemLogsScreen> {
  List<SystemLogEntry> _items = const [];
  bool _loading = true;
  String? _error;
  String _module = '';
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
      final res = await context.read<FleetRepository>().fetchSystemLogs(
        search: _searchCtrl.text,
        module: _module,
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

  void _showMetadata(SystemLogEntry log) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${log.userName} · ${log.action}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(log.summary, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Fecha: ${DateFormatter.dateTime(log.createdAt)}', style: const TextStyle(fontSize: 12)),
              if (log.ipAddress != null)
                Text('IP: ${log.ipAddress}', style: const TextStyle(fontSize: 12)),
              if (log.prettyMetadata.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    log.prettyMetadata,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bitácora del sistema')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) => _load(),
                    decoration: const InputDecoration(
                      hintText: 'Buscar usuario, placa…',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _module,
                    decoration: const InputDecoration(labelText: 'Módulo', isDense: true),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Todos')),
                      DropdownMenuItem(value: 'tracking', child: Text('Rastreo GPS')),
                      DropdownMenuItem(value: 'bitacoras', child: Text('Bitácora')),
                      DropdownMenuItem(value: 'assignments', child: Text('Asignaciones')),
                      DropdownMenuItem(value: 'incidents', child: Text('Incidencias')),
                      DropdownMenuItem(value: 'auth', child: Text('Acceso')),
                    ],
                    onChanged: (v) {
                      setState(() => _module = v ?? '');
                      _load();
                    },
                  ),
                ),
              ],
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
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          itemBuilder: (_, idx) {
                            final log = _items[idx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                onTap: () => _showMetadata(log),
                                title: Text(
                                  log.summary,
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      StatusBadge(kind: 'logModule', value: log.module),
                                      StatusBadge(kind: 'logAction', value: log.action),
                                      Text(
                                        '${log.userName} · ${DateFormatter.dateTime(log.createdAt)}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
