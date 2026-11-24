<template>
  <AdminLayout header-title="Bitácora del sistema" :user-name="currentUser?.name" @logout="logout(true)">
    <PageBreadcrumb
      page-title="Bitácora del sistema"
      subtitle="Registro de auditoría de todos los movimientos, asignaciones, emergencias y cambios realizados."
    />

    <ComponentCard title="Historial de auditoría" desc="Visible únicamente para administradores y jefes de motoristas.">
      <template #header-extra>
        <span class="rounded-lg bg-gray-100 px-2.5 py-1 text-theme-xs font-semibold tabular-nums text-gray-600 dark:bg-gray-800 dark:text-gray-300">
          {{ meta.total }} {{ meta.total === 1 ? 'evento' : 'eventos' }}
        </span>
      </template>

      <div class="fleet-filter-bar grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-5">
        <div>
          <label for="syslog-search" class="fleet-label">Buscar</label>
          <input
            id="syslog-search"
            v-model="searchQuery"
            type="text"
            placeholder="Usuario, placa o detalle…"
            class="fleet-input"
            @keyup.enter="loadLogs(1)"
          />
        </div>
        <div>
          <label for="syslog-module" class="fleet-label">Módulo</label>
          <select id="syslog-module" v-model="filterModule" class="fleet-select" @change="loadLogs(1)">
            <option value="">Todos</option>
            <option value="assignments">Asignaciones</option>
            <option value="bitacoras">Bitácora</option>
            <option value="vehicles">Vehículos</option>
            <option value="incidents">Incidencias</option>
            <option value="users">Usuarios</option>
            <option value="auth">Acceso</option>
          </select>
        </div>
        <div>
          <label for="syslog-action" class="fleet-label">Acción</label>
          <select id="syslog-action" v-model="filterAction" class="fleet-select" @change="loadLogs(1)">
            <option value="">Todas</option>
            <option value="created">Creación</option>
            <option value="updated">Edición</option>
            <option value="deleted">Eliminación</option>
            <option value="emergency_reassigned">Emergencia</option>
            <option value="personal_trip">Viaje personal</option>
            <option value="unplanned_trip">Imprevisto</option>
            <option value="login">Ingreso</option>
          </select>
        </div>
        <div>
          <label for="syslog-from" class="fleet-label">Desde</label>
          <input id="syslog-from" v-model="filterFrom" type="date" class="fleet-input" @change="loadLogs(1)" />
        </div>
        <div>
          <label for="syslog-to" class="fleet-label">Hasta</label>
          <input id="syslog-to" v-model="filterTo" type="date" class="fleet-input" @change="loadLogs(1)" />
        </div>

        <div class="flex flex-wrap items-center gap-2 sm:col-span-2 lg:col-span-5">
          <button type="button" class="fleet-btn-secondary h-9 px-3.5 py-1.5 text-theme-xs" @click="loadLogs(1)">
            Buscar
          </button>
          <button
            v-if="hasFilters"
            type="button"
            class="fleet-btn-secondary h-9 px-3.5 py-1.5 text-theme-xs"
            @click="resetFilters"
          >
            Limpiar filtros
          </button>
        </div>
      </div>

      <div class="fleet-table-wrap">
        <div class="max-w-full overflow-x-auto">
          <table class="w-full divide-y divide-gray-200 dark:divide-gray-800">
            <thead>
              <tr>
                <th scope="col" class="fleet-th">Fecha y hora</th>
                <th scope="col" class="fleet-th">Usuario</th>
                <th scope="col" class="fleet-th">Módulo</th>
                <th scope="col" class="fleet-th">Acción</th>
                <th scope="col" class="fleet-th">Descripción</th>
                <th scope="col" class="fleet-th text-right">Detalle</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
              <tr v-if="loading" v-for="n in 6" :key="`sk-${n}`" class="animate-pulse">
                <td v-for="c in 6" :key="c" class="fleet-td">
                  <div class="h-4 w-full max-w-[120px] rounded bg-gray-200 dark:bg-gray-800" />
                </td>
              </tr>

              <tr v-else-if="logs.length === 0">
                <td colspan="6" class="p-0">
                  <TableEmptyState
                    icon="clipboard"
                    :has-filters="hasFilters"
                    title="Sin eventos registrados"
                    description="Las acciones importantes del sistema aparecerán aquí cronológicamente."
                    @reset="resetFilters"
                  />
                </td>
              </tr>

              <tr v-for="log in logs" v-else :key="log.id" class="fleet-tr">
                <td class="fleet-td whitespace-nowrap text-theme-xs tabular-nums">
                  {{ formatDateTime(log.created_at) }}
                </td>
                <td class="fleet-td whitespace-nowrap">
                  <p class="font-medium text-gray-900 dark:text-white">{{ log.user_name || 'Sistema' }}</p>
                  <p v-if="log.user_role" class="text-[11px] capitalize text-gray-500 dark:text-gray-400">
                    {{ log.user_role === 'despachador' ? 'Jefe de motoristas' : log.user_role }}
                  </p>
                </td>
                <td class="fleet-td whitespace-nowrap">
                  <StatusBadge kind="logModule" :value="log.module" />
                </td>
                <td class="fleet-td whitespace-nowrap">
                  <StatusBadge kind="logAction" :value="log.action" />
                </td>
                <td class="fleet-td max-w-[320px] text-theme-sm text-gray-700 dark:text-gray-200">
                  <p class="line-clamp-2" :title="log.summary">{{ log.summary }}</p>
                </td>
                <td class="fleet-td whitespace-nowrap text-right">
                  <TableRowActions
                    :group-label="`Detalle evento ${log.id}`"
                    :show-edit="false"
                    :show-delete="false"
                    @view="openView(log)"
                  />
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <TablePagination
          :current-page="meta.current_page"
          :last-page="meta.last_page"
          :total="meta.total"
          :from="meta.from"
          :to="meta.to"
          @change="changePage"
        />
      </div>
    </ComponentCard>

    <BaseModal
      :open="detailOpen"
      title="Detalle de evento del sistema"
      :subtitle="detailItem ? formatDateTime(detailItem.created_at) : ''"
      @close="detailOpen = false"
    >
      <div v-if="detailItem" class="space-y-4">
        <div class="flex flex-wrap items-center gap-2 rounded-xl border border-gray-200/80 bg-gray-50/80 p-3.5 dark:border-white/[0.07] dark:bg-white/[0.02]">
          <StatusBadge kind="logModule" :value="detailItem.module" />
          <StatusBadge kind="logAction" :value="detailItem.action" />
          <span v-if="detailItem.ip_address" class="ml-auto font-mono text-[11px] text-gray-500 dark:text-gray-400">
            IP: {{ detailItem.ip_address }}
          </span>
        </div>

        <dl class="grid grid-cols-1 gap-3 text-theme-sm sm:grid-cols-2">
          <div class="rounded-xl border border-gray-100 p-3 dark:border-white/[0.07]">
            <dt class="text-theme-xs text-gray-500 dark:text-gray-400">Usuario</dt>
            <dd class="mt-0.5 font-medium text-gray-900 dark:text-white">{{ detailItem.user_name || 'Sistema' }}</dd>
          </div>
          <div class="rounded-xl border border-gray-100 p-3 dark:border-white/[0.07]">
            <dt class="text-theme-xs text-gray-500 dark:text-gray-400">Rol</dt>
            <dd class="mt-0.5 font-medium capitalize text-gray-900 dark:text-white">
              {{ detailItem.user_role === 'despachador' ? 'Jefe de motoristas' : (detailItem.user_role || '—') }}
            </dd>
          </div>
        </dl>

        <div class="rounded-xl border border-gray-100 p-3.5 text-theme-sm dark:border-white/[0.07]">
          <p class="text-theme-xs font-medium text-gray-500 dark:text-gray-400">Resumen del evento</p>
          <p class="mt-1 text-gray-900 dark:text-white">{{ detailItem.summary }}</p>
        </div>

        <div v-if="detailItem.metadata" class="rounded-xl border border-gray-100 p-3.5 dark:border-white/[0.07]">
          <p class="text-theme-xs font-medium text-gray-500 dark:text-gray-400">Datos registrados</p>
          <pre class="mt-2 overflow-x-auto rounded-lg bg-gray-950 p-3 text-xs text-slate-200">{{ JSON.stringify(detailItem.metadata, null, 2) }}</pre>
        </div>
      </div>

      <template #footer>
        <button type="button" class="fleet-btn-primary" @click="detailOpen = false">Cerrar</button>
      </template>
    </BaseModal>
  </AdminLayout>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import AdminLayout from '@/components/layout/AdminLayout.vue';
