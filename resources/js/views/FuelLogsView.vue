<template>
  <AdminLayout header-title="Combustible" :user-name="currentUser?.name" @logout="logout(true)">
    <PageBreadcrumb
      page-title="Cargas de combustible"
      subtitle="Registro de despacho de gasolina/diésel, odómetro, costo y rendimiento por unidad."
    >
      <template #actions>
        <button type="button" class="fleet-btn-primary" @click="openCreate">
          <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
          </svg>
          Registrar carga
        </button>
      </template>
    </PageBreadcrumb>

    <ComponentCard title="Historial de combustible" desc="Actualiza el odómetro automáticamente y calcula km/galón entre cargas.">
      <template #header-extra>
        <span class="rounded-lg bg-gray-100 px-2.5 py-1 text-theme-xs font-semibold tabular-nums text-gray-600 dark:bg-gray-800 dark:text-gray-300">
          {{ meta.total }} {{ meta.total === 1 ? 'carga' : 'cargas' }}
        </span>
      </template>

      <div class="fleet-filter-bar grid grid-cols-1 gap-3 sm:grid-cols-3">
        <div>
          <label for="fuel-veh" class="fleet-label">Vehículo</label>
          <select id="fuel-veh" v-model="filterVehicleId" class="fleet-select" @change="loadData(1)">
            <option value="">Todos</option>
            <option v-for="v in vehicles" :key="v.id" :value="String(v.id)">{{ v.license_plate }} · {{ v.brand }}</option>
          </select>
        </div>
        <div>
          <label for="fuel-type" class="fleet-label">Tipo</label>
          <select id="fuel-type" v-model="filterType" class="fleet-select" @change="loadData(1)">
            <option value="">Todos</option>
            <option value="regular">Regular</option>
            <option value="especial">Especial</option>
            <option value="diesel">Diésel</option>
          </select>
        </div>
      </div>

      <div class="fleet-table-wrap">
        <div class="max-w-full overflow-x-auto">
          <table class="w-full divide-y divide-gray-200 dark:divide-gray-800">
            <thead>
              <tr>
                <th scope="col" class="fleet-th">Fecha</th>
                <th scope="col" class="fleet-th">Vehículo</th>
                <th scope="col" class="fleet-th">Conductor / Gasolinera</th>
                <th scope="col" class="fleet-th">Cantidad y costo</th>
                <th scope="col" class="fleet-th">Odómetro / Rend.</th>
                <th v-if="isAdmin" scope="col" class="fleet-th text-right">Acciones</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
              <tr v-if="loading" v-for="n in 4" :key="n" class="animate-pulse">
                <td v-for="c in 6" :key="c" class="fleet-td"><div class="h-4 w-24 rounded bg-gray-200 dark:bg-gray-800" /></td>
              </tr>
              <tr v-else-if="logs.length === 0">
                <td :colspan="isAdmin ? 6 : 5" class="px-4 py-10 text-center text-theme-sm text-gray-500 dark:text-gray-400">
                  Sin cargas de combustible registradas.
                </td>
              </tr>
              <tr v-else v-for="f in logs" :key="f.id" class="fleet-tr">
                <td class="fleet-td whitespace-nowrap text-theme-xs text-gray-600 dark:text-gray-300">
                  {{ formatDateTime(f.filled_at) }}
                </td>
                <td class="fleet-td whitespace-nowrap">
                  <SalvadorPlate
                    :license-plate="f.vehicle?.license_plate"
                    :plate-type="f.vehicle?.plate_type"
                    :plate-number="f.vehicle?.plate_number"
                    compact
                  />
                </td>
                <td class="fleet-td text-theme-xs">
                  <p class="font-medium text-gray-900 dark:text-white">{{ f.driver?.name || f.recorder?.name || '—' }}</p>
                  <p class="text-gray-500 dark:text-gray-400">{{ f.station || 'Gasolinera no especificada' }}</p>
                </td>
                <td class="fleet-td whitespace-nowrap text-theme-xs tabular-nums">
                  <p class="font-semibold text-gray-900 dark:text-white">
                    {{ Number(f.gallons).toFixed(2) }} gal · {{ String(f.fuel_type).toUpperCase() }}
                  </p>
                  <p v-if="f.cost_usd !== null && f.cost_usd !== undefined" class="text-emerald-600 dark:text-emerald-400">
                    ${{ Number(f.cost_usd).toFixed(2) }}
                  </p>
                </td>
                <td class="fleet-td whitespace-nowrap text-theme-xs tabular-nums">
                  <p class="font-medium">{{ Number(f.odometer_km).toLocaleString() }} km</p>
                  <p v-if="f.km_per_gallon" class="text-brand-600 dark:text-brand-400">
                    {{ Number(f.km_per_gallon).toFixed(1) }} km/gal ({{ f.km_since_last }} km)
                  </p>
                </td>
                <td v-if="isAdmin" class="fleet-td whitespace-nowrap text-right">
                  <button type="button" class="fleet-btn-danger h-8 px-2.5 py-1 text-theme-xs" @click="removeFuel(f)">
                    Eliminar
                  </button>
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
          @change="loadData"
        />
      </div>
    </ComponentCard>

    <BaseModal
      :open="modalOpen"
      title="Registrar carga de combustible"
      subtitle="Ingresa el odómetro actual para calcular rendimiento y mantener alertas de mantenimiento."
      @close="modalOpen = false"
    >
      <form id="fuel-form" class="space-y-4" @submit.prevent="submitForm">
        <div>
          <label for="f-veh" class="fleet-field-label">Vehículo *</label>
          <select id="f-veh" v-model="form.vehicle_id" class="fleet-select" required @change="onVehicleChange">
            <option value="">Selecciona vehículo…</option>
            <option v-for="v in vehicles" :key="v.id" :value="v.id">
              {{ v.license_plate }} · {{ v.brand }} ({{ Number(v.current_odometer).toLocaleString() }} km)
            </option>
          </select>
        </div>
        <div class="grid grid-cols-1 gap-3 sm:grid-cols-3">
          <div>
            <label for="f-odom" class="fleet-field-label">Odómetro actual (km) *</label>
            <input id="f-odom" v-model.number="form.odometer_km" type="number" min="0" class="fleet-input tabular-nums" required />
          </div>
          <div>
            <label for="f-gal" class="fleet-field-label">Galones *</label>
            <input id="f-gal" v-model.number="form.gallons" type="number" step="0.01" min="0.1" class="fleet-input tabular-nums" required />
          </div>
          <div>
            <label for="f-cost" class="fleet-field-label">Costo ($ USD)</label>
            <input id="f-cost" v-model.number="form.cost_usd" type="number" step="0.01" min="0" class="fleet-input tabular-nums" />
          </div>
        </div>
        <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <div>
            <label for="f-type" class="fleet-field-label">Tipo de combustible</label>
            <select id="f-type" v-model="form.fuel_type" class="fleet-select">
              <option value="regular">Gasolina Regular</option>
              <option value="especial">Gasolina Especial</option>
              <option value="diesel">Diésel</option>
            </select>
          </div>
          <div>
            <label for="f-station" class="fleet-field-label">Gasolinera</label>
            <input id="f-station" v-model="form.station" type="text" placeholder="Ej. Puma, Texaco, Uno" class="fleet-input" />
          </div>
        </div>
        <div>
          <label for="f-notes" class="fleet-field-label">Notas</label>
          <textarea id="f-notes" v-model="form.notes" rows="2" class="fleet-textarea" />
        </div>
      </form>
      <template #footer>
        <button type="button" class="fleet-btn-secondary" @click="modalOpen = false">Cancelar</button>
        <button type="submit" form="fuel-form" :disabled="saving" class="fleet-btn-primary">
          {{ saving ? 'Guardando…' : 'Guardar carga' }}
        </button>
      </template>
    </BaseModal>
  </AdminLayout>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue';
