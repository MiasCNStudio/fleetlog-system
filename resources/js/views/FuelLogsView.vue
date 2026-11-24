<template>
  <AdminLayout header-title="Combustible" :user-name="currentUser?.name" @logout="logout(true)">
    <PageBreadcrumb
      page-title="Cargas de combustible"
      subtitle="Control de gasolina/diésel, ubicación GPS, comprobantes electrónicos, consumo y costo por kilómetro."
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

    <!-- Resumen de consumo y $/km -->
    <ComponentCard
      title="Resumen de consumo y costo por km"
      desc="Relación entre kilómetros recorridos, galones cargados y gasto total (ej. $60 / 150 km = $0.40/km)."
      class="mb-6"
    >
      <template #header-extra>
        <div class="inline-flex rounded-xl border border-gray-200 bg-gray-50 p-1 dark:border-white/10 dark:bg-[#0b1220]">
          <button
            v-for="opt in rangeOptions"
            :key="opt.value"
            type="button"
            :class="[
              'rounded-lg px-2.5 py-1 text-theme-xs font-semibold transition-colors',
              summaryRange === opt.value
                ? 'bg-brand-500 text-white shadow-sm'
                : 'text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white',
            ]"
            @click="changeSummaryRange(opt.value)"
          >
            {{ opt.label }}
          </button>
        </div>
      </template>

      <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
        <div class="rounded-xl border border-gray-200/80 bg-gray-50/70 p-3.5 dark:border-white/[0.07] dark:bg-white/[0.02]">
          <p class="text-[11px] font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">Km recorridos</p>
          <p class="mt-1 text-xl font-bold tabular-nums text-gray-900 dark:text-white">
            {{ Number(summary.totals?.km_traveled || 0).toLocaleString() }} km
          </p>
        </div>
        <div class="rounded-xl border border-gray-200/80 bg-gray-50/70 p-3.5 dark:border-white/[0.07] dark:bg-white/[0.02]">
          <p class="text-[11px] font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">Total galones</p>
          <p class="mt-1 text-xl font-bold tabular-nums text-gray-900 dark:text-white">
            {{ Number(summary.totals?.gallons || 0).toFixed(2) }} gal
          </p>
          <p class="text-[11px] text-gray-500 dark:text-gray-400">
            {{ summary.totals?.refills_count || 0 }} {{ (summary.totals?.refills_count || 0) === 1 ? 'carga' : 'cargas' }}
          </p>
        </div>
        <div class="rounded-xl border border-gray-200/80 bg-gray-50/70 p-3.5 dark:border-white/[0.07] dark:bg-white/[0.02]">
          <p class="text-[11px] font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">Gasto total</p>
          <p class="mt-1 text-xl font-bold tabular-nums text-emerald-600 dark:text-emerald-400">
            ${{ Number(summary.totals?.cost_usd || 0).toFixed(2) }}
          </p>
        </div>
        <div class="rounded-xl border border-brand-200 bg-brand-50/60 p-3.5 dark:border-brand-500/30 dark:bg-brand-500/10">
          <p class="text-[11px] font-semibold uppercase tracking-wide text-brand-700 dark:text-brand-300">Costo por km</p>
          <p class="mt-1 text-xl font-bold tabular-nums text-brand-700 dark:text-brand-300">
            {{ summary.totals?.cost_per_km !== null && summary.totals?.cost_per_km !== undefined ? `$${Number(summary.totals.cost_per_km).toFixed(2)}/km` : '—' }}
          </p>
        </div>
        <div class="rounded-xl border border-gray-200/80 bg-gray-50/70 p-3.5 dark:border-white/[0.07] dark:bg-white/[0.02]">
          <p class="text-[11px] font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">Rendimiento prom.</p>
          <p class="mt-1 text-xl font-bold tabular-nums text-gray-900 dark:text-white">
            {{ summary.totals?.km_per_gallon !== null && summary.totals?.km_per_gallon !== undefined ? `${Number(summary.totals.km_per_gallon).toFixed(1)} km/gal` : '—' }}
          </p>
        </div>
      </div>

      <div v-if="(summary.by_vehicle || []).length > 0" class="mt-4 overflow-x-auto rounded-xl border border-gray-200/80 dark:border-white/[0.07]">
        <table class="w-full divide-y divide-gray-200 text-theme-xs dark:divide-gray-800">
          <thead class="bg-gray-50 dark:bg-white/[0.02]">
            <tr>
              <th scope="col" class="px-3 py-2 text-left font-semibold text-gray-600 dark:text-gray-300">Unidad</th>
              <th scope="col" class="px-3 py-2 text-right font-semibold text-gray-600 dark:text-gray-300">Cargas</th>
              <th scope="col" class="px-3 py-2 text-right font-semibold text-gray-600 dark:text-gray-300">Km período</th>
              <th scope="col" class="px-3 py-2 text-right font-semibold text-gray-600 dark:text-gray-300">Galones</th>
              <th scope="col" class="px-3 py-2 text-right font-semibold text-gray-600 dark:text-gray-300">Gasto</th>
              <th scope="col" class="px-3 py-2 text-right font-semibold text-gray-600 dark:text-gray-300">$/km</th>
              <th scope="col" class="px-3 py-2 text-right font-semibold text-gray-600 dark:text-gray-300">km/gal</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
            <tr v-for="v in summary.by_vehicle" :key="v.vehicle_id" class="hover:bg-gray-50/70 dark:hover:bg-white/[0.02]">
              <td class="px-3 py-2 font-medium text-gray-900 dark:text-white">
                <div class="flex items-center gap-2">
                  <SalvadorPlate
                    :license-plate="v.license_plate"
                    :plate-type="v.plate_type"
                    :plate-number="v.plate_number"
                    compact
                  />
                  <span class="text-gray-500 dark:text-gray-400">{{ v.brand }} {{ v.model }}</span>
                </div>
              </td>
              <td class="px-3 py-2 text-right tabular-nums">{{ v.refills_count }}</td>
              <td class="px-3 py-2 text-right tabular-nums">{{ Number(v.km_traveled || 0).toLocaleString() }} km</td>
              <td class="px-3 py-2 text-right tabular-nums">{{ Number(v.gallons || 0).toFixed(2) }}</td>
              <td class="px-3 py-2 text-right font-semibold tabular-nums text-emerald-600 dark:text-emerald-400">
                ${{ Number(v.cost_usd || 0).toFixed(2) }}
              </td>
              <td class="px-3 py-2 text-right font-semibold tabular-nums text-brand-600 dark:text-brand-400">
                {{ v.cost_per_km !== null && v.cost_per_km !== undefined ? `$${Number(v.cost_per_km).toFixed(2)}` : '—' }}
              </td>
              <td class="px-3 py-2 text-right tabular-nums">
                {{ v.km_per_gallon !== null && v.km_per_gallon !== undefined ? Number(v.km_per_gallon).toFixed(1) : '—' }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </ComponentCard>

    <ComponentCard title="Historial de combustible" desc="Ubicación GPS de gasolinera, factura electrónica/foto y rendimiento entre cargas.">
      <template #header-extra>
        <span class="rounded-lg bg-gray-100 px-2.5 py-1 text-theme-xs font-semibold tabular-nums text-gray-600 dark:bg-gray-800 dark:text-gray-300">
          {{ meta.total }} {{ meta.total === 1 ? 'carga' : 'cargas' }}
        </span>
      </template>

      <div class="fleet-filter-bar grid grid-cols-1 gap-3 sm:grid-cols-3">
        <div>
          <label for="fuel-veh" class="fleet-label">Vehículo</label>
          <select id="fuel-veh" v-model="filterVehicleId" class="fleet-select" @change="onFilterChange">
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

      <!-- Hidden input for delayed receipt attachment -->
      <input
        ref="rowReceiptInput"
        type="file"
        accept="image/*,.pdf"
        class="hidden"
        @change="onRowReceiptSelected"
      />

      <div class="fleet-table-wrap">
        <div class="max-w-full overflow-x-auto">
          <table class="w-full divide-y divide-gray-200 dark:divide-gray-800">
            <thead>
              <tr>
                <th scope="col" class="fleet-th">Fecha</th>
                <th scope="col" class="fleet-th">Vehículo</th>
                <th scope="col" class="fleet-th">Conductor / Gasolinera GPS</th>
                <th scope="col" class="fleet-th">Cantidad y costo</th>
                <th scope="col" class="fleet-th">Odómetro / Rend.</th>
                <th scope="col" class="fleet-th">Comprobante</th>
                <th v-if="isAdmin" scope="col" class="fleet-th text-right">Acciones</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
              <tr v-if="loading" v-for="n in 4" :key="n" class="animate-pulse">
                <td v-for="c in (isAdmin ? 7 : 6)" :key="c" class="fleet-td"><div class="h-4 w-24 rounded bg-gray-200 dark:bg-gray-800" /></td>
              </tr>
              <tr v-else-if="logs.length === 0">
                <td :colspan="isAdmin ? 7 : 6" class="px-4 py-10 text-center text-theme-sm text-gray-500 dark:text-gray-400">
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
                  <p class="text-gray-600 dark:text-gray-300">{{ f.station || f.location_address || 'Gasolinera sin nombre' }}</p>
                  <p v-if="f.location_address && f.station" class="max-w-[230px] truncate text-[11px] text-gray-500 dark:text-gray-400" :title="f.location_address">
                    {{ f.location_address }}
                  </p>
                  <a
                    v-if="hasCoordinates(f.latitude, f.longitude)"
                    :href="gmapsLink(f)"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="mt-0.5 inline-flex items-center gap-1 text-[11px] font-medium text-brand-600 hover:underline dark:text-brand-400"
                  >
                    Ver ubicación GPS ↗
                  </a>
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
                <td class="fleet-td whitespace-nowrap text-theme-xs">
                  <div class="flex flex-col items-start gap-1">
                    <a
                      v-if="f.receipt_url"
                      :href="f.receipt_url"
                      target="_blank"
                      rel="noopener noreferrer"
                      class="inline-flex items-center gap-1 rounded-lg bg-emerald-500/10 px-2 py-1 font-medium text-emerald-700 hover:bg-emerald-500/20 dark:text-emerald-300"
                    >
                      Ver factura / foto ↗
                    </a>
                    <button
                      type="button"
                      :disabled="uploadingRowId === f.id"
                      class="inline-flex items-center gap-1 rounded-lg border border-gray-200 px-2 py-1 text-[11px] font-medium text-gray-700 hover:bg-gray-100 dark:border-white/10 dark:text-gray-200 dark:hover:bg-white/10"
                      @click="triggerRowReceiptUpload(f)"
                    >
                      {{ uploadingRowId === f.id ? 'Subiendo…' : f.receipt_url ? 'Reemplazar archivo' : 'Adjuntar factura / foto' }}
                    </button>
                  </div>
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
      subtitle="Captura galones, costo, ubicación GPS de la gasolinera y fotografía o factura electrónica."
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
            <input
              id="f-station"
              v-model="form.station"
              type="text"
              placeholder="Ej. Puma, Texaco, Uno (o detectar GPS)"
              class="fleet-input"
            />
          </div>
        </div>

        <!-- GPS + Receipt -->
        <div class="rounded-xl border border-gray-200/80 bg-gray-50/70 p-3 dark:border-white/[0.07] dark:bg-white/[0.02]">
          <div class="flex flex-wrap items-center justify-between gap-2">
            <div>
              <p class="text-theme-xs font-semibold text-gray-800 dark:text-gray-200">Ubicación GPS de gasolinera</p>
              <p class="text-[11px] text-gray-500 dark:text-gray-400">
                <template v-if="hasCoordinates(form.latitude, form.longitude)">
                  {{ Number(form.latitude).toFixed(5) }}, {{ Number(form.longitude).toFixed(5) }}
                  <span v-if="form.location_address">· {{ form.location_address }}</span>
                </template>
                <template v-else>Opcional · El servidor detecta la gasolinera desde las coordenadas</template>
              </p>
            </div>
            <button
              type="button"
              :disabled="locating"
              class="fleet-btn-secondary h-8 px-3 text-[11px]"
              @click="captureBrowserGps"
            >
              {{ locating ? 'Obteniendo GPS…' : 'Usar mi ubicación GPS' }}
            </button>
          </div>
        </div>

        <div>
          <label for="f-receipt" class="fleet-field-label">Foto de ticket o factura electrónica (opcional, máx. 10 MB)</label>
          <input
            id="f-receipt"
            ref="createReceiptInput"
            type="file"
            accept="image/*,.pdf"
            class="block w-full text-theme-xs text-gray-600 file:mr-3 file:rounded-lg file:border-0 file:bg-brand-50 file:px-3 file:py-1.5 file:text-theme-xs file:font-semibold file:text-brand-700 hover:file:bg-brand-100 dark:text-gray-300 dark:file:bg-brand-500/15 dark:file:text-brand-300"
            @change="onCreateFileSelected"
          />
          <p class="mt-1 text-[11px] text-gray-500 dark:text-gray-400">
            Si aún no tienes la factura electrónica del correo, puedes adjuntarla después desde la tabla.
          </p>
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
import { googleMapsUrl, hasCoordinates } from '../utils/maps';

const { currentUser, isAdmin, loadMe, logout } = useAuth();

const rangeOptions = [
  { value: 'week', label: 'Últimos 7 días' },
  { value: 'month', label: 'Últimos 30 días' },
  { value: 'all', label: 'Todo' },
];

const logs = ref([]);
const vehicles = ref([]);
const loading = ref(true);
const saving = ref(false);
const locating = ref(false);
const uploadingRowId = ref(null);
const targetUploadRowId = ref(null);
const modalOpen = ref(false);
const filterVehicleId = ref('');
const filterType = ref('');
const summaryRange = ref('week');
const createReceiptFile = ref(null);
const createReceiptInput = ref(null);
const rowReceiptInput = ref(null);

const meta = reactive({ current_page: 1, last_page: 1, total: 0, from: 0, to: 0 });
const summary = reactive({
  period: { range: 'week' },
  totals: { km_traveled: 0, gallons: 0, cost_usd: 0, cost_per_km: null, km_per_gallon: null, refills_count: 0 },
  by_vehicle: [],
});

const form = reactive({
  vehicle_id: '',
  odometer_km: 0,
  gallons: null,
  cost_usd: null,
  fuel_type: 'regular',
  station: '',
  latitude: null,
  longitude: null,
  location_address: '',
  full_tank: true,
  notes: '',
});

const gmapsLink = (f) =>
  googleMapsUrl({
    destination: f.station || f.location_address || 'Gasolinera',
    destinationAddress: f.location_address,
    latitude: f.latitude,
    longitude: f.longitude,
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

const loadSummary = async () => {
  const { data } = await window.axios.get('/fuel-logs/summary', {
    params: {
      range: summaryRange.value,
      vehicle_id: filterVehicleId.value || undefined,
    },
  });
  summary.period = data.period || { range: summaryRange.value };
  summary.totals = data.totals || {};
  summary.by_vehicle = data.by_vehicle || [];
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

const changeSummaryRange = async (range) => {
  summaryRange.value = range;
  await loadSummary();
};

const onFilterChange = async () => {
  await Promise.all([loadData(1), loadSummary()]);
};

const onVehicleChange = () => {
  const v = vehicles.value.find((item) => Number(item.id) === Number(form.vehicle_id));
  if (v) form.odometer_km = v.current_odometer ?? 0;
};

const captureBrowserGps = () => {
  if (!navigator.geolocation) {
    showErrorAlert('GPS no disponible', 'Este navegador no soporta geolocalización.');
    return;
  }
  locating.value = true;
  navigator.geolocation.getCurrentPosition(
    (pos) => {
      form.latitude = Number(pos.coords.latitude.toFixed(7));
      form.longitude = Number(pos.coords.longitude.toFixed(7));
      locating.value = false;
    },
    () => {
      locating.value = false;
      showErrorAlert('Ubicación denegada', 'Permite el acceso al GPS del navegador o ingresa el nombre de la gasolinera.');
    },
    { enableHighAccuracy: true, timeout: 10000 },
  );
};

const onCreateFileSelected = (ev) => {
  createReceiptFile.value = ev.target?.files?.[0] || null;
};

const openCreate = () => {
  form.vehicle_id = vehicles.value[0]?.id ?? '';
  form.gallons = null;
  form.cost_usd = null;
  form.fuel_type = 'regular';
  form.station = '';
  form.latitude = null;
  form.longitude = null;
  form.location_address = '';
  form.notes = '';
  createReceiptFile.value = null;
  if (createReceiptInput.value) createReceiptInput.value.value = '';
  onVehicleChange();
  modalOpen.value = true;
};

const submitForm = async () => {
  saving.value = true;
  try {
    const fd = new FormData();
    fd.append('vehicle_id', String(form.vehicle_id));
    fd.append('odometer_km', String(form.odometer_km ?? 0));
    fd.append('gallons', String(form.gallons));
    if (form.cost_usd !== null && form.cost_usd !== '') fd.append('cost_usd', String(form.cost_usd));
    fd.append('fuel_type', form.fuel_type);
    if (form.station) fd.append('station', form.station);
    if (form.latitude !== null) fd.append('latitude', String(form.latitude));
    if (form.longitude !== null) fd.append('longitude', String(form.longitude));
    if (form.location_address) fd.append('location_address', form.location_address);
    fd.append('full_tank', form.full_tank ? '1' : '0');
    if (form.notes) fd.append('notes', form.notes);
    if (createReceiptFile.value) fd.append('receipt', createReceiptFile.value);

    await window.axios.post('/fuel-logs', fd, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    await showSuccessAlert('Registrado', 'Carga de combustible guardada.');
    modalOpen.value = false;
    await Promise.all([loadVehicles(), loadData(1), loadSummary()]);
  } catch (err) {
    const errors = err.response?.data?.errors;
    const first = errors ? Object.values(errors).flat()[0] : null;
    await showErrorAlert('Error', first || err.response?.data?.message || 'No se pudo registrar.');
  } finally {
    saving.value = false;
  }
};

const triggerRowReceiptUpload = (f) => {
  targetUploadRowId.value = f.id;
  if (rowReceiptInput.value) {
    rowReceiptInput.value.value = '';
    rowReceiptInput.value.click();
  }
};

const onRowReceiptSelected = async (ev) => {
  const file = ev.target?.files?.[0];
  const rowId = targetUploadRowId.value;
  if (!file || !rowId) return;

  uploadingRowId.value = rowId;
  try {
    const fd = new FormData();
    fd.append('receipt', file);
    await window.axios.post(`/fuel-logs/${rowId}/receipt`, fd, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    await showSuccessAlert('Archivo adjuntado', 'La factura o foto se guardó en el historial.');
    await loadData(meta.current_page);
  } catch (err) {
    const errors = err.response?.data?.errors;
    const first = errors ? Object.values(errors).flat()[0] : null;
    await showErrorAlert('Error al subir archivo', first || err.response?.data?.message || 'Formato o tamaño no válido.');
  } finally {
    uploadingRowId.value = null;
    targetUploadRowId.value = null;
  }
};

const removeFuel = async (f) => {
  const r = await confirmDeleteDialog({ title: '¿Eliminar registro?', text: `${f.gallons} gal` });
  if (!r.isConfirmed) return;
  await window.axios.delete(`/fuel-logs/${f.id}`);
  await showSuccessAlert('Eliminado');
  await Promise.all([loadData(meta.current_page), loadSummary()]);
};

onMounted(async () => {
  await loadMe();
  await Promise.all([loadVehicles(), loadData(1), loadSummary()]);
});
</script>
