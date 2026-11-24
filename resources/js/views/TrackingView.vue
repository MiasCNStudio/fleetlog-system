<template>
  <AdminLayout header-title="Rastreo GPS" :user-name="currentUser?.name" @logout="logout(true)">
    <PageBreadcrumb
      page-title="Rastreo GPS y rutas"
      subtitle="Monitoreo de misiones en tiempo real, dispositivo vinculado y resumen final en mapa."
    >
      <template #actions>
        <button type="button" class="fleet-btn-secondary" :disabled="loadingActive" @click="refreshAll">
          {{ loadingActive ? 'Actualizando…' : 'Actualizar ahora' }}
        </button>
      </template>
    </PageBreadcrumb>

    <div class="space-y-6">
      <!-- Misiones activas en tiempo real -->
      <ComponentCard
        title="Misiones activas en ruta"
        desc="Unidades transmitiendo ubicación desde el celular que inició la salida."
      >
        <template #header-extra>
          <span class="rounded-lg bg-emerald-500/15 px-2.5 py-1 text-theme-xs font-semibold tabular-nums text-emerald-700 dark:text-emerald-300">
            {{ activeSessions.length }} {{ activeSessions.length === 1 ? 'activa' : 'activas' }}
          </span>
        </template>

        <div v-if="activeSessions.length === 0" class="rounded-xl border border-dashed border-gray-200 px-4 py-8 text-center text-theme-sm text-gray-500 dark:border-gray-800 dark:text-gray-400">
          No hay unidades con misión activa en este momento.
        </div>

        <div v-else class="grid grid-cols-1 gap-4 lg:grid-cols-12">
          <div class="overflow-hidden rounded-xl border border-gray-200 dark:border-white/10 lg:col-span-7">
            <div class="flex items-center justify-between border-b border-gray-100 bg-gray-50/80 px-3.5 py-2 text-[11px] text-gray-500 dark:border-white/[0.06] dark:bg-white/[0.02] dark:text-gray-400">
              <span>Última ubicación reportada de unidades en curso</span>
              <span class="font-semibold uppercase text-brand-600 dark:text-brand-400">
                {{ usingGoogleLive ? 'Google Maps' : 'Mapa en vivo' }}
              </span>
            </div>
            <div ref="liveMapEl" class="h-64 w-full bg-slate-100 dark:bg-slate-900 sm:h-72" />
          </div>

          <div class="space-y-3 lg:col-span-5">
            <div
              v-for="s in activeSessions"
              :key="s.id"
              :class="[
                'rounded-xl border p-3.5 transition-colors',
                s.has_sos_alert
                  ? 'border-rose-300 bg-rose-50/70 dark:border-rose-500/40 dark:bg-rose-500/10'
                  : 'border-gray-200 bg-white dark:border-white/[0.08] dark:bg-white/[0.02]',
              ]"
            >
              <div class="flex items-start justify-between gap-2">
                <div class="min-w-0">
                  <div class="flex flex-wrap items-center gap-1.5">
                    <span class="fleet-plate">{{ s.vehicle?.license_plate }}</span>
                    <StatusBadge v-if="s.has_sos_alert" kind="logAction" value="sos_alert" />
                    <StatusBadge v-else kind="trackingStatus" :value="s.status" />
                  </div>
                  <p class="mt-1 truncate text-theme-sm font-semibold text-gray-900 dark:text-white">
                    {{ s.driver?.name || '—' }}
                  </p>
                  <p class="truncate text-theme-xs text-gray-500 dark:text-gray-400">
                    Destino: {{ s.salida_bitacora?.destination || 'Sin destino' }}
                  </p>
                </div>
                <div class="text-right text-[11px] text-gray-500 dark:text-gray-400">
                  <p class="font-semibold text-gray-800 dark:text-gray-200">{{ s.gps_distance_km }} km</p>
                  <p v-if="s.last_battery_level !== null">Bat: {{ s.last_battery_level }}%</p>
                </div>
              </div>

              <div class="mt-2 rounded-lg bg-gray-50 px-2.5 py-1.5 text-[11px] text-gray-600 dark:bg-white/[0.03] dark:text-gray-300">
                <p class="truncate"><span class="font-semibold">Celular:</span> {{ s.device_name }}</p>
                <p class="truncate font-mono text-[10px] text-gray-400">{{ s.device_uuid }}</p>
                <p class="mt-0.5 text-gray-500">
                  Último ping: {{ s.last_ping_at ? formatDateTime(s.last_ping_at) : 'Esperando GPS' }}
                </p>
              </div>

              <div class="mt-3 flex flex-wrap gap-2">
                <button
                  type="button"
                  class="fleet-btn-primary h-8 px-3 py-1 text-theme-xs"
                  @click="openSessionModal(s.id)"
                >
                  Ver recorrido
                </button>
                <a
                  v-if="s.last_latitude && s.last_longitude"
                  :href="`https://www.google.com/maps/search/?api=1&query=${s.last_latitude},${s.last_longitude}`"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="fleet-btn-secondary h-8 px-3 py-1 text-theme-xs"
                >
                  Google Maps ↗
                </a>
              </div>
            </div>
          </div>
        </div>
      </ComponentCard>

      <!-- Historial de recorridos -->
      <ComponentCard
        title="Historial de misiones y rutas"
        desc="Resumen final de kilometraje, paradas, dispositivos y cronología."
      >
        <template #header-extra>
          <span class="rounded-lg bg-gray-100 px-2.5 py-1 text-theme-xs font-semibold tabular-nums text-gray-600 dark:bg-gray-800 dark:text-gray-300">
            {{ meta.total }} {{ meta.total === 1 ? 'misión' : 'misiones' }}
          </span>
        </template>

        <div class="fleet-filter-bar flex flex-wrap items-center justify-between gap-2.5">
          <div class="flex flex-wrap items-center gap-2">
            <select v-model="filters.status" class="fleet-select h-9 w-auto text-theme-xs" @change="loadSessions(1)">
              <option value="">Todos los estados</option>
              <option value="activa">En misión</option>
              <option value="finalizada">Finalizada</option>
              <option value="interrumpida">Interrumpida</option>
            </select>
            <button type="button" class="fleet-btn-secondary h-9 gap-1.5 px-3 py-1.5 text-theme-xs" @click="filterModalOpen = true">
              Filtros
              <span
                v-if="activeFilterCount > 0"
                class="inline-flex size-4 items-center justify-center rounded-full bg-brand-500 text-[10px] font-bold text-white"
              >
                {{ activeFilterCount }}
              </span>
            </button>
          </div>
        </div>

        <!-- Móvil: tarjetas compactas -->
        <div class="space-y-3 md:hidden">
          <div v-if="loadingList" v-for="n in 3" :key="`ms-${n}`" class="h-28 animate-pulse rounded-xl bg-gray-100 dark:bg-gray-800" />
          <div
            v-else-if="sessions.length === 0"
            class="rounded-xl border border-dashed border-gray-200 px-4 py-8 text-center text-theme-xs text-gray-500 dark:border-gray-800 dark:text-gray-400"
          >
            No hay sesiones de rastreo con esos filtros.
          </div>
          <div
            v-else
            v-for="s in sessions"
            :key="`m-${s.id}`"
            class="rounded-xl border border-gray-200 bg-white p-3.5 dark:border-white/[0.08] dark:bg-white/[0.02]"
          >
            <div class="flex items-start justify-between gap-2">
              <div class="min-w-0">
                <div class="flex flex-wrap items-center gap-1.5">
                  <span class="fleet-plate">{{ s.vehicle?.license_plate }}</span>
                  <StatusBadge kind="trackingStatus" :value="s.status" />
                  <StatusBadge v-if="s.has_sos_alert" kind="logAction" value="sos_alert" />
                </div>
                <p class="mt-1 truncate text-theme-sm font-semibold text-gray-900 dark:text-white">
                  {{ s.driver?.name || '—' }}
                </p>
                <p class="truncate text-theme-xs text-gray-500 dark:text-gray-400">
                  {{ s.salida_bitacora?.destination || 'Sin destino' }}
                </p>
              </div>
              <button
                type="button"
                class="fleet-btn-secondary h-8 shrink-0 px-2.5 py-1 text-theme-xs"
                @click="openSessionModal(s.id)"
              >
                Ver ruta
              </button>
            </div>
            <div class="mt-2 flex flex-wrap items-center justify-between gap-2 border-t border-gray-100 pt-2 text-[11px] text-gray-500 dark:border-white/[0.06] dark:text-gray-400">
              <span>{{ formatDateTime(s.started_at) }}</span>
              <span class="font-medium text-gray-700 dark:text-gray-200">{{ s.gps_distance_km }} km · {{ s.points_count }} pts</span>
            </div>
          </div>
        </div>

        <!-- Desktop: tabla -->
        <div class="fleet-table-wrap hidden md:block">
          <div class="max-w-full overflow-x-auto">
            <table class="w-full divide-y divide-gray-200 dark:divide-gray-800">
              <thead>
                <tr>
                  <th scope="col" class="fleet-th">Inicio</th>
                  <th scope="col" class="fleet-th">Unidad y destino</th>
                  <th scope="col" class="fleet-th">Conductor / Celular</th>
                  <th scope="col" class="fleet-th">Métricas GPS</th>
                  <th scope="col" class="fleet-th">Estado</th>
                  <th scope="col" class="fleet-th text-right">Resumen</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
                <tr v-if="loadingList" v-for="n in 4" :key="`dk-${n}`" class="animate-pulse">
                  <td v-for="c in 6" :key="c" class="fleet-td"><div class="h-4 w-24 rounded bg-gray-200 dark:bg-gray-800" /></td>
                </tr>
                <tr v-else-if="sessions.length === 0">
                  <td colspan="6" class="px-4 py-10 text-center text-theme-sm text-gray-500 dark:text-gray-400">
                    No hay misiones rastreadas que coincidan con los filtros.
                  </td>
                </tr>
                <tr v-else v-for="s in sessions" :key="s.id" class="fleet-tr-hover">
                  <td class="fleet-td whitespace-nowrap text-theme-xs text-gray-600 dark:text-gray-300">
                    <div>{{ formatDateTime(s.started_at) }}</div>
                    <div v-if="s.ended_at" class="text-[11px] text-gray-400">Fin: {{ formatDateTime(s.ended_at) }}</div>
                  </td>
                  <td class="fleet-td">
                    <span class="fleet-plate">{{ s.vehicle?.license_plate }}</span>
                    <p class="mt-1 max-w-xs truncate text-theme-xs text-gray-700 dark:text-gray-200">
                      {{ s.salida_bitacora?.destination || 'Sin destino' }}
                    </p>
                  </td>
                  <td class="fleet-td">
                    <div class="font-medium text-gray-900 dark:text-white">{{ s.driver?.name || '—' }}</div>
                    <div class="text-theme-xs text-gray-500 dark:text-gray-400">{{ s.device_name }}</div>
                    <div class="max-w-[190px] truncate font-mono text-[10px] text-gray-400" :title="s.device_uuid">
                      {{ s.device_uuid }}
                    </div>
                  </td>
                  <td class="fleet-td whitespace-nowrap text-theme-xs">
                    <div class="font-semibold text-gray-800 dark:text-gray-200">{{ s.gps_distance_km }} km GPS</div>
                    <div class="text-gray-500 dark:text-gray-400">
                      {{ s.points_count }} pts · {{ s.stops_count }} paradas
                    </div>
                  </td>
                  <td class="fleet-td whitespace-nowrap">
                    <div class="flex flex-col items-start gap-1">
                      <StatusBadge kind="trackingStatus" :value="s.status" />
                      <StatusBadge v-if="s.has_sos_alert" kind="logAction" value="sos_alert" />
                    </div>
                  </td>
                  <td class="fleet-td whitespace-nowrap text-right">
                    <button
                      type="button"
                      class="fleet-btn-secondary h-8 px-3 py-1 text-theme-xs"
                      @click="openSessionModal(s.id)"
                    >
                      Ver ruta y resumen
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <TablePagination
          :current-page="meta.current_page"
          :last-page="meta.last_page"
          :total="meta.total"
          :from="meta.from"
          :to="meta.to"
          @change="loadSessions"
        />
      </ComponentCard>
    </div>

    <!-- Modal de filtros -->
    <BaseModal
      :open="filterModalOpen"
      title="Filtrar misiones rastreadas"
      subtitle="Filtra por vehículo, motorista, fechas o alertas de emergencia."
      @close="filterModalOpen = false"
    >
      <div class="grid grid-cols-1 gap-3.5 sm:grid-cols-2">
        <div>
          <label for="tr-from" class="fleet-label">Desde</label>
          <input id="tr-from" v-model="filters.date_from" type="date" class="fleet-input" />
        </div>
        <div>
          <label for="tr-to" class="fleet-label">Hasta</label>
          <input id="tr-to" v-model="filters.date_to" type="date" class="fleet-input" />
        </div>
        <div>
          <label for="tr-driver" class="fleet-label">Motorista</label>
          <select id="tr-driver" v-model="filters.driver_id" class="fleet-select">
            <option value="">Todos los motoristas</option>
            <option v-for="d in drivers" :key="d.id" :value="String(d.id)">{{ d.name }}</option>
          </select>
        </div>
        <div>
          <label for="tr-vehicle" class="fleet-label">Vehículo</label>
          <select id="tr-vehicle" v-model="filters.vehicle_id" class="fleet-select">
            <option value="">Todos los vehículos</option>
            <option v-for="v in vehicles" :key="v.id" :value="String(v.id)">{{ v.license_plate }} · {{ v.brand }}</option>
          </select>
        </div>
        <div class="sm:col-span-2">
          <label class="flex items-center gap-2.5 rounded-xl border border-gray-200 px-3.5 py-2.5 text-theme-sm text-gray-700 dark:border-gray-700 dark:text-gray-200">
            <input v-model="filters.sos_only" type="checkbox" class="size-4 rounded border-gray-300 text-brand-600 focus:ring-brand-500" />
            Mostrar solo misiones con alerta SOS
          </label>
        </div>
      </div>

      <template #footer>
        <button type="button" class="fleet-btn-secondary" @click="resetFilters">Limpiar todo</button>
        <button type="button" class="fleet-btn-primary" @click="applyFilters">Aplicar filtros</button>
      </template>
    </BaseModal>

    <TripRouteMapModal
      :open="routeModalOpen"
      :session-id="selectedSessionId"
      @close="routeModalOpen = false"
    />
  </AdminLayout>
