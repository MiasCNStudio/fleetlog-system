<template>
  <AdminLayout header-title="Bitácora" :user-name="currentUser?.name" @logout="logout">
    <PageBreadcrumb page-title="Bitácora" subtitle="Registro de salidas, regresos, odómetro y combustible.">
      <template #actions>
        <button
          type="button"
          class="rounded-lg bg-brand-500 px-4 py-2 text-theme-sm font-medium text-white hover:bg-brand-600"
          @click="openCreate"
        >
          Nueva bitácora
        </button>
      </template>
    </PageBreadcrumb>

    <ComponentCard title="Movimientos" desc="Salida y regreso según el último registro de cada vehículo.">
      <div class="mb-4 flex flex-wrap items-end gap-3">
        <div>
          <label class="mb-1 block text-theme-xs font-medium text-gray-600 dark:text-gray-400">Filtrar por vehículo</label>
          <select
            v-model="filterVehicleId"
            class="rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            @change="loadBitacoras(1)"
          >
            <option value="">Todos</option>
            <option v-for="v in vehicleOptions" :key="v.id" :value="String(v.id)">
              {{ v.license_plate }} — {{ v.brand }} {{ v.model }}
            </option>
          </select>
        </div>
        <div>
          <label class="mb-1 block text-theme-xs font-medium text-gray-600 dark:text-gray-400">Tipo</label>
          <select
            v-model="filterType"
            class="rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            @change="loadBitacoras(1)"
          >
            <option value="">Todos</option>
            <option value="salida">Salidas</option>
            <option value="regreso">Regresos</option>
          </select>
        </div>
      </div>

      <div class="overflow-hidden rounded-xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-white/[0.03]">
        <div class="max-w-full overflow-x-auto">
          <table class="min-w-full">
            <thead>
              <tr class="border-b border-gray-200 dark:border-gray-700">
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Fecha y hora</p>
                </th>
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Tipo</p>
                </th>
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Vehículo</p>
                </th>
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Conductor</p>
                </th>
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Odómetro / Comb.</p>
                </th>
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Destino</p>
                </th>
                <th class="px-5 py-3 text-right sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Acciones</p>
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
              <tr v-for="b in bitacoras" :key="b.id" class="border-t border-gray-100 dark:border-gray-800">
                <td class="px-5 py-4 text-theme-sm text-gray-700 dark:text-gray-200 sm:px-6">
                  {{ formatDateTime(b.recorded_at) }}
                </td>
                <td class="px-5 py-4 sm:px-6">
                  <span
                    class="inline-flex rounded-full px-2.5 py-0.5 text-theme-xs font-medium"
                    :class="
                      b.type === 'salida'
                        ? 'bg-amber-500/15 text-amber-700 dark:text-amber-300'
                        : 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-300'
                    "
                  >
                    {{ b.type === 'salida' ? 'Salida' : 'Regreso' }}
                  </span>
                </td>
                <td class="px-5 py-4 font-medium text-gray-800 text-theme-sm dark:text-white/90 sm:px-6">
                  {{ b.vehicle?.license_plate }}
                </td>
                <td class="px-5 py-4 text-theme-sm text-gray-600 dark:text-gray-300 sm:px-6">
                  {{ b.driver?.name || b.user?.name }}
                </td>
                <td class="px-5 py-4 text-theme-sm text-gray-600 dark:text-gray-300 sm:px-6">
                  <span>{{ b.odometer_km !== null && b.odometer_km !== undefined ? `${b.odometer_km.toLocaleString()} km` : '—' }}</span>
                  <span v-if="b.fuel_level" class="ml-1 text-theme-xs text-gray-400">({{ b.fuel_level }})</span>
                </td>
                <td class="max-w-[200px] truncate px-5 py-4 text-theme-sm text-gray-600 dark:text-gray-300 sm:px-6" :title="b.destination || ''">
                  {{ b.destination || '—' }}
                </td>
                <td class="px-5 py-4 text-right sm:px-6">
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
        <div
          v-if="meta.last_page > 1"
          class="flex items-center justify-between border-t border-gray-100 px-4 py-3 dark:border-gray-800"
        >
          <p class="text-theme-sm text-gray-500">
            Página {{ meta.current_page }} de {{ meta.last_page }}
          </p>
          <div class="flex gap-2">
            <button
              type="button"
              class="rounded border border-gray-200 px-3 py-1 text-theme-sm dark:border-gray-700"
              :disabled="meta.current_page <= 1"
              @click="changePage(meta.current_page - 1)"
            >
              Anterior
            </button>
            <button
              type="button"
              class="rounded border border-gray-200 px-3 py-1 text-theme-sm dark:border-gray-700"
              :disabled="meta.current_page >= meta.last_page"
              @click="changePage(meta.current_page + 1)"
            >
              Siguiente
            </button>
          </div>
        </div>
      </div>
    </ComponentCard>

    <div
      v-if="modalOpen"
      class="fixed inset-0 z-[100000] flex items-center justify-center bg-black/50 p-4"
      @click.self="closeModal"
    >
      <div class="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-2xl bg-white p-6 shadow-theme-md dark:bg-gray-900">
        <h2 class="text-lg font-semibold text-gray-900 dark:text-white">
          {{ editingId ? 'Editar bitácora' : 'Nueva bitácora' }}
        </h2>

        <div v-if="!editingId" class="mt-3 space-y-3">
          <div class="rounded-lg border border-gray-200 bg-gray-50 p-3 text-theme-sm dark:border-gray-700 dark:bg-gray-800/50">
            <p class="text-gray-600 dark:text-gray-300">
              <span class="font-medium text-gray-800 dark:text-white">Registró:</span>
              {{ currentUser?.name }}
            </p>
            <p class="mt-1 text-gray-600 dark:text-gray-300">
              <span class="font-medium text-gray-800 dark:text-white">Fecha y hora:</span>
              se registrará al guardar (hora del servidor).
            </p>
          </div>
        </div>

        <form class="mt-4 space-y-4" @submit.prevent="submit">
          <div v-if="!editingId">
            <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Vehículo</label>
            <select
              v-model="form.vehicle_id"
              required
              class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
              @change="onVehicleChange"
            >
              <option value="" disabled>Seleccione…</option>
              <option v-for="v in vehicleOptions" :key="v.id" :value="String(v.id)">
                {{ v.license_plate }} — {{ v.brand }} {{ v.model }} ({{ v.status === 'mantenimiento' ? 'En mantenimiento' : v.next_type }})
              </option>
            </select>
          </div>

          <div v-if="!editingId && nextType" class="flex flex-wrap items-center gap-3">
            <div class="flex items-center gap-2">
              <span class="text-theme-sm text-gray-600 dark:text-gray-300">Movimiento:</span>
              <span
                class="inline-flex rounded-full px-2.5 py-0.5 text-theme-xs font-medium"
                :class="
                  nextType === 'salida'
                    ? 'bg-amber-500/15 text-amber-700 dark:text-amber-300'
                    : 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-300'
                "
              >
                {{ nextType === 'salida' ? 'Salida' : 'Regreso' }}
              </span>
            </div>
            <span v-if="vehicleLastOdometer !== null" class="text-theme-xs text-gray-500">
              Último odómetro: {{ vehicleLastOdometer.toLocaleString() }} km
            </span>
          </div>

          <div v-if="vehicleStatus === 'mantenimiento' && nextType === 'salida'" class="rounded-lg bg-rose-50 p-3 text-theme-sm text-rose-700 dark:bg-rose-500/15 dark:text-rose-300">
            Este vehículo está marcado en mantenimiento. Cambia su estado en Vehículos antes de registrar una salida.
          </div>

          <div v-if="canManageFleet">
            <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Conductor asignado</label>
            <select
              v-model="form.driver_id"
              class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            >
              <option value="">Quien registra ({{ currentUser?.name }})</option>
              <option v-for="d in driverOptions" :key="d.id" :value="String(d.id)">
                {{ d.name }} {{ d.driver_code ? `(${d.driver_code})` : '' }}
              </option>
            </select>
          </div>

          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div>
              <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Odómetro (km)</label>
              <input
                v-model.number="form.odometer_km"
                type="number"
                min="0"
                :placeholder="vehicleLastOdometer !== null ? `Mín. ${vehicleLastOdometer}` : 'Ej. 45200'"
                class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
              />
            </div>
            <div>
              <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Combustible</label>
              <select
                v-model="form.fuel_level"
                class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
              >
                <option value="">Sin especificar</option>
                <option value="lleno">Lleno</option>
                <option value="3/4">3/4</option>
                <option value="1/2">1/2</option>
                <option value="1/4">1/4</option>
                <option value="reserva">Reserva</option>
              </select>
            </div>
          </div>

          <div v-if="!editingId && nextType === 'salida'">
            <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">
              ¿A dónde se dirige? <span class="text-rose-500">*</span>
            </label>
            <textarea
              v-model="form.destination"
              rows="3"
              class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
              placeholder="Dirección o lugar (se usa en el mapa)"
              required
            />
            <p class="mt-1 text-theme-xs text-gray-500">Vista previa con Google Maps:</p>
            <div v-if="destinationMapSrc" class="mt-2 overflow-hidden rounded-lg border border-gray-200 dark:border-gray-700">
              <iframe
                title="Mapa destino"
                class="h-48 w-full border-0"
                loading="lazy"
                referrerpolicy="no-referrer-when-downgrade"
                :src="destinationMapSrc"
              />
            </div>
            <a
              v-if="form.destination?.trim()"
              :href="googleMapsSearchUrl(form.destination)"
              target="_blank"
              rel="noopener noreferrer"
              class="mt-2 inline-block text-theme-sm text-sky-600 underline hover:text-sky-700 dark:text-sky-400"
            >
              Abrir en Google Maps
            </a>
          </div>

          <div v-if="!editingId && nextType === 'regreso'">
            <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Notas de regreso (opcional)</label>
            <textarea
              v-model="form.destination"
              rows="2"
              class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
              placeholder="Observaciones del regreso"
            />
          </div>

          <div v-if="editingId">
            <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Destino / notas</label>
            <textarea
              v-model="form.destination"
              rows="3"
              class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            />
            <div v-if="destinationMapSrc" class="mt-2 overflow-hidden rounded-lg border border-gray-200 dark:border-gray-700">
              <iframe
                title="Mapa destino"
                class="h-40 w-full border-0"
                loading="lazy"
                referrerpolicy="no-referrer-when-downgrade"
                :src="destinationMapSrc"
              />
            </div>
          </div>

          <div>
            <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Personas que acompañan</label>
            <textarea
              v-model="form.companions"
              rows="2"
              class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
              placeholder="Nombres separados por comas, u observaciones"
            />
          </div>

          <div class="flex justify-end gap-2 pt-2">
            <button
              type="button"
              class="rounded-lg border border-gray-200 px-4 py-2 text-theme-sm dark:border-gray-700"
              @click="closeModal"
            >
              Cancelar
            </button>
            <button
              type="submit"
              class="rounded-lg bg-brand-500 px-4 py-2 text-theme-sm font-medium text-white hover:bg-brand-600"
            >
              Guardar
            </button>
          </div>
        </form>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup>
