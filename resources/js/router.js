import { createRouter, createWebHistory } from 'vue-router';
import LoginView from './views/LoginView.vue';
import DashboardView from './views/DashboardView.vue';
import UsersView from './views/UsersView.vue';
import VehiclesView from './views/VehiclesView.vue';
import BitacoraView from './views/BitacoraView.vue';

const routes = [
  { path: '/login', name: 'login', component: LoginView },
  { path: '/', redirect: '/dashboard' },
  { path: '/dashboard', name: 'dashboard', component: DashboardView, meta: { requiresAuth: true } },
  { path: '/usuarios', name: 'users', component: UsersView, meta: { requiresAuth: true } },
  { path: '/vehiculos', name: 'vehicles', component: VehiclesView, meta: { requiresAuth: true } },
  { path: '/bitacora', name: 'bitacora', component: BitacoraView, meta: { requiresAuth: true } },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

router.beforeEach((to) => {
  const hasToken = Boolean(localStorage.getItem('auth_token'));

  if (to.meta.requiresAuth && !hasToken) return { name: 'login' };
  if (to.name === 'login' && hasToken) return { name: 'dashboard' };

  return true;
});

export default router;
