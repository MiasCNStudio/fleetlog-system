import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/app_user.dart';
import '../../../data/repositories/fleet_repository.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<AppUser> _items = const [];
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
      final res = await context.read<FleetRepository>().fetchUsers();
      if (!mounted) return;
      setState(() => _items = res.items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor([AppUser? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final codeCtrl = TextEditingController(text: existing?.driverCode ?? '');
    final passCtrl = TextEditingController();
    var role = existing?.role ?? 'motorista';

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
                  existing == null ? 'Nuevo usuario' : 'Editar ${existing.name}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre completo *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo *'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 'motorista', child: Text('Motorista')),
                    DropdownMenuItem(value: 'despachador', child: Text('Jefe de motoristas')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDlg(() => role = v);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'Código motorista (opcional)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: existing == null ? 'Contraseña *' : 'Nueva contraseña (opcional)',
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () async {
                    try {
                      await context.read<FleetRepository>().saveUser(
                        id: existing?.id,
                        name: nameCtrl.text,
                        email: emailCtrl.text,
                        role: role,
                        driverCode: codeCtrl.text,
                        password: passCtrl.text,
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
                  child: const Text('Guardar usuario'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Usuario'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _items.isEmpty
                ? Center(child: Text(_error!))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                    itemCount: _items.length,
                    itemBuilder: (_, idx) {
                      final u = _items[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () => _openEditor(u),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF465FFF).withValues(alpha: 0.14),
                            child: Text(
                              u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF465FFF)),
                            ),
                          ),
                          title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${u.email}\n${u.roleLabel}${u.driverCode != null ? ' · ${u.driverCode}' : ''}'),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