import AdminLayout from '@/components/layout/AdminLayout.vue';
import BaseModal from '@/components/common/BaseModal.vue';
import ComponentCard from '@/components/common/ComponentCard.vue';
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue';
import SalvadorPlate from '@/components/common/SalvadorPlate.vue';
import TablePagination from '@/components/common/TablePagination.vue';
import { useAuth } from '../composables/useAuth';
import { confirmDeleteDialog, showErrorAlert, showSuccessAlert } from '../utils/alerts';

const { currentUser, isAdmin, loadMe, logout } = useAuth();

const logs = ref([]);
const vehicles = ref([]);
const loading = ref(true);
const saving = ref(false);
const modalOpen = ref(false);
const filterVehicleId = ref('');
const filterType = ref('');
const meta = reactive({ current_page: 1, last_page: 1, total: 0, from: 0, to: 0 });

const form = reactive({
  vehicle_id: '',
  odometer_km: 0,
  gallons: null,
  cost_usd: null,
  fuel_type: 'regular',
  station: '',
  full_tank: true,
  notes: '',
});

const formatDateTime = (val) => {
  if (!val) return '—';
  const d = new Date(val);
  return Number.isNaN(d.getTime())
    ? String(val)
    : d.toLocaleString('es-SV', { dateStyle: 'short', timeStyle: 'short' });
};

const loadVehicles = async () => {
  const { data } = await window.axios.get('/vehicles/options');
  vehicles.value = data.data || [];
};

const loadData = async (page = 1) => {
  loading.value = true;
  try {
    const { data } = await window.axios.get('/fuel-logs', {
      params: {
        page,
        vehicle_id: filterVehicleId.value || undefined,
        fuel_type: filterType.value || undefined,
      },
    });
    logs.value = data.data || [];
    meta.current_page = data.current_page ?? 1;
    meta.last_page = data.last_page ?? 1;
    meta.total = data.total ?? logs.value.length;
    meta.from = data.from ?? 0;
    meta.to = data.to ?? 0;
  } finally {
    loading.value = false;
  }
};

const onVehicleChange = () => {
  const v = vehicles.value.find((item) => Number(item.id) === Number(form.vehicle_id));
  if (v) form.odometer_km = v.current_odometer ?? 0;
};

const openCreate = () => {
  form.vehicle_id = vehicles.value[0]?.id ?? '';
  form.gallons = null;
  form.cost_usd = null;
  form.fuel_type = 'regular';
  form.station = '';
  form.notes = '';
  onVehicleChange();
  modalOpen.value = true;
};

const submitForm = async () => {
  saving.value = true;
  try {
    await window.axios.post('/fuel-logs', form);
    await showSuccessAlert('Registrado', 'Carga de combustible guardada.');
    modalOpen.value = false;
    await Promise.all([loadVehicles(), loadData(1)]);
  } catch (err) {
    const errors = err.response?.data?.errors;
    const first = errors ? Object.values(errors).flat()[0] : null;
    await showErrorAlert('Error', first || err.response?.data?.message || 'No se pudo registrar.');
  } finally {
    saving.value = false;
  }
};

const removeFuel = async (f) => {
  const r = await confirmDeleteDialog({ title: '¿Eliminar registro?', text: `${f.gallons} gal` });
  if (!r.isConfirmed) return;
  await window.axios.delete(`/fuel-logs/${f.id}`);
  await showSuccessAlert('Eliminado');
  await loadData(meta.current_page);
};

onMounted(async () => {
  await loadMe();
  await Promise.all([loadVehicles(), loadData(1)]);
});
</script>