</template>

<script setup>
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { computed, nextTick, onBeforeUnmount, onMounted, reactive, ref } from 'vue';
import AdminLayout from '@/components/layout/AdminLayout.vue';
import BaseModal from '@/components/common/BaseModal.vue';
import ComponentCard from '@/components/common/ComponentCard.vue';
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue';
import StatusBadge from '@/components/common/StatusBadge.vue';
import TablePagination from '@/components/common/TablePagination.vue';
import TripRouteMapModal from '@/components/common/TripRouteMapModal.vue';
import { useAuth } from '@/composables/useAuth.js';

const { currentUser, logout } = useAuth();

const activeSessions = ref([]);
const loadingActive = ref(false);
const sessions = ref([]);
const loadingList = ref(false);
const drivers = ref([]);
const vehicles = ref([]);

const filterModalOpen = ref(false);
const routeModalOpen = ref(false);
const selectedSessionId = ref(null);
const liveMapEl = ref(null);
const usingGoogleLive = ref(false);

let liveLeafletMap = null;
let liveGoogleMap = null;
let liveGoogleOverlays = [];
let pollInterval = null;

const filters = reactive({
  status: '',
  vehicle_id: '',
  driver_id: '',
  date_from: '',
  date_to: '',
  sos_only: false,
});

