<template>
  <AdminLayout header-title="Incidencias" :user-name="currentUser?.name" @logout="logout(true)">
    <PageBreadcrumb page-title="Incidencias" subtitle="Reportes de fallas, accidentes o novedades de las unidades.">
      <template #actions>
        <button type="button" class="fleet-btn-primary" @click="openCreate">
          <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
          </svg>
          Reportar incidencia
        </button>
      </template>
    </PageBreadcrumb>

    <ComponentCard title="Historial de incidencias" desc="Seguimiento por vehículo, severidad y estado.">
      <template #header-extra>
        <span class="rounded-lg bg-gray-100 px-2.5 py-1 text-theme-xs font-semibold tabular-nums text-gray-600 dark:bg-gray-800 dark:text-gray-300">
          {{ meta.total }} {{ meta.total === 1 ? 'incidencia' : 'incidencias' }}
        </span>
      </template>

      <div class="fleet-filter-bar grid grid-cols-1 gap-3 sm:flex sm:flex-wrap sm:items-end">
        <div class="w-full sm:w-64">
          <label for="incidents-filter-vehicle" class="fleet-label">Vehículo</label>
          <select
            id="incidents-filter-vehicle"
            v-model="filterVehicleId"
            class="fleet-select"
            @change="loadIncidents(1)"
          >
            <option value="">Todos los vehículos</option>
            <option v-for="v in vehicleOptions" :key="v.id" :value="String(v.id)">
              {{ v.license_plate }} — {{ v.brand }} {{ v.model }}
            </option>
          </select>
        </div>

        <div class="w-full sm:w-44">
          <label for="incidents-filter-status" class="fleet-label">Estado</label>
          <select
            id="incidents-filter-status"
            v-model="filterStatus"
            class="fleet-select"
            @change="loadIncidents(1)"
          >
            <option value="">Todos</option>
            <option value="abierta">Abierta</option>
            <option value="en_revision">En revisión</option>
            <option value="resuelta">Resuelta</option>
          </select>
        </div>

        <div class="w-full sm:w-44">
          <label for="incidents-filter-severity" class="fleet-label">Severidad</label>
          <select
            id="incidents-filter-severity"
            v-model="filterSeverity"
            class="fleet-select"
            @change="loadIncidents(1)"
          >
            <option value="">Todas</option>
            <option value="baja">Baja</option>
            <option value="media">Media</option>
            <option value="alta">Alta</option>
            <option value="critica">Crítica</option>
          </select>
        </div>

        <button
          v-if="hasFilters"
          type="button"
          class="fleet-btn-secondary h-10 px-3.5 text-theme-xs"
          @click="resetFilters"
        >
          Limpiar filtros
        </button>
      </div>

      <div class="fleet-table-wrap">
        <div class="max-w-full overflow-x-auto">
          <table class="w-full divide-y divide-gray-200 dark:divide-gray-800">
            <thead>
              <tr>
                <th scope="col" class="fleet-th">Fecha</th>
                <th scope="col" class="fleet-th">Vehículo</th>
                <th scope="col" class="fleet-th">Título</th>
                <th scope="col" class="fleet-th">Severidad</th>
                <th scope="col" class="fleet-th">Estado</th>
                <th scope="col" class="fleet-th">Reportó</th>
                <th scope="col" class="fleet-th text-right">Acciones</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
              <tr v-if="loading" v-for="n in 5" :key="`sk-${n}`" class="animate-pulse">
                <td v-for="c in 7" :key="c" class="fleet-td">
                  <div class="h-4 w-full max-w-[120px] rounded bg-gray-200 dark:bg-gray-800" />
                </td>
              </tr>

              <tr v-else-if="incidents.length === 0">
                <td colspan="7" class="p-0">
                  <TableEmptyState
                    icon="alert"
                    :has-filters="hasFilters"
                    :title="hasFilters ? 'Sin incidencias para estos filtros' : 'Sin incidencias reportadas'"
                    :description="
                      hasFilters
                        ? 'Prueba cambiando el vehículo, estado o severidad.'
                        : 'Cuando se reporte una falla o novedad aparecerá aquí.'
                    "
                    @reset="resetFilters"
                  />
                </td>
              </tr>

              <tr v-for="inc in incidents" v-else :key="inc.id" class="fleet-tr">
                <td class="fleet-td whitespace-nowrap text-theme-xs tabular-nums">
                  {{ formatDateTime(inc.reported_at) }}
                </td>
                <td class="fleet-td whitespace-nowrap">
                  <span class="rounded-md bg-gray-100 px-2 py-0.5 font-mono text-theme-xs font-semibold text-gray-900 dark:bg-gray-800 dark:text-white">
                    {{ inc.vehicle?.license_plate }}
                  </span>
                </td>
                <td class="fleet-td max-w-[145px] truncate font-medium text-gray-900 dark:text-white xl:max-w-[220px]" :title="inc.title">
                  {{ inc.title }}
                </td>
                <td class="fleet-td whitespace-nowrap">
                  <StatusBadge kind="incidentSeverity" :value="inc.severity" />
                </td>
                <td class="fleet-td whitespace-nowrap">
                  <StatusBadge kind="incidentStatus" :value="inc.status" />
                </td>
                <td class="fleet-td max-w-[120px] truncate text-gray-600 dark:text-gray-300 xl:max-w-[160px]" :title="inc.reporter?.name || ''">
                  {{ inc.reporter?.name || '—' }}
                </td>
                <td class="fleet-td whitespace-nowrap text-right">
                  <TableRowActions
                    :group-label="`Acciones incidencia ${inc.id}`"
                    :show-edit="canManageFleet"
                    :show-delete="isAdmin"
                    @view="openView(inc)"
                    @edit="openEdit(inc)"
                    @delete="confirmDelete(inc)"
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
      :open="modalOpen"
      :title="editingId ? 'Actualizar incidencia' : 'Reportar incidencia'"
      :subtitle="editingId ? 'Actualiza la severidad, descripción o estado de seguimiento.' : 'Registra fallas o novedades detectadas en una unidad.'"
      @close="closeModal"
    >
      <form id="incident-form" class="space-y-4" @submit.prevent="submit">
        <div v-if="!editingId">
          <label for="incident-vehicle" class="fleet-field-label">
            Vehículo <span class="text-rose-500">*</span>
          </label>
          <select id="incident-vehicle" v-model="form.vehicle_id" required class="fleet-select">
            <option value="" disabled>Seleccione una unidad…</option>
            <option v-for="v in vehicleOptions" :key="v.id" :value="String(v.id)">
              {{ v.license_plate }} — {{ v.brand }} {{ v.model }}
            </option>
          </select>
        </div>

        <div>
          <label for="incident-title" class="fleet-field-label">
            Título breve <span class="text-rose-500">*</span>
          </label>
          <input
            id="incident-title"
            v-model="form.title"
            type="text"
            required
            placeholder="Ej. Llanta delantera derecha pinchada"
            class="fleet-input"
          />
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div>
            <label for="incident-severity" class="fleet-field-label">Severidad</label>
            <select id="incident-severity" v-model="form.severity" class="fleet-select">
              <option value="baja">Baja</option>
              <option value="media">Media</option>
              <option value="alta">Alta</option>
              <option value="critica">Crítica</option>
            </select>
          </div>
          <div v-if="editingId">
            <label for="incident-status" class="fleet-field-label">Estado</label>
            <select id="incident-status" v-model="form.status" class="fleet-select">
              <option value="abierta">Abierta</option>
              <option value="en_revision">En revisión</option>
              <option value="resuelta">Resuelta</option>
            </select>
          </div>
        </div>

        <div>
          <label for="incident-description" class="fleet-field-label">Descripción</label>
          <textarea
            id="incident-description"
            v-model="form.description"
            rows="3"
            placeholder="Detalles de lo ocurrido..."
            class="fleet-textarea"
          />
        </div>

        <div
          v-if="!editingId && canManageFleet"
          class="flex items-start gap-2.5 rounded-xl border border-amber-200/80 bg-amber-50/70 p-3 dark:border-amber-500/25 dark:bg-amber-500/10"
        >
          <input
            id="maint-check"
            v-model="form.set_vehicle_maintenance"
            type="checkbox"
            class="mt-0.5 size-4 rounded border-gray-300 text-brand-500 focus:ring-brand-500"
          />
          <label for="maint-check" class="text-theme-sm font-medium text-amber-900 dark:text-amber-200">
            Poner vehículo en estado de mantenimiento
          </label>
        </div>

        <div v-if="!editingId">
          <label for="incident-photo" class="fleet-field-label">Evidencia fotográfica (opcional)</label>
          <input id="incident-photo" type="file" accept="image/*" class="fleet-file" @change="onFile" />
          <div v-if="previewUrl" class="mt-3">
            <img :src="previewUrl" alt="Vista previa" class="h-28 w-44 rounded-xl border border-gray-200 object-cover dark:border-gray-700" />
          </div>
        </div>
      </form>

      <template #footer>
        <button type="button" class="fleet-btn-secondary" @click="closeModal">
          Cancelar
        </button>
        <button type="submit" form="incident-form" :disabled="saving" class="fleet-btn-primary">
          {{ saving ? 'Guardando…' : 'Guardar' }}
        </button>
      </template>
    </BaseModal>

    <BaseModal
      :open="detailOpen"
      :title="detailItem?.title || 'Detalle de incidencia'"
      :subtitle="detailItem?.vehicle ? `${detailItem.vehicle.license_plate} · ${detailItem.vehicle.brand} ${detailItem.vehicle.model}` : ''"
      @close="detailOpen = false"
    >
      <div v-if="detailItem" class="space-y-4">
        <div class="flex flex-wrap items-center justify-between gap-2 rounded-xl border border-gray-200/80 bg-gray-50/80 px-4 py-3 dark:border-gray-800 dark:bg-white/[0.02]">
          <div class="flex items-center gap-2">
            <StatusBadge kind="incidentSeverity" :value="detailItem.severity" />
            <StatusBadge kind="incidentStatus" :value="detailItem.status" />
          </div>
          <span class="text-theme-xs font-medium tabular-nums text-gray-500 dark:text-gray-400">
            {{ formatDateTime(detailItem.reported_at) }}
          </span>
        </div>

        <dl class="grid grid-cols-1 gap-3 text-theme-sm sm:grid-cols-2">
          <div class="rounded-xl border border-gray-100 p-3 dark:border-gray-800">
            <dt class="text-theme-xs text-gray-500 dark:text-gray-400">Vehículo</dt>
            <dd class="mt-0.5 font-medium text-gray-900 dark:text-white">
              {{ detailItem.vehicle?.license_plate || '—' }}
              <span v-if="detailItem.vehicle" class="text-theme-xs font-normal text-gray-500">
                ({{ detailItem.vehicle.brand }} {{ detailItem.vehicle.model }})
              </span>
            </dd>
          </div>
          <div class="rounded-xl border border-gray-100 p-3 dark:border-gray-800">
            <dt class="text-theme-xs text-gray-500 dark:text-gray-400">Reportó</dt>
            <dd class="mt-0.5 font-medium text-gray-900 dark:text-white">
              {{ detailItem.reporter?.name || '—' }}
            </dd>
          </div>
        </dl>

        <div class="rounded-xl border border-gray-100 p-3.5 text-theme-sm dark:border-gray-800">
          <p class="text-theme-xs font-medium text-gray-500 dark:text-gray-400">Descripción</p>
          <p class="mt-1 whitespace-pre-line text-gray-900 dark:text-gray-100">
            {{ detailItem.description || 'Sin descripción adicional.' }}
          </p>
        </div>

        <div
          v-if="detailItem.photo_url"
          class="overflow-hidden rounded-xl border border-gray-200 bg-gray-50 dark:border-gray-800 dark:bg-gray-950"
        >
          <img :src="detailItem.photo_url" alt="Evidencia de incidencia" class="max-h-64 w-full object-contain" />
        </div>
      </div>

      <template #footer>
        <button type="button" class="fleet-btn-primary" @click="detailOpen = false">
          Cerrar
        </button>
      </template>
    </BaseModal>
  </AdminLayout>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import AdminLayout from '@/components/layout/AdminLayout.vue';
