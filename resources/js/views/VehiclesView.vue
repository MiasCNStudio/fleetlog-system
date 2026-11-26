<template>
  <AdminLayout header-title="Vehículos" :user-name="currentUser?.name" @logout="logout(true)">
    <PageBreadcrumb page-title="Vehículos" subtitle="Registro, estado operativo y odómetro de unidades.">
      <template v-if="canManageFleet" #actions>
        <button type="button" class="fleet-btn-primary" @click="openCreate">
          <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
          </svg>
          Nuevo vehículo
        </button>
      </template>
    </PageBreadcrumb>

    <ComponentCard title="Listado" desc="Estado, kilometraje actual, placa, marca y modelo.">
      <template #header-extra>
        <span class="rounded-lg bg-gray-100 px-2.5 py-1 text-theme-xs font-semibold tabular-nums text-gray-600 dark:bg-gray-800 dark:text-gray-300">
          {{ meta.total }} {{ meta.total === 1 ? 'unidad' : 'unidades' }}
        </span>
      </template>

      <div class="fleet-filter-bar grid grid-cols-1 gap-3 sm:flex sm:flex-wrap sm:items-end">
        <div class="w-full sm:w-72">
          <label for="vehicles-search" class="fleet-label">Buscar</label>
          <div class="relative">
            <svg
              class="pointer-events-none absolute left-3.5 top-1/2 size-4 -translate-y-1/2 text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="1.8"
              aria-hidden="true"
            >
              <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
            </svg>
            <input
              id="vehicles-search"
              v-model="searchQuery"
              type="text"
              placeholder="Placa, marca o modelo…"
              class="fleet-input pl-10 pr-9"
              @keyup.enter="loadVehicles(1)"
            />
            <button
              v-if="searchQuery"
              type="button"
              class="absolute right-2.5 top-1/2 -translate-y-1/2 rounded p-1 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"
              aria-label="Limpiar búsqueda"
              @click="clearSearch"
            >
              <svg class="size-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>

        <div class="w-full sm:w-48">
          <label for="vehicles-filter-status" class="fleet-label">Estado</label>
          <select
            id="vehicles-filter-status"
            v-model="filterStatus"
            class="fleet-select"
            @change="loadVehicles(1)"
          >
            <option value="">Todos</option>
            <option value="disponible">Disponible</option>
            <option value="en_ruta">En ruta</option>
            <option value="mantenimiento">Mantenimiento</option>
          </select>
        </div>

        <button type="button" class="fleet-btn-secondary h-10 px-3.5 text-theme-xs" @click="loadVehicles(1)">
          Buscar
        </button>

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
          <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-800">
            <thead>
              <tr>
                <th scope="col" class="fleet-th">Imagen</th>
                <th scope="col" class="fleet-th">Placa</th>
                <th scope="col" class="fleet-th">Vehículo</th>
                <th scope="col" class="fleet-th">Estado</th>
                <th scope="col" class="fleet-th">Odómetro</th>
                <th scope="col" class="fleet-th text-right">Acciones</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
              <tr v-if="loading" v-for="n in 5" :key="`sk-${n}`" class="animate-pulse">
                <td class="fleet-td"><div class="h-12 w-16 rounded-lg bg-gray-200 dark:bg-gray-800" /></td>
                <td v-for="c in 5" :key="c" class="fleet-td">
                  <div class="h-4 w-full max-w-[120px] rounded bg-gray-200 dark:bg-gray-800" />
                </td>
              </tr>

              <tr v-else-if="vehicles.length === 0">
                <td colspan="6" class="p-0">
                  <TableEmptyState
                    icon="truck"
                    :has-filters="hasFilters"
                    :title="hasFilters ? 'No se encontraron vehículos' : 'Sin vehículos registrados'"
                    :description="
                      hasFilters
                        ? 'Ajusta la búsqueda o el estado para ver unidades.'
                        : 'Agrega el primer vehículo para comenzar a operar la flotilla.'
                    "
                    @reset="resetFilters"
                  />
                </td>
              </tr>

              <tr v-for="v in vehicles" v-else :key="v.id" class="fleet-tr">
                <td class="fleet-td whitespace-nowrap">
                  <div class="flex h-12 w-16 items-center justify-center overflow-hidden rounded-xl border border-gray-200/80 bg-gray-100 text-gray-400 dark:border-gray-800 dark:bg-gray-800 dark:text-gray-500">
                    <img
                      v-if="v.photo_url"
                      :src="v.photo_url"
                      :alt="v.license_plate"
                      class="h-full w-full object-cover"
                    />
                    <svg v-else class="size-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.6" aria-hidden="true">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M9 17a2 2 0 11-4 0 2 2 0 014 0zM19 17a2 2 0 11-4 0 2 2 0 014 0z" />
                      <path stroke-linecap="round" stroke-linejoin="round" d="M13 16V6a1 1 0 00-1-1H4a1 1 0 00-1 1v10a1 1 0 001 1h1m8-1a1 1 0 01-1 1H9m4-1V8a1 1 0 011-1h2.586a1 1 0 01.707.293l3.414 3.414a1 1 0 01.293.707V16a1 1 0 01-1 1h-1m-6-1a1 1 0 001 1h1" />
                    </svg>
                  </div>
                </td>
                <td class="fleet-td whitespace-nowrap">
                  <SalvadorPlate
                    :license-plate="v.license_plate"
                    :plate-type="v.plate_type"
                    :plate-number="v.plate_number"
                  />
                </td>
                <td class="fleet-td">
                  <p class="font-medium text-gray-900 dark:text-white">{{ v.brand }} {{ v.model }}</p>
                  <p class="text-theme-xs text-gray-500 dark:text-gray-400">{{ v.color }}</p>
                </td>
                <td class="fleet-td whitespace-nowrap">
                  <div class="flex flex-col items-start gap-1">
                    <StatusBadge kind="vehicleStatus" :value="v.status" />
                    <StatusBadge
                      v-if="v.maintenance_status && v.maintenance_status !== 'sin_programar'"
                      kind="maintenanceStatus"
                      :value="v.maintenance_status"
                    />
                  </div>
                </td>
                <td class="fleet-td whitespace-nowrap tabular-nums">
                  <p class="font-medium text-gray-900 dark:text-white">
                    {{ (v.current_odometer ?? 0).toLocaleString() }} km
                  </p>
                  <p
                    v-if="v.next_maintenance_odometer !== null && v.next_maintenance_odometer !== undefined"
                    :class="[
                      'text-[11px] font-medium',
                      v.maintenance_status === 'vencido'
                        ? 'text-rose-600 dark:text-rose-400'
                        : v.maintenance_status === 'pronto'
                          ? 'text-amber-600 dark:text-amber-400'
                          : 'text-gray-500 dark:text-gray-400',
                    ]"
                  >
                    {{
                      v.km_to_maintenance <= 0
                        ? `Pasado ${Math.abs(v.km_to_maintenance).toLocaleString()} km (meta ${Number(v.next_maintenance_odometer).toLocaleString()} km)`
                        : `Próx. mant. en ${Number(v.km_to_maintenance).toLocaleString()} km`
                    }}
                  </p>
                  <p v-else-if="v.maintenance_interval_km" class="text-[11px] text-gray-500 dark:text-gray-400">
                    Mant. c/ {{ Number(v.maintenance_interval_km).toLocaleString() }} km
                  </p>
                </td>
                <td class="fleet-td whitespace-nowrap text-right">
                  <TableRowActions
                    :group-label="`Acciones para ${v.license_plate}`"
                    :show-edit="canManageFleet"
                    :show-delete="isAdmin"
                    @view="openView(v)"
                    @edit="openEdit(v)"
                    @delete="confirmDelete(v)"
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
      :title="editingId ? 'Editar vehículo' : 'Nuevo vehículo'"
      subtitle="Completa los datos técnicos y el estado operativo de la unidad."
      @close="closeModal"
    >
      <form id="vehicle-form" class="space-y-4" @submit.prevent="submit">
        <div class="rounded-xl border border-gray-200/80 bg-gray-50/70 p-3.5 dark:border-white/[0.07] dark:bg-white/[0.02]">
          <div class="mb-2 flex items-center justify-between gap-2">
            <span class="fleet-field-label mb-0">Placa vehicular (El Salvador) <span class="text-rose-500">*</span></span>
            <SalvadorPlate
              v-if="previewLicensePlate"
              :license-plate="previewLicensePlate"
              :plate-type="form.plate_type !== 'CUSTOM' ? form.plate_type : ''"
              :plate-number="form.plate_type !== 'CUSTOM' ? form.plate_number : ''"
            />
          </div>
          <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
            <div>
              <label for="vehicle-plate-type" class="fleet-label">Tipo de placa</label>
              <select id="vehicle-plate-type" v-model="form.plate_type" class="fleet-select">
                <option v-for="t in SV_PLATE_TYPES" :key="t.code" :value="t.code">{{ t.label }}</option>
                <option value="CUSTOM">Otra / Personalizada</option>
              </select>
            </div>
            <div v-if="form.plate_type !== 'CUSTOM'">
              <label for="vehicle-plate-num" class="fleet-label">Número / letras (ej. 123456 ó 745ABC)</label>
              <input
                id="vehicle-plate-num"
                v-model="form.plate_number"
                type="text"
                maxlength="10"
                placeholder="Ej. 123456 o 1234"
                class="fleet-input font-mono uppercase"
                required
              />
            </div>
            <div v-else>
              <label for="vehicle-plate" class="fleet-label">Placa completa</label>
              <input
                id="vehicle-plate"
                v-model="form.license_plate"
                type="text"
                placeholder="Ej. QA-DEMO-01"
                class="fleet-input font-mono uppercase"
                required
              />
            </div>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div>
            <label for="vehicle-status" class="fleet-field-label">Estado operativo</label>
            <select id="vehicle-status" v-model="form.status" class="fleet-select">
              <option value="disponible">Disponible</option>
              <option value="en_ruta">En ruta</option>
              <option value="mantenimiento">Mantenimiento</option>
            </select>
          </div>
          <div>
            <label for="vehicle-odometer" class="fleet-field-label">Odómetro actual (km)</label>
            <input
              id="vehicle-odometer"
              v-model.number="form.current_odometer"
              type="number"
              min="0"
              class="fleet-input tabular-nums"
            />
          </div>
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <div>
            <label for="vehicle-brand" class="fleet-field-label">
              Marca <span class="text-rose-500">*</span>
            </label>
            <input id="vehicle-brand" v-model="form.brand" type="text" placeholder="Toyota" class="fleet-input" required />
          </div>
          <div>
            <label for="vehicle-model" class="fleet-field-label">
              Modelo <span class="text-rose-500">*</span>
            </label>
            <input id="vehicle-model" v-model="form.model" type="text" placeholder="Hilux" class="fleet-input" required />
          </div>
          <div>
            <label for="vehicle-color" class="fleet-field-label">
              Color <span class="text-rose-500">*</span>
            </label>
            <input id="vehicle-color" v-model="form.color" type="text" placeholder="Blanco" class="fleet-input" required />
          </div>
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <div>
            <label for="vehicle-next-maint" class="fleet-field-label">Próx. mantenimiento (km)</label>
            <input
              id="vehicle-next-maint"
              v-model.number="form.next_maintenance_odometer"
              type="number"
              min="0"
              placeholder="Ej. 85000"
              class="fleet-input tabular-nums"
            />
          </div>
          <div>
            <label for="vehicle-maint" class="fleet-field-label">Intervalo (km)</label>
            <input
              id="vehicle-maint"
              v-model.number="form.maintenance_interval_km"
              type="number"
              min="100"
              placeholder="5000"
              class="fleet-input tabular-nums"
            />
          </div>
          <div>
            <label for="vehicle-alert-before" class="fleet-field-label">Alertar antes (km)</label>
            <input
              id="vehicle-alert-before"
              v-model.number="form.maintenance_alert_before_km"
              type="number"
              min="50"
              max="5000"
              placeholder="500"
              class="fleet-input tabular-nums"
            />
          </div>
        </div>

        <div>
          <label for="vehicle-photo" class="fleet-field-label">Imagen</label>
          <input id="vehicle-photo" type="file" accept="image/*" class="fleet-file" @change="onFile" />
          <div v-if="previewUrl" class="mt-3">
            <img :src="previewUrl" alt="Vista previa" class="h-28 w-44 rounded-xl border border-gray-200 object-cover dark:border-gray-700" />
          </div>
        </div>
      </form>

      <template #footer>
        <button type="button" class="fleet-btn-secondary" @click="closeModal">
          Cancelar
        </button>
        <button type="submit" form="vehicle-form" :disabled="saving" class="fleet-btn-primary">
          {{ saving ? 'Guardando…' : 'Guardar' }}
        </button>
      </template>
    </BaseModal>

    <BaseModal
      :open="detailOpen"
      :title="detailItem?.license_plate || 'Detalle de vehículo'"
      :subtitle="detailItem ? `${detailItem.brand} ${detailItem.model}` : ''"
      @close="detailOpen = false"
    >
      <div v-if="detailItem" class="space-y-4">
        <div
          v-if="detailItem.photo_url"
          class="overflow-hidden rounded-xl border border-gray-200 bg-gray-50 dark:border-gray-800 dark:bg-gray-950"
        >
          <img :src="detailItem.photo_url" :alt="detailItem.license_plate" class="h-48 w-full object-cover" />
        </div>

        <div class="flex items-center justify-between rounded-xl border border-gray-200/80 bg-gray-50/80 px-4 py-3 dark:border-gray-800 dark:bg-white/[0.02]">
          <span class="text-theme-xs font-medium text-gray-500 dark:text-gray-400">Estado operativo</span>
          <StatusBadge kind="vehicleStatus" :value="detailItem.status" />
        </div>

        <dl class="grid grid-cols-1 gap-3 text-theme-sm sm:grid-cols-2">
          <div class="rounded-xl border border-gray-100 p-3 dark:border-gray-800">
            <dt class="text-theme-xs text-gray-500 dark:text-gray-400">Marca y modelo</dt>
            <dd class="mt-0.5 font-medium text-gray-900 dark:text-white">{{ detailItem.brand }} {{ detailItem.model }}</dd>
          </div>
          <div class="rounded-xl border border-gray-100 p-3 dark:border-gray-800">
            <dt class="text-theme-xs text-gray-500 dark:text-gray-400">Color</dt>
            <dd class="mt-0.5 font-medium text-gray-900 dark:text-white">{{ detailItem.color }}</dd>
          </div>
          <div class="rounded-xl border border-gray-100 p-3 dark:border-gray-800">
            <dt class="text-theme-xs text-gray-500 dark:text-gray-400">Odómetro actual</dt>
            <dd class="mt-0.5 font-medium tabular-nums text-gray-900 dark:text-white">
              {{ (detailItem.current_odometer ?? 0).toLocaleString() }} km
            </dd>
          </div>
          <div class="rounded-xl border border-gray-100 p-3 dark:border-gray-800">
            <dt class="text-theme-xs text-gray-500 dark:text-gray-400">Intervalo de mantenimiento</dt>
            <dd class="mt-0.5 font-medium tabular-nums text-gray-900 dark:text-white">
              {{ detailItem.maintenance_interval_km ? `Cada ${Number(detailItem.maintenance_interval_km).toLocaleString()} km` : 'No definido' }}
            </dd>
          </div>
        </dl>
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
import SalvadorPlate from '@/components/common/SalvadorPlate.vue';
import StatusBadge from '@/components/common/StatusBadge.vue';
import TableEmptyState from '@/components/common/TableEmptyState.vue';
import TablePagination from '@/components/common/TablePagination.vue';
import TableRowActions from '@/components/common/TableRowActions.vue';
import { useAuth } from '../composables/useAuth';
import { confirmDeleteDialog, showErrorAlert, showSuccessAlert } from '../utils/alerts';
import { parseSalvadorPlate, SV_PLATE_TYPES } from '../utils/plates';