import Swal from 'sweetalert2';
import { computed, onMounted, reactive, ref, watch } from 'vue';
import AdminLayout from '@/components/layout/AdminLayout.vue';
import ComponentCard from '@/components/common/ComponentCard.vue';
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue';
import TableRowActions from '@/components/common/TableRowActions.vue';
import { useAuth } from '../composables/useAuth';

const { currentUser, isAdmin, canManageFleet, loadMe, logout } = useAuth();

const bitacoras = ref([]);
const vehicleOptions = ref([]);
const driverOptions = ref([]);
const meta = ref({ current_page: 1, last_page: 1 });
const filterVehicleId = ref('');
const filterType = ref('');
const modalOpen = ref(false);
const editingId = ref(null);
const nextType = ref(null);
const vehicleStatus = ref(null);
const vehicleLastOdometer = ref(null);

const form = reactive({
  vehicle_id: '',
  driver_id: '',
  odometer_km: null,
  fuel_level: '',
  destination: '',
  companions: '',
});

const destinationMapSrc = computed(() => {
  const q = String(form.destination || '').trim();
  if (!q) return '';
  return `https://www.google.com/maps?q=${encodeURIComponent(q)}&output=embed`;
});

const googleMapsSearchUrl = (query) =>
  `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(String(query || '').trim())}`;

