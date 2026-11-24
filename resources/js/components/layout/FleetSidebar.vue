<template>
  <aside
    aria-label="Navegación principal"
    :class="[
      'fixed left-0 top-0 z-50 flex h-screen flex-col border-r border-white/[0.08] bg-gradient-to-b from-[#131c31] via-[#0f172a] to-[#0b1120] text-white shadow-2xl transition-[width,transform] duration-300 ease-out lg:shadow-none',
      'w-72 max-w-[85vw]',
      isDesktopCollapsed ? 'lg:w-[76px]' : 'lg:w-64',
      isMobileOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0',
    ]"
  >
    <div
      :class="[
        'flex h-16 shrink-0 items-center border-b border-white/[0.07] px-3',
        isDesktopCollapsed ? 'lg:justify-center' : 'justify-between',
      ]"
    >
      <router-link
        to="/dashboard"
        :class="[
          'flex min-w-0 items-center gap-3 rounded-xl p-1.5 transition-colors hover:bg-white/[0.05] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-400',
          isDesktopCollapsed ? 'lg:justify-center' : '',
        ]"
        @click="closeMobile"
      >
        <span
          class="flex size-9 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-brand-400 to-brand-600 text-sm font-bold text-white shadow-[0_2px_10px_rgba(70,95,255,0.45)] ring-1 ring-white/20"
        >
          F
        </span>
        <span
          :class="[
            'min-w-0 truncate',
            isDesktopCollapsed ? 'lg:hidden' : '',
          ]"
        >
          <span class="block truncate text-base font-semibold tracking-tight text-white">Fleetlog</span>
          <span class="block truncate text-[11px] font-normal text-slate-400">Control de flotilla</span>
        </span>
      </router-link>

      <button
        type="button"
        class="inline-flex size-9 shrink-0 items-center justify-center rounded-xl text-slate-300 transition-colors hover:bg-white/10 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-400 lg:hidden"
        aria-label="Cerrar menú"
        @click="closeMobile"
      >
        <svg class="size-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>

    <div class="px-3 pb-2 pt-4">
      <p
        :class="[
          'px-2.5 text-[11px] font-semibold uppercase tracking-wider text-slate-400/90',
          isDesktopCollapsed ? 'lg:hidden' : '',
        ]"
      >
        Operación
      </p>
      <div
        v-if="isDesktopCollapsed"
        class="hidden border-t border-white/[0.08] lg:block"
        aria-hidden="true"
      />
    </div>

    <nav class="flex flex-1 flex-col gap-1 overflow-y-auto overflow-x-hidden px-3 pb-4">
      <router-link
        v-for="item in visibleItems"
        :key="item.to"
        :to="item.to"
        :title="isDesktopCollapsed ? item.label : undefined"
        :aria-current="isActive(item.to) ? 'page' : undefined"
        :class="[
          'group relative flex min-h-[2.75rem] items-center rounded-xl text-theme-sm font-medium transition-all duration-150 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-400',
          isDesktopCollapsed ? 'gap-3 px-3 lg:justify-center lg:px-0' : 'gap-3 px-3',
          isActive(item.to)
            ? 'bg-gradient-to-r from-brand-500/25 to-brand-500/10 text-white shadow-[inset_0_1px_0_rgba(255,255,255,0.08)] ring-1 ring-inset ring-brand-400/30'
            : 'text-slate-300 hover:bg-white/[0.06] hover:text-white',
        ]"
        @click="closeMobile"
      >
        <span
          v-if="isActive(item.to) && !isDesktopCollapsed"
          class="absolute left-0 top-1/2 h-5 w-1 -translate-y-1/2 rounded-r-full bg-brand-400"
          aria-hidden="true"
        />
        <span
          :class="[
            'flex size-6 shrink-0 items-center justify-center transition-colors [&>svg]:size-5',
            isActive(item.to) ? 'text-brand-300' : 'text-slate-400 group-hover:text-white',
          ]"
        >
          <component :is="item.icon" />
        </span>
        <span
          :class="[
            'truncate',
            isDesktopCollapsed ? 'lg:hidden' : '',
          ]"
        >
          {{ item.label }}
        </span>
      </router-link>
    </nav>

    <div class="hidden border-t border-white/[0.07] p-3 lg:block">
      <button
        type="button"
        :title="isDesktopCollapsed ? 'Expandir menú' : 'Contraer menú'"
        :aria-label="isDesktopCollapsed ? 'Expandir menú lateral' : 'Contraer menú lateral'"
        :aria-expanded="!isDesktopCollapsed"
        :class="[
          'flex h-10 w-full items-center rounded-xl text-theme-xs font-medium text-slate-300 transition-colors hover:bg-white/[0.08] hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-400',
          isDesktopCollapsed ? 'justify-center px-0' : 'justify-between px-3',
        ]"
        @click="toggleDesktopCollapsed"
      >
        <span v-if="!isDesktopCollapsed" class="truncate">Contraer menú</span>
        <svg
          :class="['size-4 shrink-0 transition-transform duration-200', isDesktopCollapsed ? 'rotate-180' : '']"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          stroke-width="1.8"
          aria-hidden="true"
        >
          <path stroke-linecap="round" stroke-linejoin="round" d="M18.75 19.5l-7.5-7.5 7.5-7.5m-6 15L5.25 12l7.5-7.5" />
        </svg>
      </button>
    </div>
  </aside>
</template>

<script setup>
import { computed, h } from 'vue';
import { useRoute } from 'vue-router';
import { useFleetLayout } from '@/composables/useFleetLayout.js';
import { useAuth } from '@/composables/useAuth.js';

const route = useRoute();
const { closeMobile, isMobileOpen, isDesktopCollapsed, toggleDesktopCollapsed } = useFleetLayout();
const { isAdmin } = useAuth();

const IconDashboard = {
  render() {
    return h(
      'svg',
      { fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', 'stroke-width': '1.75', 'aria-hidden': 'true' },
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
      { fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', 'stroke-width': '1.75', 'aria-hidden': 'true' },
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
      { fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', 'stroke-width': '1.75', 'aria-hidden': 'true' },
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
      { fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', 'stroke-width': '1.75', 'aria-hidden': 'true' },
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
      { fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', 'stroke-width': '1.75', 'aria-hidden': 'true' },
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

const IconCalendar = {
  render() {
    return h(
      'svg',
      { fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', 'stroke-width': '1.75', 'aria-hidden': 'true' },
      [
        h('path', {
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
          d: 'M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5',
        }),
      ],
    );
  },
};

const items = [
  { label: 'Dashboard', to: '/dashboard', icon: IconDashboard },
  { label: 'Asignaciones', to: '/asignaciones', icon: IconCalendar },
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
