<template>
  <AdminLayout header-title="Dashboard" :user-name="currentUser?.name" @logout="logout(true)">
    <PageBreadcrumb page-title="Dashboard Fleetlog" subtitle="Resumen operativo en tiempo real de la flota" />

    <section class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
      <article
        v-for="card in cards"
        :key="card.label"
        class="rounded-2xl border border-gray-200 bg-white p-5 shadow-theme-md dark:border-gray-800 dark:bg-white/[0.03]"
      >
        <p class="text-theme-sm text-gray-500 dark:text-gray-400">{{ card.label }}</p>
        <p class="mt-1 text-2xl font-semibold text-gray-900 dark:text-white">{{ card.value }}</p>
        <p v-if="card.hint" class="mt-1 text-theme-xs text-gray-400">{{ card.hint }}</p>
      </article>
    </section>

    <section class="mt-6 grid grid-cols-1 gap-4 lg:grid-cols-3">
      <div class="rounded-2xl border border-gray-200 bg-white p-5 shadow-theme-md dark:border-gray-800 dark:bg-white/[0.03] lg:col-span-2">
        <div class="mb-3 flex flex-wrap items-center justify-between gap-2">
          <h2 class="font-semibold text-gray-900 dark:text-white">Movimientos de flota</h2>
          <select
            v-model.number="daysFilter"
            class="rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            @change="loadData"
          >
            <option :value="7">Últimos 7 días</option>
            <option :value="30">Últimos 30 días</option>
          </select>
        </div>
        <div ref="chartEl" class="h-80" />
      </div>

      <div class="rounded-2xl border border-gray-200 bg-white p-5 shadow-theme-md dark:border-gray-800 dark:bg-white/[0.03]">
        <h2 class="mb-3 font-semibold text-gray-900 dark:text-white">Control rápido</h2>
        <div class="space-y-3 text-theme-sm">
          <p class="text-gray-600 dark:text-gray-300">
            <span class="font-medium text-gray-800 dark:text-white">Usuario:</span>
            {{ currentUser?.name || '—' }}
          </p>
          <p class="text-gray-600 dark:text-gray-300">
            <span class="font-medium text-gray-800 dark:text-white">Rol:</span>
            <span class="capitalize">{{ currentUser?.role || '—' }}</span>
          </p>
          <p class="text-gray-500">Hora actual: {{ nowLabel }}</p>
        </div>

        <div class="mt-5 flex flex-wrap gap-2">
          <router-link
            to="/bitacora"
            class="rounded-lg bg-brand-500 px-3 py-2 text-theme-sm font-medium text-white hover:bg-brand-600"
          >
            Registrar movimiento
          </router-link>
          <router-link
            to="/incidencias"
            class="rounded-lg border border-gray-200 px-3 py-2 text-theme-sm text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-200 dark:hover:bg-white/5"
          >
            Reportar incidencia
          </router-link>
          <button
            type="button"
            class="rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:text-gray-200"
            @click="toggleDark()"
          >
            {{ isDark ? 'Modo claro' : 'Modo oscuro' }}
          </button>
        </div>
      </div>
    </section>

    <section class="mt-6 grid grid-cols-1 gap-4 lg:grid-cols-2">
      <div class="rounded-2xl border border-gray-200 bg-white p-5 shadow-theme-md dark:border-gray-800 dark:bg-white/[0.03]">
        <div class="mb-3 flex items-center justify-between">
          <h2 class="font-semibold text-gray-900 dark:text-white">Unidades en ruta ahora</h2>
          <router-link to="/bitacora" class="text-theme-xs font-medium text-brand-500 hover:underline">
            Ver bitácora
          </router-link>
        </div>
        <div v-if="activeTrips.length === 0" class="py-6 text-center text-theme-sm text-gray-400">
          Todas las unidades están en base.
        </div>
        <ul v-else class="divide-y divide-gray-100 dark:divide-gray-800">
          <li v-for="t in activeTrips" :key="t.vehicle_id" class="flex items-start justify-between gap-3 py-3">
            <div>
              <p class="font-medium text-gray-900 text-theme-sm dark:text-white">
                {{ t.license_plate }} · {{ t.brand }} {{ t.model }}
              </p>
              <p class="text-theme-xs text-gray-500 dark:text-gray-400">
                Conductor: {{ t.driver_name || '—' }} · Destino: {{ t.destination || '—' }}
              </p>
            </div>
            <span class="shrink-0 rounded-full bg-amber-500/15 px-2.5 py-0.5 text-theme-xs font-medium text-amber-700 dark:text-amber-300">
              En ruta
            </span>
          </li>
        </ul>
      </div>

      <div class="rounded-2xl border border-gray-200 bg-white p-5 shadow-theme-md dark:border-gray-800 dark:bg-white/[0.03]">
        <div class="mb-3 flex items-center justify-between">
          <h2 class="font-semibold text-gray-900 dark:text-white">Incidencias abiertas recientes</h2>
          <router-link to="/incidencias" class="text-theme-xs font-medium text-brand-500 hover:underline">
            Ver todas
          </router-link>
        </div>
        <div v-if="recentIncidents.length === 0" class="py-6 text-center text-theme-sm text-gray-400">
          Sin incidencias abiertas.
        </div>
        <ul v-else class="divide-y divide-gray-100 dark:divide-gray-800">
          <li v-for="inc in recentIncidents" :key="inc.id" class="flex items-start justify-between gap-3 py-3">
            <div>
              <p class="font-medium text-gray-900 text-theme-sm dark:text-white">
                {{ inc.title }}
              </p>
              <p class="text-theme-xs text-gray-500 dark:text-gray-400">
                {{ inc.vehicle?.license_plate }} · Reportó: {{ inc.reporter?.name || '—' }}
              </p>
            </div>
            <span class="shrink-0 rounded-full bg-rose-500/15 px-2.5 py-0.5 text-theme-xs font-medium uppercase text-rose-700 dark:text-rose-300">
              {{ inc.severity }}
            </span>
          </li>
        </ul>
      </div>
    </section>
  </AdminLayout>
