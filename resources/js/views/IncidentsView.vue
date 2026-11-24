<template>
  <AdminLayout header-title="Incidencias" :user-name="currentUser?.name" @logout="logout">
    <PageBreadcrumb page-title="Incidencias" subtitle="Reportes de fallas, accidentes o novedades de las unidades.">
      <template #actions>
        <button
          type="button"
          class="rounded-lg bg-brand-500 px-4 py-2 text-theme-sm font-medium text-white hover:bg-brand-600"
          @click="openCreate"
        >
          Reportar incidencia
        </button>
      </template>
    </PageBreadcrumb>

    <ComponentCard title="Historial de incidencias" desc="Seguimiento por vehículo, severidad y estado.">
      <div class="mb-4 flex flex-wrap items-end gap-3">
        <div>
          <label class="mb-1 block text-theme-xs font-medium text-gray-600 dark:text-gray-400">Vehículo</label>
          <select
            v-model="filterVehicleId"
            class="rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            @change="loadIncidents(1)"
          >
            <option value="">Todos</option>
            <option v-for="v in vehicleOptions" :key="v.id" :value="String(v.id)">
              {{ v.license_plate }} — {{ v.brand }} {{ v.model }}
            </option>
          </select>
        </div>
        <div>
          <label class="mb-1 block text-theme-xs font-medium text-gray-600 dark:text-gray-400">Estado</label>
          <select
            v-model="filterStatus"
            class="rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            @change="loadIncidents(1)"
          >
            <option value="">Todos</option>
            <option value="abierta">Abierta</option>
            <option value="en_revision">En revisión</option>
            <option value="resuelta">Resuelta</option>
          </select>
        </div>
        <div>
          <label class="mb-1 block text-theme-xs font-medium text-gray-600 dark:text-gray-400">Severidad</label>
          <select
            v-model="filterSeverity"
            class="rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            @change="loadIncidents(1)"
          >
            <option value="">Todas</option>
            <option value="baja">Baja</option>
            <option value="media">Media</option>
            <option value="alta">Alta</option>
            <option value="critica">Crítica</option>
          </select>
        </div>
      </div>

      <div class="overflow-hidden rounded-xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-white/[0.03]">
        <div class="max-w-full overflow-x-auto">
          <table class="min-w-full">
            <thead>
              <tr class="border-b border-gray-200 dark:border-gray-700">
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Fecha</p>
                </th>
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Vehículo</p>
                </th>
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Título</p>
                </th>
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Severidad</p>
                </th>
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Estado</p>
                </th>
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Reportó</p>
                </th>
                <th class="px-5 py-3 text-right sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Acciones</p>
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
              <tr v-for="inc in incidents" :key="inc.id" class="border-t border-gray-100 dark:border-gray-800">
                <td class="px-5 py-4 text-theme-sm text-gray-600 dark:text-gray-300 sm:px-6">
                  {{ formatDateTime(inc.reported_at) }}
                </td>
                <td class="px-5 py-4 font-medium text-gray-800 text-theme-sm dark:text-white/90 sm:px-6">
                  {{ inc.vehicle?.license_plate }}
                </td>
                <td class="max-w-[220px] truncate px-5 py-4 text-theme-sm text-gray-700 dark:text-gray-200 sm:px-6" :title="inc.title">
                  {{ inc.title }}
                </td>
                <td class="px-5 py-4 sm:px-6">
                  <span class="inline-flex rounded-full px-2.5 py-0.5 text-theme-xs font-medium capitalize" :class="severityBadgeClass(inc.severity)">
                    {{ inc.severity }}
                  </span>
                </td>
                <td class="px-5 py-4 sm:px-6">
                  <span class="inline-flex rounded-full px-2.5 py-0.5 text-theme-xs font-medium" :class="statusBadgeClass(inc.status)">
                    {{ statusLabel(inc.status) }}
                  </span>
                </td>
                <td class="px-5 py-4 text-theme-sm text-gray-600 dark:text-gray-300 sm:px-6">
                  {{ inc.reporter?.name || '—' }}
                </td>
                <td class="px-5 py-4 text-right sm:px-6">
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
          {{ editingId ? 'Actualizar incidencia' : 'Reportar incidencia' }}
        </h2>
        <form class="mt-4 space-y-4" @submit.prevent="submit">
          <div v-if="!editingId">
            <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Vehículo</label>
            <select
              v-model="form.vehicle_id"
              required
              class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            >
              <option value="" disabled>Seleccione…</option>
              <option v-for="v in vehicleOptions" :key="v.id" :value="String(v.id)">
                {{ v.license_plate }} — {{ v.brand }} {{ v.model }}
              </option>
            </select>
          </div>

          <div>
            <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Título breve</label>
            <input
              v-model="form.title"
              type="text"
              required
              placeholder="Ej. Llanta delantera derecha pinchada"
              class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            />
          </div>

          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div>
              <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Severidad</label>
              <select
                v-model="form.severity"
                class="w-full rounded-lg border border-gray-200 bg-white px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
              >
                <option value="baja">Baja</option>
                <option value="media">Media</option>
                <option value="alta">Alta</option>
                <option value="critica">Crítica</option>
              </select>
            </div>
            <div v-if="editingId">
              <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Estado</label>
              <select
                v-model="form.status"
                class="w-full rounded-lg border border-gray-200 bg-white px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
              >
                <option value="abierta">Abierta</option>
                <option value="en_revision">En revisión</option>
                <option value="resuelta">Resuelta</option>
              </select>
            </div>
          </div>

          <div>
            <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Descripción</label>
            <textarea
              v-model="form.description"
              rows="3"
              placeholder="Detalles de lo ocurrido..."
              class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            />
          </div>

          <div v-if="!editingId && canManageFleet" class="flex items-center gap-2">
            <input id="maint-check" v-model="form.set_vehicle_maintenance" type="checkbox" class="rounded border-gray-300" />
            <label for="maint-check" class="text-theme-sm text-gray-700 dark:text-gray-300">
              Poner vehículo en estado de mantenimiento
            </label>
          </div>

          <div v-if="!editingId">
            <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Evidencia fotográfica (opcional)</label>
            <input type="file" accept="image/*" class="w-full text-theme-sm" @change="onFile" />
            <div v-if="previewUrl" class="mt-2">
              <img :src="previewUrl" alt="Vista previa" class="h-28 w-40 rounded-lg object-cover" />
            </div>
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
import { onMounted, reactive, ref } from 'vue';
import AdminLayout from '@/components/layout/AdminLayout.vue';
import ComponentCard from '@/components/common/ComponentCard.vue';
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue';
import TableRowActions from '@/components/common/TableRowActions.vue';
import { useAuth } from '../composables/useAuth';