const formatDateTime = (iso) => {
  if (!iso) return '';
  const d = new Date(iso);
  return d.toLocaleString('es-HN', { dateStyle: 'short', timeStyle: 'medium' });
};

const loadVehicles = async () => {
  const { data } = await window.axios.get('/vehicles/options');
  vehicleOptions.value = data.data || [];
};

const loadDrivers = async () => {
  const { data } = await window.axios.get('/drivers/options');
  driverOptions.value = data.data || [];
};

const loadBitacoras = async (page = 1) => {
  const params = { page, per_page: 15 };
  if (filterVehicleId.value) params.vehicle_id = filterVehicleId.value;
  if (filterType.value) params.type = filterType.value;
  const { data } = await window.axios.get('/bitacoras', { params });
  bitacoras.value = data.data;
  meta.value = {
    current_page: data.current_page,
    last_page: data.last_page,
  };
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

const openCreate = () => {
  editingId.value = null;
  form.vehicle_id = '';
  form.driver_id = '';
  form.odometer_km = null;
  form.fuel_level = '';
  form.destination = '';
  form.companions = '';
  nextType.value = null;
  vehicleStatus.value = null;
  vehicleLastOdometer.value = null;
  modalOpen.value = true;
};

const openEdit = (b) => {
  editingId.value = b.id;
  form.vehicle_id = String(b.vehicle_id);
  form.driver_id = b.driver_id ? String(b.driver_id) : '';
  form.odometer_km = b.odometer_km ?? null;
  form.fuel_level = b.fuel_level || '';
  form.destination = b.destination || '';
  form.companions = b.companions || '';
  nextType.value = null;
  vehicleStatus.value = null;
  vehicleLastOdometer.value = null;
  modalOpen.value = true;
};

const esc = (v) =>
  String(v ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

const openView = (b) => {
  const dest = b.destination && String(b.destination).trim();
  const mapLink = dest ? googleMapsSearchUrl(dest) : '';
  const mapIframe =
    dest &&
    `<div class="mt-3 overflow-hidden rounded-lg border border-gray-200"><iframe class="h-48 w-full border-0" loading="lazy" src="https://www.google.com/maps?q=${encodeURIComponent(dest)}&output=embed"></iframe></div>`;
  Swal.fire({
    title: esc(b.vehicle?.license_plate),
    html: `
      <div class="text-left text-theme-sm space-y-2 text-gray-700">
        <p><strong>Fecha:</strong> ${esc(formatDateTime(b.recorded_at))}</p>
        <p><strong>Tipo:</strong> ${b.type === 'salida' ? 'Salida' : 'Regreso'}</p>
        <p><strong>Conductor:</strong> ${esc(b.driver?.name || b.user?.name)}</p>
        <p><strong>Registró:</strong> ${esc(b.user?.name)}</p>
        <p><strong>Odómetro:</strong> ${b.odometer_km !== null && b.odometer_km !== undefined ? `${b.odometer_km.toLocaleString()} km` : '—'}</p>
        <p><strong>Combustible:</strong> ${esc(b.fuel_level || '—')}</p>
        <p><strong>Destino / notas:</strong> ${dest ? esc(dest) : '—'}</p>
        <p><strong>Acompañantes:</strong> ${b.companions ? esc(b.companions) : '—'}</p>
        ${mapLink ? `<p><a href="${esc(mapLink)}" target="_blank" rel="noopener noreferrer" class="text-sky-600 underline">Abrir destino en Google Maps</a></p>` : ''}
      </div>
      ${mapIframe || ''}
    `,
    confirmButtonText: 'Cerrar',
    showCloseButton: true,
    width: 560,
  });
};

const closeModal = () => {
  modalOpen.value = false;
};

const submit = async () => {
  try {
    if (!editingId.value && nextType.value === 'salida' && !String(form.destination || '').trim()) {
      await Swal.fire({ icon: 'warning', title: 'Destino requerido', text: 'Indique a dónde se dirige el vehículo.' });
      return;
    }

    const payload = {
      driver_id: form.driver_id ? Number(form.driver_id) : null,
      odometer_km: form.odometer_km !== null && form.odometer_km !== '' ? Number(form.odometer_km) : null,
      fuel_level: form.fuel_level || null,
      destination: form.destination?.trim() || null,
      companions: form.companions || null,
    };

    if (editingId.value) {
      await window.axios.put(`/bitacoras/${editingId.value}`, payload);
    } else {
      await window.axios.post('/bitacoras', {
        ...payload,
        vehicle_id: Number(form.vehicle_id),
      });
    }
    await Swal.fire({ icon: 'success', title: 'Guardado', timer: 1400, showConfirmButton: false });
    closeModal();
    await Promise.all([loadVehicles(), loadBitacoras(meta.value.current_page)]);
  } catch (err) {
    const errors = err.response?.data?.errors;
    const firstErr = errors ? Object.values(errors).flat()[0] : null;
    const msg = firstErr || err.response?.data?.message || 'No se pudo guardar';
    await Swal.fire({ icon: 'error', title: 'Error', text: msg });
  }
};

const confirmDelete = async (b) => {
  const r = await Swal.fire({
    icon: 'warning',
    title: '¿Eliminar registro de bitácora?',
    showCancelButton: true,
    confirmButtonText: 'Sí, eliminar',
    cancelButtonText: 'Cancelar',
  });
  if (!r.isConfirmed) return;
  try {
    await window.axios.delete(`/bitacoras/${b.id}`);
    await Swal.fire({ icon: 'success', title: 'Eliminado', timer: 1200, showConfirmButton: false });
    await Promise.all([loadVehicles(), loadBitacoras(meta.value.current_page)]);
  } catch (err) {
    await Swal.fire({ icon: 'error', title: err.response?.data?.message || 'No se pudo eliminar' });
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
  await Promise.all([loadVehicles(), loadDrivers(), loadBitacoras(1)]);
});
</script>