const { currentUser, isAdmin, canManageFleet, ensureMe, logout } = useAuth();

const vehicles = ref([]);
const loading = ref(true);
const saving = ref(false);
const meta = ref({ current_page: 1, last_page: 1, total: 0, from: 0, to: 0 });
const searchQuery = ref('');
const filterStatus = ref('');
const modalOpen = ref(false);
const detailOpen = ref(false);
const detailItem = ref(null);
const editingId = ref(null);
const previewUrl = ref('');
const fileRef = ref(null);

const form = reactive({
  plate_type: 'P',
  plate_number: '',
  license_plate: '',
  color: '',
  brand: '',
  model: '',
  status: 'disponible',
  current_odometer: 0,
  next_maintenance_odometer: null,
  maintenance_interval_km: 5000,
  maintenance_alert_before_km: 500,
});

const previewLicensePlate = computed(() => {
  if (form.plate_type === 'CUSTOM') return String(form.license_plate || '').toUpperCase().trim();
  const num = String(form.plate_number || '').toUpperCase().replace(/[^A-Z0-9]/g, '');
  return num ? `${form.plate_type}${num}` : '';
});

const hasFilters = computed(() => Boolean(searchQuery.value.trim() || filterStatus.value));

const loadVehicles = async (page = 1) => {
  loading.value = true;
  try {
    const params = { page };
    if (searchQuery.value.trim()) params.search = searchQuery.value.trim();
    if (filterStatus.value) params.status = filterStatus.value;
    const { data } = await window.axios.get('/vehicles', { params });
    vehicles.value = data.data || [];
    meta.value = {
      current_page: data.current_page ?? 1,
      last_page: data.last_page ?? 1,
      total: data.total ?? vehicles.value.length,
      from: data.from ?? 0,
      to: data.to ?? 0,
    };
  } catch (_) {
    /* manejado por interceptor o estado actual */
  } finally {
    loading.value = false;
  }
};