import BaseModal from '@/components/common/BaseModal.vue';
import ComponentCard from '@/components/common/ComponentCard.vue';
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue';
import StatusBadge from '@/components/common/StatusBadge.vue';
import TableEmptyState from '@/components/common/TableEmptyState.vue';
import TablePagination from '@/components/common/TablePagination.vue';
import TableRowActions from '@/components/common/TableRowActions.vue';
import { useAuth } from '../composables/useAuth';

const { currentUser, loadMe, logout } = useAuth();

const logs = ref([]);
const loading = ref(true);
const meta = ref({ current_page: 1, last_page: 1, total: 0, from: 0, to: 0 });
const searchQuery = ref('');
const filterModule = ref('');
const filterAction = ref('');
const filterFrom = ref('');
const filterTo = ref('');
const detailOpen = ref(false);
const detailItem = ref(null);

const hasFilters = computed(() =>
  Boolean(searchQuery.value.trim() || filterModule.value || filterAction.value || filterFrom.value || filterTo.value),
);

const formatDateTime = (iso) => {
  if (!iso) return '';
  return new Date(iso).toLocaleString('es-HN', { dateStyle: 'short', timeStyle: 'medium' });
};

const loadLogs = async (page = 1) => {
  loading.value = true;
  try {
    const params = { page, per_page: 25 };
    if (searchQuery.value.trim()) params.search = searchQuery.value.trim();
    if (filterModule.value) params.module = filterModule.value;
    if (filterAction.value) params.action = filterAction.value;
    if (filterFrom.value) params.date_from = filterFrom.value;
    if (filterTo.value) params.date_to = filterTo.value;

    const { data } = await window.axios.get('/system-logs', { params });
    logs.value = data.data || [];
    meta.value = {
      current_page: data.current_page ?? 1,
      last_page: data.last_page ?? 1,
      total: data.total ?? logs.value.length,
      from: data.from ?? 0,
      to: data.to ?? 0,
    };
  } catch (_) {
    /* manejado */
  } finally {
    loading.value = false;
  }
};

const resetFilters = () => {
  searchQuery.value = '';
  filterModule.value = '';
  filterAction.value = '';
  filterFrom.value = '';
  filterTo.value = '';
  loadLogs(1);
};

const changePage = (page) => {
  if (page < 1 || page > meta.value.last_page) return;
  loadLogs(page);
};

const openView = (log) => {
  detailItem.value = log;
  detailOpen.value = true;
};

onMounted(async () => {
  await loadMe();
  await loadLogs(1);
});
</script>
