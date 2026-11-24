<template>
  <AdminLayout header-title="Vehículos" :user-name="currentUser?.name" @logout="logout">
    <PageBreadcrumb page-title="Vehículos" subtitle="Registro, estado operativo y odómetro de unidades.">
      <template v-if="canManageFleet" #actions>
        <button
          type="button"
          class="rounded-lg bg-brand-500 px-4 py-2 text-theme-sm font-medium text-white hover:bg-brand-600"
          @click="openCreate"
        >
          Nuevo vehículo
        </button>
      </template>
    </PageBreadcrumb>

    <ComponentCard title="Listado" desc="Estado, kilometraje actual, placa, marca y modelo.">
      <div class="mb-4 flex flex-wrap items-end gap-3">
        <div>
          <label class="mb-1 block text-theme-xs font-medium text-gray-600 dark:text-gray-400">Buscar</label>
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Placa, marca o modelo..."
            class="rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            @keyup.enter="loadVehicles(1)"
          />
        </div>
        <div>
          <label class="mb-1 block text-theme-xs font-medium text-gray-600 dark:text-gray-400">Estado</label>
          <select
            v-model="filterStatus"
            class="rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            @change="loadVehicles(1)"
          >
            <option value="">Todos</option>
            <option value="disponible">Disponible</option>
            <option value="en_ruta">En ruta</option>
            <option value="mantenimiento">Mantenimiento</option>
          </select>
        </div>
      </div>

      <div class="overflow-hidden rounded-xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-white/[0.03]">
        <div class="max-w-full overflow-x-auto">
          <table class="min-w-full">
            <thead>
              <tr class="border-b border-gray-200 dark:border-gray-700">
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Imagen</p>
                </th>
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Placa</p>
                </th>
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Vehículo</p>
                </th>
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Estado</p>
                </th>
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Odómetro</p>
                </th>
                <th class="px-5 py-3 text-right sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Acciones</p>
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
              <tr v-for="v in vehicles" :key="v.id" class="border-t border-gray-100 dark:border-gray-800">
                <td class="px-5 py-4 sm:px-6">
                  <div class="h-14 w-20 overflow-hidden rounded-lg bg-gray-100">
                    <img
                      v-if="v.photo_url"
                      :src="v.photo_url"
                      :alt="v.license_plate"
                      class="h-full w-full object-cover"
                    />
                  </div>
                </td>
                <td class="px-5 py-4 font-medium text-gray-800 text-theme-sm dark:text-white/90 sm:px-6">
                  {{ v.license_plate }}
                </td>
                <td class="px-5 py-4 text-theme-sm text-gray-600 dark:text-gray-300 sm:px-6">
                  {{ v.brand }} {{ v.model }} · {{ v.color }}
                </td>
                <td class="px-5 py-4 sm:px-6">
                  <span
                    class="inline-flex rounded-full px-2.5 py-0.5 text-theme-xs font-medium"
                    :class="statusBadgeClass(v.status)"
                  >
                    {{ statusLabel(v.status) }}
                  </span>
                </td>
                <td class="px-5 py-4 text-theme-sm text-gray-600 dark:text-gray-300 sm:px-6">
                  {{ (v.current_odometer ?? 0).toLocaleString() }} km
                </td>
                <td class="px-5 py-4 text-right sm:px-6">
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
          {{ editingId ? 'Editar vehículo' : 'Nuevo vehículo' }}
        </h2>
        <form class="mt-4 space-y-4" @submit.prevent="submit">
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div>
              <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Placa</label>
              <input
                v-model="form.license_plate"
                type="text"
                class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm uppercase dark:border-gray-700 dark:bg-gray-900 dark:text-white"
                required
              />
            </div>
            <div>
              <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Estado</label>
              <select
                v-model="form.status"
                class="w-full rounded-lg border border-gray-200 bg-white px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
              >
                <option value="disponible">Disponible</option>
                <option value="en_ruta">En ruta</option>
                <option value="mantenimiento">Mantenimiento</option>
              </select>
            </div>
          </div>
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <div>
              <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Marca</label>
              <input
                v-model="form.brand"
                type="text"
                class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
                required
              />
            </div>
            <div>
              <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Modelo</label>
              <input
                v-model="form.model"
                type="text"
                class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
                required
              />
            </div>
            <div>
              <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Color</label>
              <input
                v-model="form.color"
                type="text"
                class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
                required
              />
            </div>
          </div>
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div>
              <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Odómetro actual (km)</label>
              <input
                v-model.number="form.current_odometer"
                type="number"
                min="0"
                class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
              />
            </div>
            <div>
              <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Mant. cada (km, opcional)</label>
              <input
                v-model.number="form.maintenance_interval_km"
                type="number"
                min="500"
                placeholder="Ej. 5000"
                class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
              />
            </div>
          </div>
          <div>
            <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Imagen</label>
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