const meta = reactive({
  current_page: 1,
  last_page: 1,
  total: 0,
  from: 0,
  to: 0,
});

const activeFilterCount = computed(() => {
  let count = 0;
  if (filters.vehicle_id) count++;
  if (filters.driver_id) count++;
  if (filters.date_from) count++;
  if (filters.date_to) count++;
  if (filters.sos_only) count++;
  return count;
});

const formatDateTime = (val) => {
  if (!val) return '—';
  const d = new Date(val);
  return Number.isNaN(d.getTime())
    ? String(val)
    : d.toLocaleString('es-SV', { dateStyle: 'short', timeStyle: 'short' });
};

const openSessionModal = (id) => {
  selectedSessionId.value = id;
  routeModalOpen.value = true;
};

const destroyLiveMap = () => {
  if (liveLeafletMap) {
    liveLeafletMap.remove();
    liveLeafletMap = null;
  }
  if (liveGoogleOverlays.length > 0) {
    liveGoogleOverlays.forEach((o) => o?.setMap?.(null));
    liveGoogleOverlays = [];
  }
  liveGoogleMap = null;
};

const renderLiveMap = async () => {
  await nextTick();
  if (!liveMapEl.value) return;

  const positioned = activeSessions.value.filter(
    (s) => Number.isFinite(Number(s.last_latitude)) && Number.isFinite(Number(s.last_longitude)),
  );

  destroyLiveMap();

  const defaultCenter = [13.6978, -89.1914];
  const centerLatLng = positioned.length > 0
    ? [Number(positioned[0].last_latitude), Number(positioned[0].last_longitude)]
    : defaultCenter;

  liveLeafletMap = L.map(liveMapEl.value, { center: centerLatLng, zoom: positioned.length > 0 ? 13 : 11 });
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap',
    maxZoom: 19,
  }).addTo(liveLeafletMap);

  const bounds = [];

  positioned.forEach((s) => {
    const trail = (s.recent_trail || []).map((pt) => [Number(pt.latitude), Number(pt.longitude)]);
    if (trail.length > 1) {
      L.polyline(trail, { color: s.has_sos_alert ? '#e11d48' : '#465fff', weight: 3.5, opacity: 0.8 }).addTo(liveLeafletMap);
      trail.forEach((p) => bounds.push(p));
    }
    const pos = [Number(s.last_latitude), Number(s.last_longitude)];
    bounds.push(pos);

    const icon = L.divIcon({
      className: 'fleetlog-live-unit',
      html: `<div style="padding:3px 7px;border-radius:9999px;background:${s.has_sos_alert ? '#e11d48' : '#465fff'};border:2px solid #fff;color:#fff;font-size:10px;font-weight:700;white-space:nowrap;box-shadow:0 3px 10px rgba(15,23,42,0.35);">${s.vehicle?.license_plate || 'Unidad'}</div>`,
    });

    L.marker(pos, { icon })
      .bindPopup(`<strong>${s.vehicle?.license_plate}</strong><br>${s.driver?.name || ''}<br>Cel: ${s.device_name}`)
      .addTo(liveLeafletMap);
  });

  if (bounds.length > 1) {
    liveLeafletMap.fitBounds(bounds, { padding: [30, 30] });
  }
  setTimeout(() => liveLeafletMap?.invalidateSize(), 180);
};

