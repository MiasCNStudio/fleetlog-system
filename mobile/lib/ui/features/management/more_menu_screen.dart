import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';

class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión y cuenta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF465FFF).withValues(alpha: 0.16),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'F',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF465FFF),
                  ),
                ),
              ),
              title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${user.roleLabel} · ${user.email}'),
            ),
          ),
          if (auth.deviceIdentity != null) ...[
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.smartphone_outlined),
                title: Text('Celular vinculado: ${auth.deviceIdentity!.name}'),
                subtitle: Text(
                  'ID: ${auth.deviceIdentity!.uuid}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Módulos operativos',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.directions_car_outlined),
                  title: const Text('Vehículos'),
                  subtitle: const Text('Estado, odómetro y mantenimiento'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/vehiculos'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.report_problem_outlined),
                  title: const Text('Incidencias'),
                  subtitle: const Text('Reportar fallas con cámara o seguimiento'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/incidencias'),
                ),
                if (user.canManageFleet) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.shield_outlined),
                    title: const Text('Bitácora del sistema'),
                    subtitle: const Text('Auditoría completa de movimientos y alertas'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/bitacora-sistema'),
                  ),
                ],
                if (user.isAdmin) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.people_outline),
                    title: const Text('Usuarios'),
                    subtitle: const Text('Administradores, jefes de motoristas y conductores'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/usuarios'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(auth.darkMode ? Icons.dark_mode : Icons.light_mode),
                  title: const Text('Tema oscuro'),
                  value: auth.darkMode,
                  onChanged: (_) => auth.toggleDarkMode(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Color(0xFFE11D48)),
                  title: const Text(
                    'Cerrar sesión',
                    style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.w600),
                  ),
                  onTap: auth.logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