</template>

<script setup>
import ApexCharts from 'apexcharts';
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import { useDark, useNow, useToggle } from '@vueuse/core';
import AdminLayout from '@/components/layout/AdminLayout.vue';
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue';
import { setCurrentUser, useAuth } from '../composables/useAuth';

const { currentUser, logout } = useAuth();

const chartEl = ref(null);
const cards = ref([]);
const activeTrips = ref([]);
const recentIncidents = ref([]);
const daysFilter = ref(7);

const now = useNow({ interval: 1000 });
const isDark = useDark();
const toggleDark = useToggle(isDark);
const nowLabel = computed(() => now.value.toLocaleTimeString());

let chartInstance = null;

const renderChart = (seriesData) => {
  if (!chartEl.value) return;
  const options = {
    chart: { type: 'bar', height: 300, toolbar: { show: false } },
    series: [
      { name: 'Salidas', data: seriesData.salidas || seriesData.values || [] },
      { name: 'Regresos', data: seriesData.regresos || [] },
    ],
    xaxis: { categories: seriesData.categories || [] },
    colors: ['#465fff', '#12b76a'],
    plotOptions: { bar: { borderRadius: 4, columnWidth: '55%' } },
    dataLabels: { enabled: false },
    legend: { position: 'top' },
  };

  if (chartInstance) {
    chartInstance.updateOptions(options);
  } else {
    chartInstance = new ApexCharts(chartEl.value, options);
    chartInstance.render();
  }
};

const loadData = async () => {
  const { data } = await window.axios.get('/dashboard', { params: { days: daysFilter.value } });
  const s = data.summary || {};

  cards.value = [
    { label: 'Viajes activos', value: s.viajes_activos ?? 0, hint: `Flota total: ${s.total_vehiculos ?? 0}` },
    { label: 'Unidades disponibles', value: s.unidades_disponibles ?? 0 },
    { label: 'Conductores en ruta', value: s.conductores_en_ruta ?? 0 },
    { label: 'Incidencias abiertas', value: s.incidencias_abiertas ?? 0, hint: `Hoy: ${s.incidencias_hoy ?? 0}` },
    { label: 'En mantenimiento', value: s.unidades_mantenimiento ?? 0 },
  ];

  activeTrips.value = data.active_trips || [];
  recentIncidents.value = data.recent_incidents || [];

  if (data.user) {
    setCurrentUser(data.user);
  }

  renderChart(data.series || {});
};

onMounted(async () => {
  await loadData();
});

onBeforeUnmount(() => {
  chartInstance?.destroy();
});
</script>