import BaseModal from '@/components/common/BaseModal.vue';
import ComponentCard from '@/components/common/ComponentCard.vue';
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue';
import StatusBadge from '@/components/common/StatusBadge.vue';
import TableEmptyState from '@/components/common/TableEmptyState.vue';
import TablePagination from '@/components/common/TablePagination.vue';
import TableRowActions from '@/components/common/TableRowActions.vue';
import { useAuth } from '../composables/useAuth';
import { confirmDeleteDialog, showErrorAlert, showSuccessAlert } from '../utils/alerts';

const { currentUser, isAdmin, canManageFleet, loadMe, logout } = useAuth();

const incidents = ref([]);
const vehicleOptions = ref([]);
const loading = ref(true);
const saving = ref(false);
const meta = ref({ current_page: 1, last_page: 1, total: 0, from: 0, to: 0 });
const filterVehicleId = ref('');
const filterStatus = ref('');
const filterSeverity = ref('');
const modalOpen = ref(false);
const detailOpen = ref(false);
const detailItem = ref(null);
const editingId = ref(null);
const previewUrl = ref('');
const fileRef = ref(null);

const form = reactive({
  vehicle_id: '',
  title: '',
  description: '',
  severity: 'media',
  status: 'abierta',
  set_vehicle_maintenance: false,
});

