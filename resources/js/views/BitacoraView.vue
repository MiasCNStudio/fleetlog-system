<template>
  <AdminLayout header-title="Bitácora" :user-name="currentUser?.name" @logout="logout(true)">
    <PageBreadcrumb page-title="Bitácora" subtitle="Registro de salidas, regresos, odómetro, combustible y ubicación exacta.">
      <template #actions>
        <div class="flex flex-wrap items-center gap-2">
          <router-link to="/asignaciones" class="fleet-btn-secondary">
            Ver asignaciones
          </router-link>
          <button type="button" class="fleet-btn-primary" @click="openCreate">
            <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
            </svg>
            Nueva bitácora
          </button>
        </div>
      </template>
    </PageBreadcrumb>

    <ComponentCard title="Movimientos" desc="Salida y regreso según el último registro de cada vehículo.">
      <template #header-extra>
        <span class="rounded-lg bg-gray-100 px-2.5 py-1 text-theme-xs font-semibold tabular-nums text-gray-600 dark:bg-gray-800 dark:text-gray-300">
          {{ meta.total }} {{ meta.total === 1 ? 'registro' : 'registros' }}
        </span>
      </template>

      <div class="fleet-filter-bar grid grid-cols-1 gap-3 sm:flex sm:flex-wrap sm:items-end">
        <div class="w-full sm:w-64">
          <label for="bitacora-filter-vehicle" class="fleet-label">Vehículo</label>
          <select
            id="bitacora-filter-vehicle"
            v-model="filterVehicleId"
            class="fleet-select"
            @change="loadBitacoras(1)"
          >
            <option value="">Todos los vehículos</option>
            <option v-for="v in vehicleOptions" :key="v.id" :value="String(v.id)">
              {{ v.license_plate }} — {{ v.brand }} {{ v.model }}
            </option>
          </select>
        </div>

        <div class="w-full sm:w-44">
          <label for="bitacora-filter-type" class="fleet-label">Tipo</label>
          <select
            id="bitacora-filter-type"
            v-model="filterType"
            class="fleet-select"
            @change="loadBitacoras(1)"
          >
            <option value="">Todos</option>
            <option value="salida">Salidas</option>
            <option value="regreso">Regresos</option>
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
                <th scope="col" class="fleet-th">Fecha y hora</th>
                <th scope="col" class="fleet-th">Tipo</th>
                <th scope="col" class="fleet-th">Vehículo</th>
                <th scope="col" class="fleet-th">Conductor</th>
                <th scope="col" class="fleet-th">Odómetro / Comb.</th>
                <th scope="col" class="fleet-th">Destino</th>
                <th scope="col" class="fleet-th text-right">Acciones</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
              <tr v-if="loading" v-for="n in 5" :key="`sk-${n}`" class="animate-pulse">
                <td v-for="c in 7" :key="c" class="fleet-td">
                  <div class="h-4 w-full max-w-[120px] rounded bg-gray-200 dark:bg-gray-800" />
                </td>
              </tr>

              <tr v-else-if="bitacoras.length === 0">
                <td colspan="7" class="p-0">
                  <TableEmptyState
                    icon="clipboard"
                    :has-filters="hasFilters"
                    :title="hasFilters ? 'Sin movimientos para estos filtros' : 'Aún no hay movimientos registrados'"
                    :description="
                      hasFilters
                        ? 'Prueba cambiando el vehículo o el tipo de movimiento.'
                        : 'Registra la primera salida o regreso de una unidad.'
                    "
                    @reset="resetFilters"
                  />
                </td>
              </tr>

              <tr v-for="b in bitacoras" v-else :key="b.id" class="fleet-tr">
                <td class="fleet-td whitespace-nowrap text-theme-xs tabular-nums">
                  {{ formatDateTime(b.recorded_at) }}
                </td>
                <td class="fleet-td whitespace-nowrap">
                  <StatusBadge kind="bitacoraType" :value="b.type" />
                </td>
                <td class="fleet-td whitespace-nowrap">
                  <span class="rounded-md bg-gray-100 px-2 py-0.5 font-mono text-theme-xs font-semibold text-gray-900 dark:bg-gray-800 dark:text-white">
                    {{ b.vehicle?.license_plate }}
                  </span>
                </td>
                <td class="fleet-td max-w-[125px] truncate text-gray-600 dark:text-gray-300 xl:max-w-[165px]" :title="b.driver?.name || b.user?.name || ''">
                  <p class="truncate">{{ b.driver?.name || b.user?.name }}</p>
                  <span
                    v-if="b.assignment?.is_emergency_reassigned"
                    class="mt-0.5 inline-block rounded bg-rose-500/15 px-1.5 py-0.5 text-[10px] font-semibold text-rose-700 dark:text-rose-300"
                  >
                    Emergencia
                  </span>
                </td>
                <td class="fleet-td whitespace-nowrap tabular-nums text-gray-600 dark:text-gray-300">
                  <span>{{ b.odometer_km !== null && b.odometer_km !== undefined ? `${b.odometer_km.toLocaleString()} km` : '—' }}</span>
                  <span v-if="b.fuel_level" class="ml-1.5 rounded bg-gray-100 px-1.5 py-0.5 text-[11px] font-medium text-gray-600 dark:bg-gray-800 dark:text-gray-300">
                    {{ b.fuel_level }}
                  </span>
                </td>
                <td class="fleet-td max-w-[160px] xl:max-w-[220px]">
                  <p class="truncate text-gray-700 dark:text-gray-200" :title="b.destination || ''">
                    {{ b.destination || '—' }}
                  </p>
                  <div v-if="b.destination || hasCoordinates(b.latitude, b.longitude)" class="mt-0.5 flex items-center gap-2 text-[11px]">
                    <a
                      :href="gmapsLink(b)"
                      target="_blank"
                      rel="noopener noreferrer"
                      class="font-medium text-brand-600 hover:underline dark:text-brand-400"
                    >
                      Maps ↗
                    </a>
                    <a
                      :href="wazeLink(b)"
                      target="_blank"
                      rel="noopener noreferrer"
                      class="font-medium text-sky-600 hover:underline dark:text-sky-400"
                    >
                      Waze ↗
                    </a>
                  </div>
                </td>
                <td class="fleet-td whitespace-nowrap text-right">
                  <TableRowActions
                    :group-label="`Acciones bitácora ${b.id}`"
                    :show-edit="canManageFleet"
                    :show-delete="isAdmin"
                    @view="openView(b)"
                    @edit="openEdit(b)"
                    @delete="confirmDelete(b)"
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
      max-width="xl"
      :title="editingId ? 'Editar bitácora' : 'Nueva bitácora'"
      :subtitle="editingId ? 'Actualiza los datos del movimiento registrado.' : 'El tipo de movimiento se calcula automáticamente según la unidad.'"
      @close="closeModal"
    >
      <div v-if="!editingId" class="mb-4 rounded-xl border border-gray-200/80 bg-gray-50/80 p-3.5 text-theme-xs dark:border-white/[0.07] dark:bg-white/[0.02]">
        <div class="flex flex-wrap items-center justify-between gap-2">
          <p class="text-gray-600 dark:text-gray-300">
            <span class="font-semibold text-gray-900 dark:text-white">Registró:</span>
            {{ currentUser?.name }}
          </p>
          <p class="text-gray-500 dark:text-gray-400">
            Hora automática del servidor al guardar
          </p>
        </div>
      </div>

      <div
        v-if="!editingId && !canManageFleet && assignmentOptions.length === 0"
        class="mb-4 rounded-xl border border-amber-200 bg-amber-50 p-4 text-theme-sm text-amber-900 dark:border-amber-500/30 dark:bg-amber-500/10 dark:text-amber-100"
      >
        <p class="font-semibold">No tienes asignaciones activas en este momento.</p>
        <p class="mt-1 text-theme-xs">
          Para iniciar una salida necesitas una asignación o tomar un viaje por emergencia desde Asignaciones. (Si vas a registrar el regreso de una unidad en ruta, selecciona el vehículo abajo).
        </p>
        <router-link to="/asignaciones" class="fleet-btn-secondary mt-3 h-9 px-3.5 py-1.5 text-theme-xs" @click="closeModal">
          Ir a Asignaciones →
        </router-link>
      </div>

      <form id="bitacora-form" class="space-y-4" @submit.prevent="submit">
        <div v-if="!editingId && assignmentOptions.length > 0">
          <label for="bitacora-assignment" class="fleet-field-label">
            Asignación programada {{ canManageFleet ? '(opcional)' : '' }}
          </label>
          <select
            id="bitacora-assignment"
            v-model="form.assignment_id"
            class="fleet-select"
            @change="onAssignmentChange"
          >
            <option value="">
              {{ canManageFleet ? 'Bitácora directa (sin asignación)' : 'Seleccionar asignación / regreso…' }}
            </option>
            <option v-for="a in assignmentOptions" :key="a.id" :value="String(a.id)">
              {{ formatShortDate(a.scheduled_date) }} · {{ a.vehicle?.license_plate }} · {{ a.destination }} ({{ a.status === 'en_curso' ? 'Regreso' : 'Salida' }})
            </option>
          </select>
        </div>

        <div
          v-if="!editingId && selectedAssignment?.official_instruction"
          class="rounded-xl border border-amber-300 bg-amber-50 p-3.5 dark:border-amber-500/35 dark:bg-amber-500/10"
        >
          <p class="text-[11px] font-bold uppercase tracking-wider text-amber-800 dark:text-amber-300">
            Instrucción oficial de la asignación
          </p>
          <p class="mt-1 text-theme-sm font-medium text-amber-950 dark:text-amber-100">
            {{ selectedAssignment.official_instruction }}
          </p>
        </div>

        <div v-if="!editingId">
          <label for="bitacora-vehicle" class="fleet-field-label">
            Vehículo <span class="text-rose-500">*</span>
          </label>
          <select
            id="bitacora-vehicle"
            v-model="form.vehicle_id"
            required
            :disabled="Boolean(form.assignment_id)"
            class="fleet-select"
            @change="onVehicleChange"
          >
            <option value="" disabled>Seleccione una unidad…</option>
            <option v-for="v in vehicleOptions" :key="v.id" :value="String(v.id)">
              {{ v.license_plate }} — {{ v.brand }} {{ v.model }} ({{ v.status === 'mantenimiento' ? 'En mantenimiento' : v.next_type }})
            </option>
          </select>
        </div>

        <div
          v-if="!editingId && nextType"
          class="flex flex-wrap items-center justify-between gap-2 rounded-xl border border-gray-200 bg-gray-50/70 px-3.5 py-2.5 dark:border-white/[0.07] dark:bg-white/[0.02]"
        >
          <div class="flex items-center gap-2">
            <span class="text-theme-xs font-medium text-gray-600 dark:text-gray-300">Movimiento detectado:</span>
            <StatusBadge kind="bitacoraType" :value="nextType" />
          </div>
          <span v-if="vehicleLastOdometer !== null" class="text-theme-xs font-medium tabular-nums text-gray-600 dark:text-gray-400">
            Último odómetro: {{ vehicleLastOdometer.toLocaleString() }} km
          </span>
        </div>

        <div
          v-if="vehicleStatus === 'mantenimiento' && nextType === 'salida'"
          class="rounded-xl border border-rose-200 bg-rose-50 p-3.5 text-theme-sm text-rose-700 dark:border-rose-500/30 dark:bg-rose-500/10 dark:text-rose-300"
          role="alert"
        >
          Este vehículo está marcado en mantenimiento. Cambia su estado en Vehículos antes de registrar una salida.
        </div>

        <div v-if="canManageFleet">
          <label for="bitacora-driver" class="fleet-field-label">Conductor asignado</label>
          <select id="bitacora-driver" v-model="form.driver_id" class="fleet-select">
            <option value="">Quien registra ({{ currentUser?.name }})</option>
            <option v-for="d in driverOptions" :key="d.id" :value="String(d.id)">
              {{ d.name }} {{ d.driver_code ? `(${d.driver_code})` : '' }}
            </option>
          </select>
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div>
            <label for="bitacora-odometer" class="fleet-field-label">Odómetro (km)</label>
            <input
              id="bitacora-odometer"
              v-model.number="form.odometer_km"
              type="number"
              min="0"
              :placeholder="vehicleLastOdometer !== null ? `Mín. ${vehicleLastOdometer}` : 'Ej. 45200'"
              class="fleet-input tabular-nums"
            />
          </div>
          <div>
            <label for="bitacora-fuel" class="fleet-field-label">Combustible</label>
            <select id="bitacora-fuel" v-model="form.fuel_level" class="fleet-select">
              <option value="">Sin especificar</option>
              <option value="lleno">Lleno</option>
              <option value="3/4">3/4</option>
              <option value="1/2">1/2</option>
              <option value="1/4">1/4</option>
              <option value="reserva">Reserva</option>
            </select>
          </div>
        </div>

        <div v-if="(!editingId && nextType === 'salida') || editingId">
          <MapLocationPicker
            v-model:destination="form.destination"
            v-model:destination-address="form.destination_address"
            v-model:latitude="form.latitude"
            v-model:longitude="form.longitude"
            v-model:place-id="form.place_id"
            :label="editingId ? 'Destino / ubicación en mapa' : '¿A dónde se dirige? (selecciona en mapa)'"
            :required="!editingId && nextType === 'salida'"
          />
        </div>

        <div v-if="!editingId && nextType === 'regreso'">
          <label for="bitacora-destination-in" class="fleet-field-label">Notas de regreso (opcional)</label>
          <textarea
            id="bitacora-destination-in"
            v-model="form.destination"
            rows="2"
            class="fleet-textarea"
            placeholder="Observaciones del regreso"
          />
        </div>

        <div>
          <label for="bitacora-companions" class="fleet-field-label">Personas que acompañan</label>
          <textarea
            id="bitacora-companions"
            v-model="form.companions"
            rows="2"
            class="fleet-textarea"
            placeholder="Nombres separados por comas, u observaciones"
          />
        </div>
      </form>

      <template #footer>
        <button type="button" class="fleet-btn-secondary" @click="closeModal">
          Cancelar
        </button>
        <button type="submit" form="bitacora-form" :disabled="saving" class="fleet-btn-primary">
          {{ saving ? 'Guardando…' : 'Guardar' }}
        </button>
      </template>
    </BaseModal>

    <BaseModal
      :open="detailOpen"
      max-width="xl"
      :title="detailItem?.vehicle?.license_plate ? `Bitácora · ${detailItem.vehicle.license_plate}` : 'Detalle de bitácora'"
      :subtitle="detailItem ? `${detailItem.vehicle?.brand || ''} ${detailItem.vehicle?.model || ''}`.trim() : ''"
      @close="detailOpen = false"
    >
      <div v-if="detailItem" class="space-y-4">
        <div class="flex flex-wrap items-center justify-between gap-2 rounded-xl border border-gray-200/80 bg-gray-50/80 px-4 py-3 dark:border-white/[0.07] dark:bg-white/[0.02]">
          <StatusBadge kind="bitacoraType" :value="detailItem.type" />
          <span class="text-theme-xs font-medium tabular-nums text-gray-500 dark:text-gray-400">
            {{ formatDateTime(detailItem.recorded_at) }}
          </span>
        </div>

        <div
          v-if="detailItem.official_instruction"
          class="rounded-xl border border-amber-300 bg-amber-50 p-3.5 dark:border-amber-500/35 dark:bg-amber-500/10"
        >
          <p class="text-[11px] font-bold uppercase tracking-wider text-amber-800 dark:text-amber-300">
            Instrucción oficial
          </p>
          <p class="mt-1 text-theme-sm font-medium text-amber-950 dark:text-amber-100">
            {{ detailItem.official_instruction }}
          </p>
        </div>

        <div
          v-if="detailItem.assignment?.is_emergency_reassigned"
          class="rounded-xl border border-rose-200 bg-rose-50 p-3.5 dark:border-rose-500/30 dark:bg-rose-500/10"
        >
          <p class="text-[11px] font-bold uppercase tracking-wider text-rose-700 dark:text-rose-300">
            Viaje tomado por emergencia
          </p>
          <p class="mt-1 text-theme-xs text-rose-900 dark:text-rose-100">
            Sustituyó a <strong>{{ detailItem.assignment.original_driver?.name || 'motorista titular' }}</strong> ·
            Razón: {{ detailItem.assignment.reassignment_reason }}
          </p>
        </div>

        <dl class="grid grid-cols-1 gap-3 text-theme-sm sm:grid-cols-2">
          <div class="rounded-xl border border-gray-100 p-3 dark:border-white/[0.07]">
            <dt class="text-theme-xs text-gray-500 dark:text-gray-400">Conductor</dt>
            <dd class="mt-0.5 font-medium text-gray-900 dark:text-white">
              {{ detailItem.driver?.name || detailItem.user?.name || '—' }}
            </dd>
          </div>
          <div class="rounded-xl border border-gray-100 p-3 dark:border-white/[0.07]">
            <dt class="text-theme-xs text-gray-500 dark:text-gray-400">Registró</dt>
            <dd class="mt-0.5 font-medium text-gray-900 dark:text-white">
              {{ detailItem.user?.name || '—' }}
            </dd>
          </div>
          <div class="rounded-xl border border-gray-100 p-3 dark:border-white/[0.07]">
            <dt class="text-theme-xs text-gray-500 dark:text-gray-400">Odómetro</dt>
            <dd class="mt-0.5 font-medium tabular-nums text-gray-900 dark:text-white">
              {{ detailItem.odometer_km !== null && detailItem.odometer_km !== undefined ? `${detailItem.odometer_km.toLocaleString()} km` : '—' }}
            </dd>
          </div>
          <div class="rounded-xl border border-gray-100 p-3 dark:border-white/[0.07]">
            <dt class="text-theme-xs text-gray-500 dark:text-gray-400">Combustible</dt>
            <dd class="mt-0.5 font-medium text-gray-900 dark:text-white">
              {{ detailItem.fuel_level || '—' }}
            </dd>
          </div>
        </dl>

        <div class="rounded-xl border border-gray-100 p-3.5 text-theme-sm dark:border-white/[0.07]">
          <p class="text-theme-xs font-medium text-gray-500 dark:text-gray-400">Destino / notas</p>
          <p class="mt-1 whitespace-pre-line font-medium text-gray-900 dark:text-gray-100">
            {{ detailItem.destination || '—' }}
          </p>
          <p v-if="detailItem.destination_address" class="mt-0.5 text-theme-xs text-gray-500 dark:text-gray-400">
            {{ detailItem.destination_address }}
          </p>
          <p v-if="hasCoordinates(detailItem.latitude, detailItem.longitude)" class="mt-1 font-mono text-[11px] text-gray-500">
            {{ formatCoordinates(detailItem.latitude, detailItem.longitude) }}
          </p>
          <div v-if="detailItem.destination?.trim() || hasCoordinates(detailItem.latitude, detailItem.longitude)" class="mt-3 flex flex-wrap gap-2">
            <a :href="gmapsLink(detailItem)" target="_blank" rel="noopener noreferrer" class="fleet-btn-primary h-9 px-3.5 py-1.5 text-theme-xs">
              Abrir en Google Maps ↗
            </a>
            <a :href="wazeLink(detailItem)" target="_blank" rel="noopener noreferrer" class="fleet-btn-secondary h-9 px-3.5 py-1.5 text-theme-xs">
              Abrir en Waze ↗
            </a>
          </div>
        </div>

        <div class="rounded-xl border border-gray-100 p-3.5 text-theme-sm dark:border-white/[0.07]">
          <p class="text-theme-xs font-medium text-gray-500 dark:text-gray-400">Acompañantes</p>
          <p class="mt-1 text-gray-900 dark:text-gray-100">
            {{ detailItem.companions || '—' }}
          </p>
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
import { computed, onMounted, reactive, ref, watch } from 'vue';
import AdminLayout from '@/components/layout/AdminLayout.vue';
import BaseModal from '@/components/common/BaseModal.vue';
import ComponentCard from '@/components/common/ComponentCard.vue';
import MapLocationPicker from '@/components/common/MapLocationPicker.vue';
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue';
import StatusBadge from '@/components/common/StatusBadge.vue';
import TableEmptyState from '@/components/common/TableEmptyState.vue';
import TablePagination from '@/components/common/TablePagination.vue';
import TableRowActions from '@/components/common/TableRowActions.vue';
import { useAuth } from '../composables/useAuth';
import {
  confirmDeleteDialog,
  showErrorAlert,
  showSuccessAlert,
  showWarningAlert,
} from '../utils/alerts';
import { formatCoordinates, googleMapsUrl, hasCoordinates, wazeUrl } from '../utils/maps';

