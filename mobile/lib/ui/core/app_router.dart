import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/assignments/assignments_screen.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/bitacora/bitacora_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/incidents/incidents_screen.dart';
import '../features/management/more_menu_screen.dart';
import '../features/management/system_logs_screen.dart';
import '../features/management/users_screen.dart';
import '../features/management/vehicles_screen.dart';
import '../features/tracking/tracking_screen.dart';

GoRouter createAppRouter(AuthController auth) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: auth,
    redirect: (context, state) {
      if (auth.initializing) return null;

      final loggedIn = auth.isAuthenticated;
      final onLogin = state.matchedLocation == '/login';

      if (!loggedIn) {
        return onLogin ? null : '/login';
      }
      if (onLogin) {
        return '/dashboard';
      }

      final user = auth.user;
      final path = state.matchedLocation;
      if (user != null) {
        if ((path == '/rastreo' || path == '/bitacora-sistema') && !user.canManageFleet) {
          return '/dashboard';
        }
        if (path == '/usuarios' && !user.isAdmin) {
          return '/dashboard';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => _FleetShell(
          auth: auth,
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, _) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/asignaciones',
            builder: (_, _) => const AssignmentsScreen(),
          ),
          GoRoute(
            path: '/bitacora',
            builder: (_, _) => const BitacoraScreen(),
          ),
          GoRoute(
            path: '/rastreo',
            builder: (_, _) => const TrackingScreen(),
          ),
          GoRoute(
            path: '/incidencias',
            builder: (_, _) => const IncidentsScreen(),
          ),
          GoRoute(
            path: '/mas',
            builder: (_, _) => const MoreMenuScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/vehiculos',
        builder: (_, _) => const VehiclesScreen(),
      ),
      GoRoute(
        path: '/bitacora-sistema',
        builder: (_, _) => const SystemLogsScreen(),
      ),
      GoRoute(
        path: '/usuarios',
        builder: (_, _) => const UsersScreen(),
      ),
    ],
  );
}

class _FleetShell extends StatelessWidget {
  const _FleetShell({
    required this.auth,
    required this.location,
    required this.child,
  });

  final AuthController auth;
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final canManage = auth.user?.canManageFleet ?? false;

    final tabs = canManage
        ? const [
            (route: '/dashboard', label: 'Panel', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard),
            (route: '/asignaciones', label: 'Agenda', icon: Icons.calendar_today_outlined, selectedIcon: Icons.calendar_today),
            (route: '/bitacora', label: 'Bitácora', icon: Icons.assignment_outlined, selectedIcon: Icons.assignment),
            (route: '/rastreo', label: 'Rastreo', icon: Icons.gps_fixed_outlined, selectedIcon: Icons.gps_fixed),
            (route: '/mas', label: 'Gestión', icon: Icons.apps_outlined, selectedIcon: Icons.apps),
          ]
        : const [
            (route: '/dashboard', label: 'Mi Panel', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard),
            (route: '/asignaciones', label: 'Agenda', icon: Icons.calendar_today_outlined, selectedIcon: Icons.calendar_today),
            (route: '/bitacora', label: 'Bitácora', icon: Icons.assignment_outlined, selectedIcon: Icons.assignment),
            (route: '/incidencias', label: 'Fallas', icon: Icons.report_problem_outlined, selectedIcon: Icons.report_problem),
            (route: '/mas', label: 'Cuenta', icon: Icons.person_outline, selectedIcon: Icons.person),
          ];

    var currentIndex = tabs.indexWhere((t) => location == t.route);
    if (currentIndex < 0) currentIndex = 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (idx) => context.go(tabs[idx].route),
        destinations: [
          for (final t in tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}
