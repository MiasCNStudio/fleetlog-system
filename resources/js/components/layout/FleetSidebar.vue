<template>
  <aside
    :class="[
      'group/sidebar fixed left-0 top-0 z-[99999] flex h-screen flex-col overflow-hidden border-r border-white/10 bg-[#1c2434] text-white shadow-[4px_0_24px_rgba(0,0,0,0.12)] transition-[width,transform] duration-300 ease-out',
      'w-[min(100vw,280px)] lg:w-[72px] lg:hover:w-[280px] lg:[@media(hover:none)]:w-[280px]',
      isMobileOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0',
    ]"
  >
    <div class="flex h-16 shrink-0 items-center border-b border-white/10">
      <router-link
        to="/dashboard"
        class="grid min-h-[4rem] w-full min-w-0 grid-cols-[72px_minmax(0,1fr)] items-center gap-0 hover:bg-white/5"
        @click="closeMobile"
      >
        <span
          class="flex size-10 shrink-0 items-center justify-center justify-self-center rounded-lg bg-brand-500 text-sm font-bold text-white shadow-sm"
        >
          F
        </span>
        <span
          class="truncate pr-4 text-base font-semibold tracking-tight text-white/95 transition-opacity duration-200 lg:opacity-0 lg:group-hover/sidebar:opacity-100 lg:[@media(hover:none)]:opacity-100"
        >
          Fleetlog
        </span>
      </router-link>
    </div>

    <div class="px-3 pb-2 pt-4">
      <p
        class="pl-2 text-[11px] font-semibold uppercase tracking-wider text-white/40 transition-opacity duration-200 lg:opacity-0 lg:group-hover/sidebar:opacity-100 lg:[@media(hover:none)]:opacity-100"
      >
        Menú
      </p>
    </div>

    <nav class="flex flex-1 flex-col gap-1 overflow-y-auto overflow-x-hidden px-2 pb-6">
      <router-link
        v-for="item in visibleItems"
        :key="item.to"
        :to="item.to"
        :title="item.label"
        class="flex min-h-[2.75rem] w-full min-w-0 items-center rounded-lg text-theme-sm font-medium transition-colors"
        :class="
          isActive(item.to)
            ? 'bg-white/10 text-brand-300'
            : 'text-white/80 hover:bg-white/5 hover:text-white'
        "
        @click="closeMobile"
      >
        <span class="grid w-full min-w-0 grid-cols-[72px_minmax(0,1fr)] items-center">
          <span class="flex size-9 items-center justify-center justify-self-center text-current [&>svg]:size-5">
            <component :is="item.icon" />
          </span>
          <span
            class="truncate pr-3 text-left transition-opacity duration-200 lg:opacity-0 lg:group-hover/sidebar:opacity-100 lg:[@media(hover:none)]:opacity-100"
          >
            {{ item.label }}
          </span>
        </span>
      </router-link>
    </nav>
  </aside>
</template>

<script setup>
import { computed, h } from 'vue';
import { useRoute } from 'vue-router';
import { useFleetLayout } from '@/composables/useFleetLayout.js';
import { useAuth } from '@/composables/useAuth.js';

const route = useRoute();
const { closeMobile, isMobileOpen } = useFleetLayout();
const { isAdmin } = useAuth();

const IconDashboard = {
  render() {
    return h(
      'svg',
      { fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', 'stroke-width': '1.75' },
      [
        h('path', {
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
          d: 'M4 5a1 1 0 011-1h4a1 1 0 011 1v5a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM14 5a1 1 0 011-1h4a1 1 0 011 1v2a1 1 0 01-1 1h-4a1 1 0 01-1-1V5zM4 16a1 1 0 011-1h4a1 1 0 011 1v3a1 1 0 01-1 1H5a1 1 0 01-1-1v-3zM14 13a1 1 0 011-1h4a1 1 0 011 1v6a1 1 0 01-1 1h-4a1 1 0 01-1-1v-6z',
        }),
      ],
    );
  },
};

const IconUsers = {
  render() {
    return h(
      'svg',
      { fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', 'stroke-width': '1.75' },
      [
        h('path', {
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
          d: 'M15 19.128a9 9 0 002.618-.106 3 3 0 00-4.682-2.825 9 9 0 01-5.936 0 3 3 0 00-4.682 2.825A9 9 0 0112 21a9 9 0 014-1.872zM12 12a4 4 0 100-8 4 4 0 000 8z',
        }),
      ],
    );
  },
};

const IconTruck = {
  render() {
    return h(
      'svg',
      { fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', 'stroke-width': '1.75' },
      [
        h('path', {
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
          d: 'M9 17a2 2 0 11-4 0 2 2 0 014 0zM19 17a2 2 0 11-4 0 2 2 0 014 0z',
        }),
        h('path', {
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
          d: 'M13 16V6a1 1 0 00-1-1H4a1 1 0 00-1 1v10a1 1 0 001 1h1m8-1a1 1 0 01-1 1H9m4-1V8a1 1 0 011-1h2.586a1 1 0 01.707.293l3.414 3.414a1 1 0 01.293.707V16a1 1 0 01-1 1h-1m-6-1a1 1 0 001 1h1M5 17a2 2 0 104 0m-4 0a2 2 0 114 0m6 0a2 2 0 104 0m-4 0a2 2 0 114 0',
        }),
      ],
    );
  },
};

const IconClipboard = {
  render() {
    return h(
      'svg',
      { fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', 'stroke-width': '1.75' },
      [
        h('path', {
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
          d: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01',
        }),
      ],
    );
  },
};

const IconAlert = {
  render() {
    return h(
      'svg',
      { fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', 'stroke-width': '1.75' },
      [
        h('path', {
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
          d: 'M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z',
        }),
      ],
    );
  },
};

const items = [
  { label: 'Dashboard', to: '/dashboard', icon: IconDashboard },
  { label: 'Bitácora', to: '/bitacora', icon: IconClipboard },
  { label: 'Vehículos', to: '/vehiculos', icon: IconTruck },
  { label: 'Incidencias', to: '/incidencias', icon: IconAlert },
  { label: 'Usuarios', to: '/usuarios', icon: IconUsers, adminOnly: true },
];

const visibleItems = computed(() =>
  items.filter((item) => !item.adminOnly || isAdmin.value),
);

const isActive = (path) => route.path === path || route.path.startsWith(`${path}/`);
</script>
