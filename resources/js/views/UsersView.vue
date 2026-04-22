<template>
  <AdminLayout header-title="Usuarios" :user-name="currentUser?.name" @logout="logout">
    <PageBreadcrumb page-title="Usuarios" subtitle="Gestión de funcionarios y motoristas">
      <template #actions>
        <button
          type="button"
          class="rounded-lg bg-brand-500 px-4 py-2 text-theme-sm font-medium text-white hover:bg-brand-600"
          @click="openCreate"
        >
          Nuevo usuario
        </button>
      </template>
    </PageBreadcrumb>

    <ComponentCard title="Listado" desc="Filtra y administra el personal del sistema.">
      <div class="overflow-hidden rounded-xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-white/[0.03]">
        <div class="max-w-full overflow-x-auto">
          <table class="min-w-full">
            <thead>
              <tr class="border-b border-gray-200 dark:border-gray-700">
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Persona</p>
                </th>
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Correo</p>
                </th>
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Tipo</p>
                </th>
                <th class="px-5 py-3 text-left sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Código</p>
                </th>
                <th class="px-5 py-3 text-right sm:px-6">
                  <p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Acciones</p>
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
              <tr v-for="u in users" :key="u.id" class="border-t border-gray-100 dark:border-gray-800">
                <td class="px-5 py-4 sm:px-6">
                  <div class="flex items-center gap-3">
                    <div class="h-10 w-10 overflow-hidden rounded-full bg-gray-100">
                      <img v-if="u.photo_url" :src="u.photo_url" :alt="u.name" class="h-full w-full object-cover" />
                    </div>
                    <span class="font-medium text-gray-800 text-theme-sm dark:text-white/90">{{ u.name }}</span>
                  </div>
                </td>
                <td class="px-5 py-4 text-theme-sm text-gray-600 dark:text-gray-300 sm:px-6">{{ u.email }}</td>
                <td class="px-5 py-4 sm:px-6">
                  <span
                    class="rounded-full px-2 py-0.5 text-theme-xs font-medium"
                    :class="
                      u.person_type === 'motorista'
                        ? 'bg-brand-50 text-brand-700 dark:bg-brand-500/15 dark:text-brand-400'
                        : 'bg-success-50 text-success-700 dark:bg-success-500/15 dark:text-success-500'
                    "
                  >
                    {{ u.person_type === 'motorista' ? 'Motorista' : 'Funcionario' }}
                  </span>
                </td>
                <td class="px-5 py-4 text-theme-sm text-gray-600 dark:text-gray-300 sm:px-6">
                  {{ u.driver_code || '—' }}
                </td>
                <td class="px-5 py-4 text-right sm:px-6">
                  <TableRowActions
                    :group-label="`Acciones para ${u.name}`"
                    @view="openView(u)"
                    @edit="openEdit(u)"
                    @delete="confirmDelete(u)"
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
          {{ editingId ? 'Editar usuario' : 'Nuevo usuario' }}
        </h2>
        <form class="mt-4 space-y-4" @submit.prevent="submit">
          <div>
            <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Tipo</label>
            <select
              v-model="form.person_type"
              class="w-full rounded-lg border border-gray-200 bg-white px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
              required
            >
              <option value="funcionario">Funcionario</option>
              <option value="motorista">Motorista</option>
            </select>
          </div>
          <div>
            <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">
              {{ form.person_type === 'motorista' ? 'Nombre del motorista' : 'Nombre del funcionario' }}
            </label>
            <input
              v-model="form.name"
              type="text"
              class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
              required
            />
          </div>
          <div v-if="form.person_type === 'motorista'">
            <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">
              Código de motorista
            </label>
            <input
              v-model="form.driver_code"
              type="text"
              autocomplete="off"
              class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
              :required="form.person_type === 'motorista'"
            />
          </div>
          <div>
            <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Correo</label>
            <input
              v-model="form.email"
              type="email"
              class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
              required
            />
          </div>
          <div>
            <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">
              Contraseña {{ editingId ? '(opcional)' : '' }}
            </label>
            <input
              v-model="form.password"
              type="password"
              class="w-full rounded-lg border border-gray-200 px-3 py-2 text-theme-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white"
              :required="!editingId"
            />
          </div>
          <div>
            <label class="mb-1 block text-theme-sm font-medium text-gray-700 dark:text-gray-300">Imagen</label>
            <input
              type="file"
              accept="image/*"
              class="w-full text-theme-sm"
              @change="onFile"
            />
            <div v-if="previewUrl" class="mt-2">
              <img :src="previewUrl" alt="Vista previa" class="h-24 w-24 rounded-lg object-cover" />
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
import { onMounted, reactive, ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import AdminLayout from '@/components/layout/AdminLayout.vue';
import ComponentCard from '@/components/common/ComponentCard.vue';
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue';
import TableRowActions from '@/components/common/TableRowActions.vue';
import { setAuthToken } from '../bootstrap';

const router = useRouter();

const currentUser = ref(null);
const users = ref([]);
const meta = ref({ current_page: 1, last_page: 1 });
const modalOpen = ref(false);
const editingId = ref(null);
const previewUrl = ref('');
const fileRef = ref(null);

const form = reactive({
  name: '',
  email: '',
  password: '',
  person_type: 'funcionario',
  driver_code: '',
});

const loadMe = async () => {
  const { data } = await window.axios.get('/user');
  currentUser.value = data;
};

const loadUsers = async (page = 1) => {
  const { data } = await window.axios.get('/users', { params: { page } });
  users.value = data.data;
  meta.value = {
    current_page: data.current_page,
    last_page: data.last_page,
  };
};

const changePage = (page) => {
  if (page < 1 || page > meta.value.last_page) return;
  loadUsers(page);
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
  form.name = '';
  form.email = '';
  form.password = '';
  form.person_type = 'funcionario';
  form.driver_code = '';
  resetPreview();
  modalOpen.value = true;
};

const openEdit = (u) => {
  editingId.value = u.id;
  form.name = u.name;
  form.email = u.email;
  form.password = '';
  form.person_type = u.person_type || 'funcionario';
  form.driver_code = u.driver_code || '';
  resetPreview();
  previewUrl.value = u.photo_url || '';
  modalOpen.value = true;
};

const esc = (v) =>
  String(v ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

const openView = (u) => {
  const tipo = u.person_type === 'motorista' ? 'Motorista' : 'Funcionario';
  const codigo = u.person_type === 'motorista' && u.driver_code ? esc(u.driver_code) : '—';
  const pu = u.photo_url && String(u.photo_url).trim();
  const photo =
    pu && (/^https?:\/\//.test(pu) || pu.startsWith('/'))
      ? `<p class="mt-3"><img src="${esc(pu)}" alt="" class="mx-auto h-28 w-28 rounded-lg object-cover" /></p>`
      : '';
  Swal.fire({
    title: esc(u.name),
    html: `
      <div class="text-left text-theme-sm space-y-2 text-gray-700">
        <p><strong>Correo:</strong> ${esc(u.email)}</p>
        <p><strong>Tipo:</strong> ${tipo}</p>
        <p><strong>Código:</strong> ${codigo}</p>
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
  fd.append('name', form.name);
  fd.append('email', form.email);
  fd.append('person_type', form.person_type);
  if (form.person_type === 'motorista') {
    fd.append('driver_code', form.driver_code);
  }
  if (form.password) {
    fd.append('password', form.password);
  }
  if (fileRef.value) {
    fd.append('photo', fileRef.value);
  }
  return fd;
};

const submit = async () => {
  try {
    if (editingId.value) {
      await window.axios.post(`/users/${editingId.value}`, buildFormData());
    } else {
      if (!form.password) {
        await Swal.fire({ icon: 'warning', title: 'La contraseña es obligatoria al crear' });
        return;
      }
      await window.axios.post('/users', buildFormData());
    }
    await Swal.fire({ icon: 'success', title: 'Guardado', timer: 1400, showConfirmButton: false });
    closeModal();
    await loadUsers(meta.value.current_page);
  } catch (err) {
    const msg = err.response?.data?.message || 'No se pudo guardar';
    await Swal.fire({ icon: 'error', title: 'Error', text: msg });
  }
};

const confirmDelete = async (u) => {
  const r = await Swal.fire({
    icon: 'warning',
    title: '¿Eliminar usuario?',
    text: u.name,
    showCancelButton: true,
    confirmButtonText: 'Sí, eliminar',
    cancelButtonText: 'Cancelar',
  });
  if (!r.isConfirmed) return;
  try {
    await window.axios.delete(`/users/${u.id}`);
    await Swal.fire({ icon: 'success', title: 'Eliminado', timer: 1200, showConfirmButton: false });
    await loadUsers(meta.value.current_page);
  } catch (err) {
    await Swal.fire({ icon: 'error', title: 'No se pudo eliminar' });
  }
};

const logout = async () => {
  try {
    await window.axios.post('/logout');
  } catch (_) {
    /* vacío */
  } finally {
    setAuthToken(null);
    await router.push({ name: 'login' });
  }
};

watch(
  () => form.person_type,
  (v) => {
    if (v === 'funcionario') {
      form.driver_code = '';
    }
  },
);

onMounted(async () => {
  try {
    await loadMe();
    await loadUsers(1);
  } catch (_) {
    setAuthToken(null);
    await router.push({ name: 'login' });
  }
});
</script>