const vehicles = ref([]);
const meta = ref({ current_page: 1, last_page: 1 });
const searchQuery = ref('');
const filterStatus = ref('');
const modalOpen = ref(false);
const editingId = ref(null);
const previewUrl = ref('');
const fileRef = ref(null);

const form = reactive({
  license_plate: '',
  color: '',
  brand: '',
  model: '',
  status: 'disponible',
  current_odometer: 0,
  maintenance_interval_km: null,
});

const statusLabel = (s) => {
  if (s === 'en_ruta') return 'En ruta';
  if (s === 'mantenimiento') return 'Mantenimiento';
  return 'Disponible';
};

const statusBadgeClass = (s) => {
  if (s === 'en_ruta') return 'bg-amber-500/15 text-amber-700 dark:text-amber-300';
  if (s === 'mantenimiento') return 'bg-rose-500/15 text-rose-700 dark:text-rose-300';
  return 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-300';
};

const loadVehicles = async (page = 1) => {
  const params = { page };
  if (searchQuery.value.trim()) params.search = searchQuery.value.trim();
  if (filterStatus.value) params.status = filterStatus.value;
  const { data } = await window.axios.get('/vehicles', { params });
  vehicles.value = data.data;
  meta.value = {
    current_page: data.current_page,
    last_page: data.last_page,
  };
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
  form.license_plate = '';
  form.color = '';
  form.brand = '';
  form.model = '';
  form.status = 'disponible';
  form.current_odometer = 0;
  form.maintenance_interval_km = null;
  resetPreview();
  modalOpen.value = true;
};

const openEdit = (v) => {
  editingId.value = v.id;
  form.license_plate = v.license_plate;
  form.color = v.color;
  form.brand = v.brand;
  form.model = v.model;
  form.status = v.status || 'disponible';
  form.current_odometer = v.current_odometer ?? 0;
  form.maintenance_interval_km = v.maintenance_interval_km || null;
  resetPreview();
  previewUrl.value = v.photo_url || '';
  modalOpen.value = true;
};

const esc = (v) =>
  String(v ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

const openView = (v) => {
  const pu = v.photo_url && String(v.photo_url).trim();
  const photo =
    pu && (/^https?:\/\//.test(pu) || pu.startsWith('/'))
      ? `<p class="mt-3"><img src="${esc(pu)}" alt="" class="mx-auto h-32 max-w-full rounded-lg object-cover" /></p>`
      : '';
  Swal.fire({
    title: esc(v.license_plate),
    html: `
      <div class="text-left text-theme-sm space-y-2 text-gray-700">
        <p><strong>Color:</strong> ${esc(v.color)}</p>
        <p><strong>Marca:</strong> ${esc(v.brand)}</p>
        <p><strong>Modelo:</strong> ${esc(v.model)}</p>
        <p><strong>Estado:</strong> ${esc(statusLabel(v.status))}</p>
        <p><strong>Odómetro:</strong> ${(v.current_odometer ?? 0).toLocaleString()} km</p>
      </div>
      ${photo}
    `,
    confirmButtonText: 'Cerrar',
    showCloseButton: true,
  });
};

const closeModal = () => {
  modalOpen.value = false;
  resetPreview();
};

const buildFormData = () => {
  const fd = new FormData();
  fd.append('license_plate', form.license_plate);
  fd.append('color', form.color);
  fd.append('brand', form.brand);
  fd.append('model', form.model);
  fd.append('status', form.status);
  fd.append('current_odometer', String(form.current_odometer ?? 0));
  if (form.maintenance_interval_km) {
    fd.append('maintenance_interval_km', String(form.maintenance_interval_km));
  }
  if (fileRef.value) {
    fd.append('photo', fileRef.value);
  }
  return fd;
};

const submit = async () => {
  try {
    if (editingId.value) {
      await window.axios.post(`/vehicles/${editingId.value}`, buildFormData());
    } else {
      await window.axios.post('/vehicles', buildFormData());
    }
    await Swal.fire({ icon: 'success', title: 'Guardado', timer: 1400, showConfirmButton: false });
    closeModal();
    await loadVehicles(meta.value.current_page);
  } catch (err) {
    const msg = err.response?.data?.message || 'No se pudo guardar';
    await Swal.fire({ icon: 'error', title: 'Error', text: msg });
  }
};

const confirmDelete = async (v) => {
  const r = await Swal.fire({
    icon: 'warning',
    title: '¿Eliminar vehículo?',
    text: v.license_plate,
    showCancelButton: true,
    confirmButtonText: 'Sí, eliminar',
    cancelButtonText: 'Cancelar',
  });
  if (!r.isConfirmed) return;
  try {
    await window.axios.delete(`/vehicles/${v.id}`);
    await Swal.fire({ icon: 'success', title: 'Eliminado', timer: 1200, showConfirmButton: false });
    await loadVehicles(meta.value.current_page);
  } catch (err) {
    await Swal.fire({ icon: 'error', title: err.response?.data?.message || 'No se pudo eliminar' });
  }
};

onMounted(async () => {
  await loadMe();
  await loadVehicles(1);
});
</script>
