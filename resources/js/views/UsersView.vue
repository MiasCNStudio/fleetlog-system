<template>
  <AdminLayout header-title="Usuarios" :user-name="currentUser?.name" @logout="logout(true)">
    <PageBreadcrumb page-title="Usuarios" subtitle="Gestión de funcionarios, despachadores y motoristas">
      <template #actions>
        <button type="button" class="fleet-btn-primary" @click="openCreate">
          <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
          </svg>
          Nuevo usuario
        </button>
      </template>
    </PageBreadcrumb>

    <ComponentCard title="Listado" desc="Filtra y administra el personal y sus roles en el sistema.">
      <template #header-extra>
        <span class="rounded-lg bg-gray-100 px-2.5 py-1 text-theme-xs font-semibold tabular-nums text-gray-600 dark:bg-gray-800 dark:text-gray-300">
          {{ meta.total }} {{ meta.total === 1 ? 'usuario' : 'usuarios' }}
        </span>
      </template>

      <div class="fleet-filter-bar grid grid-cols-1 gap-3 sm:flex sm:flex-wrap sm:items-end">
        <div class="w-full sm:w-72">
          <label for="users-search" class="fleet-label">Buscar</label>
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
              id="users-search"
              v-model="searchQuery"
              type="text"
              placeholder="Nombre, correo o código…"
              class="fleet-input pl-10 pr-9"
              @keyup.enter="loadUsers(1)"
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
          <label for="users-filter-role" class="fleet-label">Rol</label>
          <select
            id="users-filter-role"
            v-model="filterRole"
            class="fleet-select"
            @change="loadUsers(1)"
          >
            <option value="">Todos</option>
            <option value="admin">Admin</option>
            <option value="despachador">Jefe de motoristas / Despachador</option>
            <option value="motorista">Motorista</option>
          </select>
        </div>

        <button type="button" class="fleet-btn-secondary h-10 px-3.5 text-theme-xs" @click="loadUsers(1)">
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
                <th scope="col" class="fleet-th">Persona</th>
                <th scope="col" class="fleet-th">Correo</th>
                <th scope="col" class="fleet-th">Tipo</th>
                <th scope="col" class="fleet-th">Rol</th>
                <th scope="col" class="fleet-th">Código</th>
                <th scope="col" class="fleet-th text-right">Acciones</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
              <tr v-if="loading" v-for="n in 5" :key="`sk-${n}`" class="animate-pulse">
                <td v-for="c in 6" :key="c" class="fleet-td">
                  <div class="h-4 w-full max-w-[130px] rounded bg-gray-200 dark:bg-gray-800" />
                </td>
              </tr>

              <tr v-else-if="users.length === 0">
                <td colspan="6" class="p-0">
                  <TableEmptyState
                    icon="users"
                    :has-filters="hasFilters"
                    :title="hasFilters ? 'No se encontraron usuarios' : 'Sin usuarios registrados'"
                    :description="
                      hasFilters
                        ? 'Ajusta el texto de búsqueda o el rol seleccionado.'
                        : 'Agrega funcionarios, despachadores o motoristas para usar Fleetlog.'
                    "
                    @reset="resetFilters"
                  />
                </td>
              </tr>

              <tr v-for="u in users" v-else :key="u.id" class="fleet-tr">
                <td class="fleet-td whitespace-nowrap">
                  <div class="flex items-center gap-3">
                    <div class="flex size-10 shrink-0 items-center justify-center overflow-hidden rounded-full border border-gray-200 bg-brand-50 text-theme-xs font-semibold text-brand-600 dark:border-gray-700 dark:bg-brand-500/15 dark:text-brand-300">
                      <img v-if="u.photo_url" :src="u.photo_url" :alt="u.name" class="h-full w-full object-cover" />
                      <span v-else>{{ userInitials(u.name) }}</span>
                    </div>
                    <span class="font-medium text-gray-900 dark:text-white">{{ u.name }}</span>
                  </div>
                </td>
                <td class="fleet-td whitespace-nowrap text-gray-600 dark:text-gray-300">
                  {{ u.email }}
                </td>
                <td class="fleet-td whitespace-nowrap">
                  <StatusBadge kind="userType" :value="u.person_type || 'funcionario'" />
                </td>
                <td class="fleet-td whitespace-nowrap">
                  <StatusBadge kind="userRole" :value="u.role || 'motorista'" />
                </td>
                <td class="fleet-td whitespace-nowrap font-mono text-theme-xs text-gray-600 dark:text-gray-300">
                  {{ u.driver_code || '—' }}
                </td>
                <td class="fleet-td whitespace-nowrap text-right">
                  <TableRowActions
                    :group-label="`Acciones para ${u.name}`"
                    :show-delete="u.id !== currentUser?.id"
                    @view="openView(u)"
                    @edit="openEdit(u)"
                    @delete="confirmDelete(u)"
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
      :title="editingId ? 'Editar usuario' : 'Nuevo usuario'"
      subtitle="Define el tipo de persona, rol de acceso y credenciales."
      @close="closeModal"
    >
      <form id="user-form" class="space-y-4" @submit.prevent="submit">
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div>
            <label for="user-type" class="fleet-field-label">Tipo</label>
            <select id="user-type" v-model="form.person_type" class="fleet-select" required>
              <option value="funcionario">Funcionario</option>
              <option value="motorista">Motorista</option>
            </select>
          </div>
          <div>
            <label for="user-role" class="fleet-field-label">Rol de acceso</label>
            <select id="user-role" v-model="form.role" class="fleet-select" required>
              <option value="admin">Administrador</option>
              <option value="despachador">Jefe de motoristas / Despachador</option>
              <option value="motorista">Motorista (solo campo)</option>
            </select>
          </div>
        </div>

        <div>
          <label for="user-name" class="fleet-field-label">
            {{ form.person_type === 'motorista' ? 'Nombre del motorista' : 'Nombre del funcionario' }}
            <span class="text-rose-500">*</span>
          </label>
          <input id="user-name" v-model="form.name" type="text" class="fleet-input" required />
        </div>

        <div v-if="form.person_type === 'motorista'">
          <label for="user-driver-code" class="fleet-field-label">
            Código de motorista <span class="text-rose-500">*</span>
          </label>
          <input
            id="user-driver-code"
            v-model="form.driver_code"
            type="text"
            autocomplete="off"
            placeholder="Ej. MOT-001"
            class="fleet-input font-mono uppercase"
            :required="form.person_type === 'motorista'"
          />
        </div>

        <div>
          <label for="user-email" class="fleet-field-label">
            Correo <span class="text-rose-500">*</span>
          </label>
          <input id="user-email" v-model="form.email" type="email" class="fleet-input" required />
        </div>

        <div>
          <label for="user-password" class="fleet-field-label">
            Contraseña {{ editingId ? '(opcional)' : '*' }}
          </label>
          <input
            id="user-password"
            v-model="form.password"
            type="password"
            class="fleet-input"
            :required="!editingId"
          />
        </div>

        <div>
          <label for="user-photo" class="fleet-field-label">Imagen</label>
          <input id="user-photo" type="file" accept="image/*" class="fleet-file" @change="onFile" />
          <div v-if="previewUrl" class="mt-3">
            <img :src="previewUrl" alt="Vista previa" class="size-24 rounded-2xl border border-gray-200 object-cover dark:border-gray-700" />
          </div>
        </div>
      </form>

      <template #footer>
        <button type="button" class="fleet-btn-secondary" @click="closeModal">
          Cancelar
        </button>
        <button type="submit" form="user-form" :disabled="saving" class="fleet-btn-primary">
          {{ saving ? 'Guardando…' : 'Guardar' }}
        </button>
      </template>
    </BaseModal>

    <BaseModal
      :open="detailOpen"
      :title="detailItem?.name || 'Detalle de usuario'"
      :subtitle="detailItem?.email || ''"
      @close="detailOpen = false"
    >
      <div v-if="detailItem" class="space-y-4">
        <div class="flex items-center gap-4 rounded-xl border border-gray-200/80 bg-gray-50/80 p-4 dark:border-gray-800 dark:bg-white/[0.02]">
          <div class="flex size-16 shrink-0 items-center justify-center overflow-hidden rounded-2xl border border-gray-200 bg-brand-50 text-base font-bold text-brand-600 dark:border-gray-700 dark:bg-brand-500/15 dark:text-brand-300">
            <img v-if="detailItem.photo_url" :src="detailItem.photo_url" :alt="detailItem.name" class="h-full w-full object-cover" />
            <span v-else>{{ userInitials(detailItem.name) }}</span>
          </div>
          <div class="min-w-0 space-y-1.5">
            <p class="truncate text-base font-semibold text-gray-900 dark:text-white">{{ detailItem.name }}</p>
            <div class="flex flex-wrap items-center gap-2">
              <StatusBadge kind="userType" :value="detailItem.person_type || 'funcionario'" />
              <StatusBadge kind="userRole" :value="detailItem.role || 'motorista'" />
            </div>
          </div>
        </div>

        <dl class="grid grid-cols-1 gap-3 text-theme-sm sm:grid-cols-2">
          <div class="rounded-xl border border-gray-100 p-3 dark:border-gray-800">
            <dt class="text-theme-xs text-gray-500 dark:text-gray-400">Correo electrónico</dt>
            <dd class="mt-0.5 truncate font-medium text-gray-900 dark:text-white">{{ detailItem.email }}</dd>
          </div>
          <div class="rounded-xl border border-gray-100 p-3 dark:border-gray-800">
            <dt class="text-theme-xs text-gray-500 dark:text-gray-400">Código de motorista</dt>
            <dd class="mt-0.5 font-mono font-medium text-gray-900 dark:text-white">
              {{ detailItem.person_type === 'motorista' && detailItem.driver_code ? detailItem.driver_code : '—' }}
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
import { computed, onMounted, reactive, ref, watch } from 'vue';
import AdminLayout from '@/components/layout/AdminLayout.vue';
import BaseModal from '@/components/common/BaseModal.vue';
import ComponentCard from '@/components/common/ComponentCard.vue';
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