const clearSearch = () => {
  searchQuery.value = '';
  loadVehicles(1);
};

const resetFilters = () => {
  searchQuery.value = '';
  filterStatus.value = '';
  loadVehicles(1);
};

const changePage = (page) => {
  if (page < 1 || page > meta.value.last_page) return;
  loadVehicles(page);
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
  form.plate_type = 'P';
  form.plate_number = '';
  form.license_plate = '';
  form.color = '';
  form.brand = '';
  form.model = '';
  form.status = 'disponible';
  form.current_odometer = 0;
  form.next_maintenance_odometer = null;
  form.maintenance_interval_km = 5000;
  form.maintenance_alert_before_km = 500;
  resetPreview();
  modalOpen.value = true;
};

const openEdit = (v) => {
  editingId.value = v.id;
  const parsed = parseSalvadorPlate(v.license_plate, v.plate_type, v.plate_number);
  if (parsed.isSalvador) {
    form.plate_type = parsed.type;
    form.plate_number = parsed.number;
    form.license_plate = parsed.raw;
  } else {
    form.plate_type = 'CUSTOM';
    form.plate_number = '';
    form.license_plate = v.license_plate;
  }
  form.color = v.color;
  form.brand = v.brand;
  form.model = v.model;
  form.status = v.status || 'disponible';
  form.current_odometer = v.current_odometer ?? 0;
  form.next_maintenance_odometer = v.next_maintenance_odometer ?? null;
  form.maintenance_interval_km = v.maintenance_interval_km || 5000;
  form.maintenance_alert_before_km = v.maintenance_alert_before_km || 500;
  resetPreview();
  previewUrl.value = v.photo_url || '';
  modalOpen.value = true;
};