const loadActive = async () => {
  loadingActive.value = true;
  try {
    const { data } = await window.axios.get('/tracking/sessions/active');
    activeSessions.value = data.data || [];
    await renderLiveMap();
  } finally {
    loadingActive.value = false;
  }
};

const loadSessions = async (page = 1) => {
  loadingList.value = true;
  try {
    const { data } = await window.axios.get('/tracking/sessions', {
      params: {
        page,
        status: filters.status || undefined,
        vehicle_id: filters.vehicle_id || undefined,
        driver_id: filters.driver_id || undefined,
        date_from: filters.date_from || undefined,
        date_to: filters.date_to || undefined,
        sos_only: filters.sos_only ? 1 : undefined,
      },
    });
    sessions.value = data.data || [];
    meta.current_page = data.current_page || 1;
    meta.last_page = data.last_page || 1;
    meta.total = data.total || 0;
    meta.from = data.from || 0;
    meta.to = data.to || 0;
  } finally {
    loadingList.value = false;
  }
};

const loadOptions = async () => {
  const [vRes, dRes] = await Promise.all([
    window.axios.get('/vehicles/options'),
    window.axios.get('/drivers/options'),
  ]);
  vehicles.value = vRes.data.data || [];
  drivers.value = dRes.data.data || [];
};

const applyFilters = () => {
  filterModalOpen.value = false;
  loadSessions(1);
};

const resetFilters = () => {
  filters.vehicle_id = '';
  filters.driver_id = '';
  filters.date_from = '';
  filters.date_to = '';
  filters.sos_only = false;
  filterModalOpen.value = false;
  loadSessions(1);
};

const refreshAll = async () => {
  await Promise.all([loadActive(), loadSessions(meta.current_page)]);
};

onMounted(async () => {
  await Promise.all([loadOptions(), refreshAll()]);
  pollInterval = setInterval(() => {
    loadActive();
  }, 15000);
});

onBeforeUnmount(() => {
  if (pollInterval) clearInterval(pollInterval);
  destroyLiveMap();
});
</script>