const { currentUser, isAdmin, canManageFleet, loadMe, logout } = useAuth();

const incidents = ref([]);
const vehicleOptions = ref([]);
const meta = ref({ current_page: 1, last_page: 1 });
const filterVehicleId = ref('');
const filterStatus = ref('');
const filterSeverity = ref('');
const modalOpen = ref(false);
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

const statusLabel = (s) => {
  if (s === 'en_revision') return 'En revisión';
  if (s === 'resuelta') return 'Resuelta';
  return 'Abierta';
};

const statusBadgeClass = (s) => {
  if (s === 'resuelta') return 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-300';
  if (s === 'en_revision') return 'bg-amber-500/15 text-amber-700 dark:text-amber-300';
  return 'bg-rose-500/15 text-rose-700 dark:text-rose-300';
};

const severityBadgeClass = (sev) => {
  if (sev === 'critica') return 'bg-rose-600/20 text-rose-800 dark:text-rose-300';
  if (sev === 'alta') return 'bg-amber-500/20 text-amber-800 dark:text-amber-300';
  if (sev === 'media') return 'bg-sky-500/15 text-sky-700 dark:text-sky-300';
  return 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300';
};

const formatDateTime = (iso) => {
  if (!iso) return '';
  return new Date(iso).toLocaleString('es-HN', { dateStyle: 'short', timeStyle: 'short' });
};

const loadVehicles = async () => {
  const { data } = await window.axios.get('/vehicles/options');
  vehicleOptions.value = data.data || [];
};

const loadIncidents = async (page = 1) => {
  const params = { page, per_page: 15 };
  if (filterVehicleId.value) params.vehicle_id = filterVehicleId.value;
  if (filterStatus.value) params.status = filterStatus.value;
  if (filterSeverity.value) params.severity = filterSeverity.value;
  const { data } = await window.axios.get('/incidents', { params });
  incidents.value = data.data;
  meta.value = {
    current_page: data.current_page,
    last_page: data.last_page,
  };
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

const esc = (v) =>
  String(v ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

const openView = (inc) => {
  const pu = inc.photo_url && String(inc.photo_url).trim();
  const photo =
    pu && (/^https?:\/\//.test(pu) || pu.startsWith('/'))
      ? `<p class="mt-3"><img src="${esc(pu)}" alt="" class="mx-auto h-40 max-w-full rounded-lg object-cover" /></p>`
      : '';
  Swal.fire({
    title: esc(inc.title),
    html: `
      <div class="text-left text-theme-sm space-y-2 text-gray-700">
        <p><strong>Vehículo:</strong> ${esc(inc.vehicle?.license_plate)} (${esc(inc.vehicle?.brand)} ${esc(inc.vehicle?.model)})</p>
        <p><strong>Reportado:</strong> ${esc(formatDateTime(inc.reported_at))}</p>
        <p><strong>Reportó:</strong> ${esc(inc.reporter?.name || '—')}</p>
        <p><strong>Severidad:</strong> ${esc(inc.severity)}</p>
        <p><strong>Estado:</strong> ${esc(statusLabel(inc.status))}</p>
        <p><strong>Descripción:</strong> ${inc.description ? esc(inc.description) : '—'}</p>
      </div>
      ${photo}
    `,
    confirmButtonText: 'Cerrar',
    showCloseButton: true,
    width: 520,
  });
};

const closeModal = () => {
  modalOpen.value = false;
  resetPreview();
};

const submit = async () => {
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
    await Swal.fire({ icon: 'success', title: 'Guardado', timer: 1400, showConfirmButton: false });
    closeModal();
    await loadIncidents(meta.value.current_page);
  } catch (err) {
    const msg = err.response?.data?.message || 'No se pudo guardar';
    await Swal.fire({ icon: 'error', title: 'Error', text: msg });
  }
};

const confirmDelete = async (inc) => {
  const r = await Swal.fire({
    icon: 'warning',
    title: '¿Eliminar incidencia?',
    text: inc.title,
    showCancelButton: true,
    confirmButtonText: 'Sí, eliminar',
    cancelButtonText: 'Cancelar',
  });
  if (!r.isConfirmed) return;
  try {
    await window.axios.delete(`/incidents/${inc.id}`);
    await Swal.fire({ icon: 'success', title: 'Eliminado', timer: 1200, showConfirmButton: false });
    await loadIncidents(meta.value.current_page);
  } catch (err) {
    await Swal.fire({ icon: 'error', title: err.response?.data?.message || 'No se pudo eliminar' });
  }
};

onMounted(async () => {
  await loadMe();
  await Promise.all([loadVehicles(), loadIncidents(1)]);
});
</script>