const { currentUser, isAdmin, canManageFleet, loadMe, logout } = useAuth();

const bitacoras = ref([]);
const vehicleOptions = ref([]);
const driverOptions = ref([]);
const assignmentOptions = ref([]);
const loading = ref(true);
const saving = ref(false);
const meta = ref({ current_page: 1, last_page: 1, total: 0, from: 0, to: 0 });
const filterVehicleId = ref('');
const filterType = ref('');
const modalOpen = ref(false);
const detailOpen = ref(false);
const detailItem = ref(null);
const editingId = ref(null);
const nextType = ref(null);
const vehicleStatus = ref(null);
const vehicleLastOdometer = ref(null);

const form = reactive({
  assignment_id: '',
  vehicle_id: '',
  driver_id: '',
  odometer_km: null,
  fuel_level: '',
  destination: '',
  destination_address: '',
  latitude: null,
  longitude: null,
  place_id: '',
  companions: '',
  official_instruction: '',
});

const hasFilters = computed(() => Boolean(filterVehicleId.value || filterType.value));

const selectedAssignment = computed(() =>
  assignmentOptions.value.find((a) => String(a.id) === String(form.assignment_id)) || null,
);

const gmapsLink = (item) =>
  googleMapsUrl({
    destination: item?.destination,
    destinationAddress: item?.destination_address,
    latitude: item?.latitude,
    longitude: item?.longitude,
  });