const openView = (v) => {
  detailItem.value = v;
  detailOpen.value = true;
};

const closeModal = () => {
  modalOpen.value = false;
  resetPreview();
};

const buildFormData = () => {
  const fd = new FormData();
  if (form.plate_type !== 'CUSTOM' && form.plate_number.trim()) {
    const cleanNum = form.plate_number.toUpperCase().replace(/[^A-Z0-9]/g, '');
    fd.append('plate_type', form.plate_type);
    fd.append('plate_number', cleanNum);
    fd.append('license_plate', `${form.plate_type}${cleanNum}`);
  } else {
    fd.append('license_plate', form.license_plate);
  }
  fd.append('color', form.color);
  fd.append('brand', form.brand);
  fd.append('model', form.model);
  fd.append('status', form.status);
  fd.append('current_odometer', String(form.current_odometer ?? 0));
  if (form.next_maintenance_odometer !== null && form.next_maintenance_odometer !== '') {
    fd.append('next_maintenance_odometer', String(form.next_maintenance_odometer));
  }
  if (form.maintenance_interval_km) {
    fd.append('maintenance_interval_km', String(form.maintenance_interval_km));
  }
  if (form.maintenance_alert_before_km) {
    fd.append('maintenance_alert_before_km', String(form.maintenance_alert_before_km));
  }
  if (fileRef.value) {
    fd.append('photo', fileRef.value);
  }
  return fd;
};

const submit = async () => {
  if (saving.value) return;
  saving.value = true;
  try {
    if (editingId.value) {
      await window.axios.post(`/vehicles/${editingId.value}`, buildFormData());
    } else {
      await window.axios.post('/vehicles', buildFormData());
    }
    await showSuccessAlert('Guardado');
    closeModal();
    await loadVehicles(meta.value.current_page);
  } catch (err) {
    const errors = err.response?.data?.errors;
    const firstErr = errors ? Object.values(errors).flat()[0] : null;
    const msg = firstErr || err.response?.data?.message || 'No se pudo guardar';
    await showErrorAlert('Error', msg);
  } finally {
    saving.value = false;
  }
};

const confirmDelete = async (v) => {
  const r = await confirmDeleteDialog({
    title: '¿Eliminar vehículo?',
    text: v.license_plate,
  });
  if (!r.isConfirmed) return;
  try {
    await window.axios.delete(`/vehicles/${v.id}`);
    await showSuccessAlert('Eliminado');
    await loadVehicles(meta.value.current_page);
  } catch (err) {
    await showErrorAlert('Error', err.response?.data?.message || 'No se pudo eliminar');
  }
};

onMounted(async () => {
  await ensureMe();
  await loadVehicles(1);
});
</script>