const hasFilters = computed(() =>
  Boolean(filterVehicleId.value || filterStatus.value || filterSeverity.value),
);

const formatDateTime = (iso) => {
  if (!iso) return '';
  return new Date(iso).toLocaleString('es-HN', { dateStyle: 'short', timeStyle: 'short' });
};

const loadVehicles = async () => {
  const { data } = await window.axios.get('/vehicles/options');
  vehicleOptions.value = data.data || [];
};

const loadIncidents = async (page = 1) => {
  loading.value = true;
  try {
    const params = { page, per_page: 15 };
    if (filterVehicleId.value) params.vehicle_id = filterVehicleId.value;
    if (filterStatus.value) params.status = filterStatus.value;
    if (filterSeverity.value) params.severity = filterSeverity.value;
    const { data } = await window.axios.get('/incidents', { params });
    incidents.value = data.data || [];
    meta.value = {
      current_page: data.current_page ?? 1,
      last_page: data.last_page ?? 1,
      total: data.total ?? incidents.value.length,
      from: data.from ?? 0,
      to: data.to ?? 0,
    };
  } catch (_) {
    /* manejado por interceptor o estado actual */
  } finally {
    loading.value = false;
  }
};

const resetFilters = () => {
  filterVehicleId.value = '';
  filterStatus.value = '';
  filterSeverity.value = '';
  loadIncidents(1);
};