const wazeLink = (item) =>
  wazeUrl({
    destination: item?.destination,
    destinationAddress: item?.destination_address,
    latitude: item?.latitude,
    longitude: item?.longitude,
  });

const formatDateTime = (iso) => {
  if (!iso) return '';
  const d = new Date(iso);
  return d.toLocaleString('es-HN', { dateStyle: 'short', timeStyle: 'medium' });
};

const formatShortDate = (dateStr) => {
  if (!dateStr) return '';
  const clean = String(dateStr).slice(0, 10);
  const [y, m, d] = clean.split('-');
  return y && m && d ? `${d}/${m}/${y}` : dateStr;
};

const loadVehicles = async () => {
  const { data } = await window.axios.get('/vehicles/options');
  vehicleOptions.value = data.data || [];
};

const loadDrivers = async () => {
  const { data } = await window.axios.get('/drivers/options');
  driverOptions.value = data.data || [];
};

const loadAssignmentOptions = async () => {
  try {
    const { data } = await window.axios.get('/assignments/options');
    assignmentOptions.value = data.data || [];
  } catch (_) {
    assignmentOptions.value = [];
  }
};

const loadBitacoras = async (page = 1) => {
  loading.value = true;
  try {
    const params = { page, per_page: 15 };
    if (filterVehicleId.value) params.vehicle_id = filterVehicleId.value;
    if (filterType.value) params.type = filterType.value;
    const { data } = await window.axios.get('/bitacoras', { params });
    bitacoras.value = data.data || [];
    meta.value = {
      current_page: data.current_page ?? 1,
      last_page: data.last_page ?? 1,
      total: data.total ?? bitacoras.value.length,
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
  filterVehicleId.value = '';
  filterType.value = '';
  loadBitacoras(1);
};

const changePage = (page) => {
  if (page < 1 || page > meta.value.last_page) return;
  loadBitacoras(page);
};

const fetchNextType = async (vehicleId) => {
  if (!vehicleId) {
    nextType.value = null;
    vehicleStatus.value = null;
    vehicleLastOdometer.value = null;
    return;
  }
  const { data } = await window.axios.get(`/vehicles/${vehicleId}/siguiente-tipo-bitacora`);
  nextType.value = data.type;
  vehicleStatus.value = data.status;
  vehicleLastOdometer.value = data.current_odometer ?? 0;
  if (!editingId.value && form.odometer_km === null) {
    form.odometer_km = data.current_odometer ?? null;
  }
};

const onVehicleChange = async () => {
  form.odometer_km = null;
  await fetchNextType(form.vehicle_id);
};

const onAssignmentChange = async () => {
  const a = selectedAssignment.value;
  if (!a) {
    form.vehicle_id = '';
    form.driver_id = '';
    form.destination = '';
    form.destination_address = '';
    form.latitude = null;
    form.longitude = null;
    form.place_id = '';
    form.companions = '';
    form.official_instruction = '';
    return;
  }
  form.vehicle_id = String(a.vehicle_id);
  form.driver_id = a.driver_id ? String(a.driver_id) : '';
  form.destination = a.destination || '';
  form.destination_address = a.destination_address || '';
  form.latitude = a.latitude ?? null;
  form.longitude = a.longitude ?? null;
  form.place_id = a.place_id || '';
  form.companions = a.companions || '';
  form.official_instruction = a.official_instruction || '';
  form.odometer_km = null;
  await fetchNextType(form.vehicle_id);
};

const openCreate = () => {
  editingId.value = null;
  form.assignment_id = '';
  form.vehicle_id = '';
  form.driver_id = '';
  form.odometer_km = null;
  form.fuel_level = '';
  form.destination = '';
  form.destination_address = '';
  form.latitude = null;
  form.longitude = null;
  form.place_id = '';
  form.companions = '';
  form.official_instruction = '';
  nextType.value = null;
  vehicleStatus.value = null;
  vehicleLastOdometer.value = null;
  modalOpen.value = true;
};

const openEdit = (b) => {
  editingId.value = b.id;
  form.assignment_id = b.assignment_id ? String(b.assignment_id) : '';
  form.vehicle_id = String(b.vehicle_id);
  form.driver_id = b.driver_id ? String(b.driver_id) : '';
  form.odometer_km = b.odometer_km ?? null;
  form.fuel_level = b.fuel_level || '';
  form.destination = b.destination || '';
  form.destination_address = b.destination_address || '';
  form.latitude = b.latitude ?? null;
  form.longitude = b.longitude ?? null;
  form.place_id = b.place_id || '';
  form.companions = b.companions || '';
  form.official_instruction = b.official_instruction || '';
  nextType.value = null;
  vehicleStatus.value = null;
  vehicleLastOdometer.value = null;
  modalOpen.value = true;
};

const openView = (b) => {
  detailItem.value = b;
  detailOpen.value = true;
};

const closeModal = () => {
  modalOpen.value = false;
};

const submit = async () => {
  if (saving.value) return;
  if (!editingId.value && nextType.value === 'salida' && !String(form.destination || '').trim()) {
    await showWarningAlert('Destino requerido', 'Indique o seleccione en el mapa a dónde se dirige el vehículo.');
    return;
  }

  saving.value = true;
  try {
    const payload = {
      driver_id: form.driver_id ? Number(form.driver_id) : null,
      odometer_km: form.odometer_km !== null && form.odometer_km !== '' ? Number(form.odometer_km) : null,
      fuel_level: form.fuel_level || null,
      destination: form.destination?.trim() || null,
      destination_address: form.destination_address?.trim() || null,
      latitude: form.latitude !== null && form.latitude !== '' ? Number(form.latitude) : null,
      longitude: form.longitude !== null && form.longitude !== '' ? Number(form.longitude) : null,
      place_id: form.place_id || null,
      companions: form.companions || null,
      official_instruction: form.official_instruction || null,
    };

    if (editingId.value) {
      await window.axios.put(`/bitacoras/${editingId.value}`, payload);
    } else {
      await window.axios.post('/bitacoras', {
        ...payload,
        vehicle_id: Number(form.vehicle_id),
        assignment_id: form.assignment_id ? Number(form.assignment_id) : null,
      });
    }
    await showSuccessAlert('Guardado');
    closeModal();
    await Promise.all([loadVehicles(), loadAssignmentOptions(), loadBitacoras(meta.value.current_page)]);
  } catch (err) {
    const errors = err.response?.data?.errors;
    const firstErr = errors ? Object.values(errors).flat()[0] : null;
    const msg = firstErr || err.response?.data?.message || 'No se pudo guardar';
    await showErrorAlert('Error', msg);
  } finally {
    saving.value = false;
  }
};

const confirmDelete = async (b) => {
  const r = await confirmDeleteDialog({
    title: '¿Eliminar registro de bitácora?',
    text: b.vehicle?.license_plate ? `${b.vehicle.license_plate} · ${formatDateTime(b.recorded_at)}` : '',
  });
  if (!r.isConfirmed) return;
  try {
    await window.axios.delete(`/bitacoras/${b.id}`);
    await showSuccessAlert('Eliminado');
    await Promise.all([loadVehicles(), loadAssignmentOptions(), loadBitacoras(meta.value.current_page)]);
  } catch (err) {
    await showErrorAlert('Error', err.response?.data?.message || 'No se pudo eliminar');
  }
};

watch(
  () => form.vehicle_id,
  async (id) => {
    if (modalOpen.value && !editingId.value && id) {
      await fetchNextType(id);
    }
  },
);

onMounted(async () => {
  await loadMe();
  await Promise.all([loadVehicles(), loadDrivers(), loadAssignmentOptions(), loadBitacoras(1)]);
});
</script>
