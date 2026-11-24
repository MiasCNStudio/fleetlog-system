import { createRouter, createWebHistory } from 'vue-router';
import LoginView from './views/LoginView.vue';
import DashboardView from './views/DashboardView.vue';
import AssignmentsView from './views/AssignmentsView.vue';
import UsersView from './views/UsersView.vue';
import VehiclesView from './views/VehiclesView.vue';
import BitacoraView from './views/BitacoraView.vue';
import IncidentsView from './views/IncidentsView.vue';
import MaintenanceView from './views/MaintenanceView.vue';
import FuelLogsView from './views/FuelLogsView.vue';
import SystemLogsView from './views/SystemLogsView.vue';
import TrackingView from './views/TrackingView.vue';

const routes = [
  { path: '/login', name: 'login', component: LoginView },
  { path: '/', redirect: '/dashboard' },
  { path: '/dashboard', name: 'dashboard', component: DashboardView, meta: { requiresAuth: true } },
  { path: '/asignaciones', name: 'assignments', component: AssignmentsView, meta: { requiresAuth: true } },
  { path: '/usuarios', name: 'users', component: UsersView, meta: { requiresAuth: true, requiresAdmin: true } },
  { path: '/vehiculos', name: 'vehicles', component: VehiclesView, meta: { requiresAuth: true } },
  { path: '/bitacora', name: 'bitacora', component: BitacoraView, meta: { requiresAuth: true } },
  { path: '/incidencias', name: 'incidents', component: IncidentsView, meta: { requiresAuth: true } },
  {
    path: '/bitacora-sistema',
    name: 'system-logs',
    component: SystemLogsView,
    meta: { requiresAuth: true, requiresFleetManager: true },
  },
  {
    path: '/rastreo',
    name: 'tracking',
    component: TrackingView,
    meta: { requiresAuth: true, requiresFleetManager: true },
  },
  { path: '/mantenimiento', name: 'maintenance', component: MaintenanceView, meta: { requiresAuth: true } },
  { path: '/combustible', name: 'fuel', component: FuelLogsView, meta: { requiresAuth: true } },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

router.beforeEach((to) => {
  const hasToken = Boolean(localStorage.getItem('auth_token'));

  if (to.meta.requiresAuth && !hasToken) return { name: 'login' };
  if (to.name === 'login' && hasToken) return { name: 'dashboard' };

  if (to.meta.requiresAdmin || to.meta.requiresFleetManager) {
    try {
      const user = JSON.parse(localStorage.getItem('auth_user') || 'null');
      if (to.meta.requiresAdmin && user && user.role !== 'admin') {
        return { name: 'dashboard' };
      }
      if (to.meta.requiresFleetManager && user && !['admin', 'despachador'].includes(user.role)) {
        return { name: 'dashboard' };
      }
    } catch (_) {
      /* continúa y valida con API */
    }
  }

  return true;
});

export default router;