const changePage = (page) => {
  if (page < 1 || page > meta.value.last_page) return;
  loadIncidents(page);
};

const resetPreview = () => {
  if (previewUrl.value && previewUrl.value.startsWith('blob:')) {
    URL.revokeObjectURL(previewUrl.value);
  }
  previewUrl.value = '';
  fileRef.value = null;
};

const onFile = (e) => {
  const file = e.target.files?.[0];
  resetPreview();
  if (!file) return;
  fileRef.value = file;
  previewUrl.value = URL.createObjectURL(file);
};

const openCreate = () => {
  editingId.value = null;
  form.vehicle_id = '';
  form.title = '';
  form.description = '';
  form.severity = 'media';
  form.status = 'abierta';
  form.set_vehicle_maintenance = false;
  resetPreview();
  modalOpen.value = true;
};

const openEdit = (inc) => {
  editingId.value = inc.id;
  form.vehicle_id = String(inc.vehicle_id);
  form.title = inc.title;
  form.description = inc.description || '';
  form.severity = inc.severity || 'media';
  form.status = inc.status || 'abierta';
  form.set_vehicle_maintenance = false;
  resetPreview();
  modalOpen.value = true;
};

const openView = (inc) => {
  detailItem.value = inc;
  detailOpen.value = true;
};

const closeModal = () => {
  modalOpen.value = false;
  resetPreview();
};

const submit = async () => {
  if (saving.value) return;
  saving.value = true;
  try {
    if (editingId.value) {
      await window.axios.put(`/incidents/${editingId.value}`, {
        title: form.title,
        description: form.description || null,
        severity: form.severity,
        status: form.status,
      });
    } else {
      const fd = new FormData();
      fd.append('vehicle_id', form.vehicle_id);
      fd.append('title', form.title);
      fd.append('severity', form.severity);
      if (form.description) fd.append('description', form.description);
      if (form.set_vehicle_maintenance) fd.append('set_vehicle_maintenance', '1');
      if (fileRef.value) fd.append('photo', fileRef.value);
      await window.axios.post('/incidents', fd);
    }
    await showSuccessAlert('Guardado');
    closeModal();
    await loadIncidents(meta.value.current_page);
  } catch (err) {
    const errors = err.response?.data?.errors;
    const firstErr = errors ? Object.values(errors).flat()[0] : null;
    const msg = firstErr || err.response?.data?.message || 'No se pudo guardar';
    await showErrorAlert('Error', msg);
  } finally {
    saving.value = false;
  }
};

const confirmDelete = async (inc) => {
  const r = await confirmDeleteDialog({
    title: '¿Eliminar incidencia?',
    text: inc.title,
  });
  if (!r.isConfirmed) return;
  try {
    await window.axios.delete(`/incidents/${inc.id}`);
    await showSuccessAlert('Eliminado');
    await loadIncidents(meta.value.current_page);
  } catch (err) {
    await showErrorAlert('Error', err.response?.data?.message || 'No se pudo eliminar');
  }
};

onMounted(async () => {
  await loadMe();
  await Promise.all([loadVehicles(), loadIncidents(1)]);
});
</script>