const { currentUser, loadMe, logout } = useAuth();

const users = ref([]);
const loading = ref(true);
const saving = ref(false);
const meta = ref({ current_page: 1, last_page: 1, total: 0, from: 0, to: 0 });
const searchQuery = ref('');
const filterRole = ref('');
const modalOpen = ref(false);
const detailOpen = ref(false);
const detailItem = ref(null);
const editingId = ref(null);
const previewUrl = ref('');
const fileRef = ref(null);

const form = reactive({
  name: '',
  email: '',
  password: '',
  person_type: 'funcionario',
  role: 'despachador',
  driver_code: '',
});

const hasFilters = computed(() => Boolean(searchQuery.value.trim() || filterRole.value));

const userInitials = (name) => {
  const parts = String(name || '').trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return 'U';
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
};

const loadUsers = async (page = 1) => {
  loading.value = true;
  try {
    const params = { page };
    if (searchQuery.value.trim()) params.search = searchQuery.value.trim();
    if (filterRole.value) params.role = filterRole.value;
    const { data } = await window.axios.get('/users', { params });
    users.value = data.data || [];
    meta.value = {
      current_page: data.current_page ?? 1,
      last_page: data.last_page ?? 1,
      total: data.total ?? users.value.length,
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
  loadUsers(1);
};

const resetFilters = () => {
  searchQuery.value = '';
  filterRole.value = '';
  loadUsers(1);
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
  form.role = 'despachador';
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
  form.role = u.role || 'motorista';
  form.driver_code = u.driver_code || '';
  resetPreview();
  previewUrl.value = u.photo_url || '';
  modalOpen.value = true;
};

const openView = (u) => {
  detailItem.value = u;
  detailOpen.value = true;
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
  fd.append('role', form.role);
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
  if (saving.value) return;
  if (!editingId.value && !form.password) {
    await showWarningAlert('La contraseña es obligatoria al crear');
    return;
  }
  saving.value = true;
  try {
    if (editingId.value) {
      await window.axios.post(`/users/${editingId.value}`, buildFormData());
      if (Number(editingId.value) === Number(currentUser.value?.id)) {
        await loadMe();
      }
    } else {
      await window.axios.post('/users', buildFormData());
    }
    await showSuccessAlert('Guardado');
    closeModal();
    await loadUsers(meta.value.current_page);
  } catch (err) {
    const errors = err.response?.data?.errors;
    const firstErr = errors ? Object.values(errors).flat()[0] : null;
    const msg = firstErr || err.response?.data?.message || 'No se pudo guardar';
    await showErrorAlert('Error', msg);
  } finally {
    saving.value = false;
  }
};

const confirmDelete = async (u) => {
  const r = await confirmDeleteDialog({
    title: '¿Eliminar usuario?',
    text: u.name,
  });
  if (!r.isConfirmed) return;
  try {
    await window.axios.delete(`/users/${u.id}`);
    await showSuccessAlert('Eliminado');
    await loadUsers(meta.value.current_page);
  } catch (err) {
    await showErrorAlert('Error', err.response?.data?.message || 'No se pudo eliminar');
  }
};

watch(
  () => form.person_type,
  (v) => {
    if (v === 'funcionario') {
      form.driver_code = '';
    } else if (!editingId.value) {
      form.role = 'motorista';
    }
  },
);

onMounted(async () => {
  await loadMe();
  await loadUsers(1);
});
</script>
