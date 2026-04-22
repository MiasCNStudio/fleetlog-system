<template>
  <AdminLayout header-title="Dashboard" :user-name="user?.name" @logout="logout">
    <PageBreadcrumb page-title="Dashboard Fleetlog" subtitle="Resumen operativo de la flota" />

    <section class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <article
        v-for="card in cards"
        :key="card.label"
        class="rounded-2xl border border-gray-200 bg-white p-5 shadow-theme-md dark:border-gray-800 dark:bg-white/[0.03]"
      >
        <p class="text-theme-sm text-gray-500 dark:text-gray-400">{{ card.label }}</p>
        <p class="mt-1 text-2xl font-semibold text-gray-900 dark:text-white">{{ card.value }}</p>
      </article>
    </section>

    <section class="mt-6 grid grid-cols-1 gap-4 lg:grid-cols-3">
      <div class="rounded-2xl border border-gray-200 bg-white p-5 shadow-theme-md dark:border-gray-800 dark:bg-white/[0.03] lg:col-span-2">
        <h2 class="mb-3 font-semibold text-gray-900 dark:text-white">Viajes semanales</h2>
        <div ref="chartEl" class="h-80" />
      </div>

      <div class="rounded-2xl border border-gray-200 bg-white p-5 shadow-theme-md dark:border-gray-800 dark:bg-white/[0.03]">
        <h2 class="mb-3 font-semibold text-gray-900 dark:text-white">Filtros</h2>
        <select ref="fleetSelect" class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white">
          <option value="todos">Toda la flota</option>
          <option value="norte">Zona Norte</option>
          <option value="sur">Zona Sur</option>
        </select>
        <p class="mt-3 text-theme-sm text-gray-500">Hora actual: {{ nowLabel }}</p>
        <button
          type="button"
          class="mt-4 rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700"
          @click="toggleDark"
        >
          Alternar modo oscuro
        </button>
      </div>
    </section>
  </AdminLayout>
</template>

<script setup>
import ApexCharts from 'apexcharts';
import Swal from 'sweetalert2';
import TomSelect from 'tom-select';
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import { useDark, useNow, useToggle } from '@vueuse/core';
import { useRouter } from 'vue-router';
import AdminLayout from '@/components/layout/AdminLayout.vue';
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue';
import { setAuthToken } from '../bootstrap';

const router = useRouter();
const chartEl = ref(null);
const fleetSelect = ref(null);
const cards = ref([]);
const user = ref(null);
const now = useNow({ interval: 1000 });
const isDark = useDark();
const toggleDark = useToggle(isDark);
const nowLabel = computed(() => now.value.toLocaleTimeString());

let chartInstance = null;
let tomInstance = null;

const loadData = async () => {
  const { data } = await window.axios.get('/dashboard');
  cards.value = [
    { label: 'Viajes activos', value: data.summary.viajes_activos },
    { label: 'Unidades disponibles', value: data.summary.unidades_disponibles },
    { label: 'Conductores en ruta', value: data.summary.conductores_en_ruta },
    { label: 'Incidencias hoy', value: data.summary.incidencias_hoy },
  ];
  user.value = data.user;

  chartInstance = new ApexCharts(chartEl.value, {
    chart: { type: 'line', toolbar: { show: false } },
    series: [{ name: 'Viajes', data: data.series.values }],
    xaxis: { categories: data.series.categories },
    stroke: { curve: 'smooth' },
  });

  chartInstance.render();
};

const logout = async () => {
  try {
    await window.axios.post('/logout');
  } catch (_) {
    /* vacío */
  } finally {
    setAuthToken(null);
    await router.push({ name: 'login' });
    Swal.fire({ icon: 'success', title: 'Sesión cerrada', timer: 1200, showConfirmButton: false });
  }
};

onMounted(async () => {
  try {
    await loadData();
    tomInstance = new TomSelect(fleetSelect.value, { create: false, sortField: { field: 'text', direction: 'asc' } });
  } catch (error) {
    setAuthToken(null);
    await router.push({ name: 'login' });
  }
});

onBeforeUnmount(() => {
  chartInstance?.destroy();
  tomInstance?.destroy();
});
</script>
