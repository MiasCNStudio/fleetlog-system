<template>
  <AdminLayout header-title="Mantenimiento" :user-name="currentUser?.name" @logout="logout(true)">
    <PageBreadcrumb
      page-title="Mantenimiento preventivo"
      subtitle="Control por kilometraje, alertas preventivas (500 km) y registro de servicios."
    >
      <template v-if="canManageFleet" #actions>
        <button type="button" class="fleet-btn-primary" @click="openCreate()">
          <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
          </svg>
          Programar / Registrar
        </button>
      </template>
    </PageBreadcrumb>

    <div class="space-y-6">
      <!-- Alertas por kilometraje -->
      <section v-if="alerts.length > 0" class="grid grid-cols-1 gap-3 md:grid-cols-2">
        <div
          v-for="v in alerts"
          :key="`al-${v.id}`"
          :class="[
            'flex flex-col justify-between gap-3 rounded-2xl border p-4 shadow-xs',
            v.maintenance_status === 'vencido'
              ? 'border-rose-400 bg-rose-50/90 text-rose-950 dark:border-rose-500/50 dark:bg-rose-500/15 dark:text-rose-100'
              : 'border-amber-300 bg-amber-50/90 text-amber-950 dark:border-amber-500/40 dark:bg-amber-500/15 dark:text-amber-100',
          ]"
        >
          <div class="flex items-start justify-between gap-2">
            <div class="space-y-1">
              <div class="flex flex-wrap items-center gap-2">
                <SalvadorPlate :license-plate="v.license_plate" :plate-type="v.plate_type" :plate-number="v.plate_number" />
                <StatusBadge kind="maintenanceStatus" :value="v.maintenance_status" />
              </div>
              <p class="text-theme-sm font-bold">
                {{
                  v.maintenance_status === 'vencido'
                    ? `¡MANTENIMIENTO PASADO por ${Math.abs(v.km_to_maintenance).toLocaleString()} km!`
                    : `Esta unidad necesitará mantenimiento dentro de ${Number(v.km_to_maintenance).toLocaleString()} km`
                }}
              </p>
              <p class="text-theme-xs opacity-85">
                {{ v.brand }} {{ v.model }} · Odómetro: {{ Number(v.current_odometer).toLocaleString() }} km / Meta: {{ Number(v.next_maintenance_odometer).toLocaleString() }} km
              </p>
            </div>
            <button
              v-if="canManageFleet"
              type="button"
              class="fleet-btn-secondary h-8 shrink-0 px-3 py-1 text-theme-xs"
              @click="openCreate(v.id, true)"
            >
              Registrar servicio
            </button>
          </div>
        </div>
      </section>

      <ComponentCard title="Historial y agenda de mantenimientos" desc="Programación por odómetro, taller, costo y finalización.">
        <template #header-extra>
          <span class="rounded-lg bg-gray-100 px-2.5 py-1 text-theme-xs font-semibold tabular-nums text-gray-600 dark:bg-gray-800 dark:text-gray-300">
            {{ meta.total }} {{ meta.total === 1 ? 'registro' : 'registros' }}
          </span>
        </template>

        <div class="fleet-filter-bar grid grid-cols-1 gap-3 sm:grid-cols-3">
          <div>
            <label for="maint-vehicle" class="fleet-label">Vehículo</label>
            <select id="maint-vehicle" v-model="filterVehicleId" class="fleet-select" @change="loadData(1)">
              <option value="">Todos los vehículos</option>
              <option v-for="v in vehicles" :key="v.id" :value="String(v.id)">{{ v.license_plate }} · {{ v.brand }}</option>
            </select>
          </div>
          <div>
            <label for="maint-status" class="fleet-label">Estado</label>
            <select id="maint-status" v-model="filterStatus" class="fleet-select" @change="loadData(1)">
              <option value="">Todos</option>
              <option value="programado">Programado</option>
              <option value="completado">Completado</option>
              <option value="cancelado">Cancelado</option>
            </select>
          </div>
        </div>

        <div class="fleet-table-wrap">
          <div class="max-w-full overflow-x-auto">
            <table class="w-full divide-y divide-gray-200 dark:divide-gray-800">
              <thead>
                <tr>
                  <th scope="col" class="fleet-th">Vehículo</th>
                  <th scope="col" class="fleet-th">Servicio</th>
                  <th scope="col" class="fleet-th">Kilometraje</th>
                  <th scope="col" class="fleet-th">Taller / Costo</th>
                  <th scope="col" class="fleet-th">Estado</th>
                  <th v-if="canManageFleet" scope="col" class="fleet-th text-right">Acciones</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
                <tr v-if="loading" v-for="n in 4" :key="n" class="animate-pulse">
                  <td v-for="c in 6" :key="c" class="fleet-td"><div class="h-4 w-24 rounded bg-gray-200 dark:bg-gray-800" /></td>
                </tr>
                <tr v-else-if="records.length === 0">
                  <td :colspan="canManageFleet ? 6 : 5" class="px-4 py-10 text-center text-theme-sm text-gray-500 dark:text-gray-400">
                    Sin registros de mantenimiento todavía.
                  </td>
                </tr>
                <tr v-else v-for="m in records" :key="m.id" class="fleet-tr">
                  <td class="fleet-td whitespace-nowrap">
                    <SalvadorPlate
                      :license-plate="m.vehicle?.license_plate"
                      :plate-type="m.vehicle?.plate_type"
                      :plate-number="m.vehicle?.plate_number"
                      compact
                    />
                  </td>
                  <td class="fleet-td">
                    <p class="font-semibold text-gray-900 dark:text-white">{{ m.title }}</p>
                    <p v-if="m.description" class="text-theme-xs text-gray-500 dark:text-gray-400">{{ m.description }}</p>
                  </td>
                  <td class="fleet-td whitespace-nowrap text-theme-xs tabular-nums">
                    <div v-if="m.scheduled_odometer_km">Meta: {{ Number(m.scheduled_odometer_km).toLocaleString() }} km</div>
                    <div v-if="m.completed_odometer_km" class="text-emerald-600 dark:text-emerald-400">
                      Realizado: {{ Number(m.completed_odometer_km).toLocaleString() }} km
                    </div>
                  </td>
                  <td class="fleet-td whitespace-nowrap text-theme-xs">
                    <div>{{ m.workshop || '—' }}</div>
                    <div v-if="m.cost_usd !== null && m.cost_usd !== undefined" class="font-semibold">
                      ${{ Number(m.cost_usd).toFixed(2) }}
                    </div>
                  </td>
                  <td class="fleet-td whitespace-nowrap">
                    <StatusBadge kind="maintenanceJobStatus" :value="m.status" />
                  </td>
                  <td v-if="canManageFleet" class="fleet-td whitespace-nowrap text-right">
                    <div class="inline-flex items-center gap-1.5">
                      <button
                        v-if="m.status === 'programado'"
                        type="button"
                        class="fleet-btn-primary h-8 px-2.5 py-1 text-theme-xs"
                        @click="openComplete(m)"
                      >
                        Completar
                      </button>
                      <button
                        v-if="isAdmin"
                        type="button"
                        class="fleet-btn-danger h-8 px-2.5 py-1 text-theme-xs"
                        @click="removeRecord(m)"
                      >
                        Eliminar
                      </button>
                    </div>
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
    </div>

    <!-- Modal programar/registrar mantenimiento -->
    <BaseModal
      :open="modalOpen"
      title="Mantenimiento de unidad"
      subtitle="Define el kilometraje objetivo y el margen de alerta preventiva (500 km por defecto)."
      @close="modalOpen = false"
    >
      <form id="maint-form" class="space-y-4" @submit.prevent="submitForm">
        <div>
          <label for="m-veh" class="fleet-field-label">Vehículo *</label>
          <select id="m-veh" v-model="form.vehicle_id" class="fleet-select" required @change="onVehicleChange">
            <option value="">Selecciona vehículo…</option>
            <option v-for="v in vehicles" :key="v.id" :value="v.id">
              {{ v.license_plate }} · {{ v.brand }} ({{ Number(v.current_odometer).toLocaleString() }} km)
            </option>
          </select>
        </div>

        <div>
          <label for="m-title" class="fleet-field-label">Tipo de mantenimiento *</label>
          <input id="m-title" v-model="form.title" type="text" placeholder="Ej. Cambio de aceite y filtros 5,000 km" class="fleet-input" required />
        </div>

        <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <div>
            <label for="m-status" class="fleet-field-label">Registrar como</label>
            <select id="m-status" v-model="form.status" class="fleet-select">
              <option value="programado">Programar próximo mantenimiento</option>
              <option value="completado">Registrar mantenimiento ya realizado</option>
            </select>
          </div>
          <div>
            <label for="m-alert" class="fleet-field-label">Alertar antes (km)</label>
            <input id="m-alert" v-model.number="form.alert_before_km" type="number" min="50" max="5000" class="fleet-input tabular-nums" />
          </div>
        </div>

        <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <div v-if="form.status === 'programado'">
            <label for="m-sched-km" class="fleet-field-label">Kilometraje meta *</label>
            <input id="m-sched-km" v-model.number="form.scheduled_odometer_km" type="number" min="0" class="fleet-input tabular-nums" required />
          </div>
          <div v-else>
            <label for="m-comp-km" class="fleet-field-label">Odómetro al realizarlo (km) *</label>
            <input id="m-comp-km" v-model.number="form.completed_odometer_km" type="number" min="0" class="fleet-input tabular-nums" required />
          </div>
          <div>
            <label for="m-int" class="fleet-field-label">Intervalo siguiente (km)</label>
            <input id="m-int" v-model.number="form.next_interval_km" type="number" min="100" class="fleet-input tabular-nums" />
          </div>
        </div>

        <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <div>
            <label for="m-work" class="fleet-field-label">Taller / proveedor</label>
            <input id="m-work" v-model="form.workshop" type="text" placeholder="Taller central" class="fleet-input" />
          </div>
          <div>
            <label for="m-cost" class="fleet-field-label">Costo ($ USD)</label>
            <input id="m-cost" v-model.number="form.cost_usd" type="number" step="0.01" min="0" class="fleet-input tabular-nums" />
          </div>
        </div>

        <div>
          <label for="m-desc" class="fleet-field-label">Descripción / observaciones</label>
          <textarea id="m-desc" v-model="form.description" rows="2" class="fleet-textarea" />
        </div>

        <label v-if="form.status === 'programado'" class="flex items-center gap-2 text-theme-xs text-gray-700 dark:text-gray-300">
          <input v-model="form.put_in_maintenance" type="checkbox" class="size-4 rounded border-gray-300 text-brand-600" />
          Inmovilizar unidad ahora (pasar vehículo a estado Mantenimiento)
        </label>
        <label v-else class="flex items-center gap-2 text-theme-xs text-gray-700 dark:text-gray-300">
          <input v-model="form.release_vehicle" type="checkbox" class="size-4 rounded border-gray-300 text-brand-600" />
          Liberar unidad a Disponible si estaba en taller
        </label>
      </form>

      <template #footer>
        <button type="button" class="fleet-btn-secondary" @click="modalOpen = false">Cancelar</button>
        <button type="submit" form="maint-form" :disabled="saving" class="fleet-btn-primary">
          {{ saving ? 'Guardando…' : 'Guardar' }}
        </button>
      </template>
    </BaseModal>

    <!-- Modal completar mantenimiento programado -->
    <BaseModal
      :open="completeOpen"
      title="Completar mantenimiento"
      :subtitle="completingItem ? `${completingItem.vehicle?.license_plate} · ${completingItem.title}` : ''"
      @close="completeOpen = false"
    >
      <form id="complete-form" class="space-y-3.5" @submit.prevent="submitComplete">
        <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <div>
            <label for="mc-km" class="fleet-field-label">Odómetro actual (km) *</label>
            <input id="mc-km" v-model.number="completeForm.completed_odometer_km" type="number" min="0" class="fleet-input tabular-nums" required />
          </div>
          <div>
            <label for="mc-next" class="fleet-field-label">Próximo mant. (km)</label>
            <input id="mc-next" v-model.number="completeForm.next_maintenance_odometer" type="number" min="0" class="fleet-input tabular-nums" />
          </div>
        </div>
        <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <div>
            <label for="mc-work" class="fleet-field-label">Taller</label>
            <input id="mc-work" v-model="completeForm.workshop" type="text" class="fleet-input" />
          </div>
          <div>
            <label for="mc-cost" class="fleet-field-label">Costo ($ USD)</label>
            <input id="mc-cost" v-model.number="completeForm.cost_usd" type="number" step="0.01" min="0" class="fleet-input tabular-nums" />
          </div>
        </div>
        <div>
          <label for="mc-notes" class="fleet-field-label">Notas finales</label>
          <textarea id="mc-notes" v-model="completeForm.notes" rows="2" class="fleet-textarea" />
        </div>
      </form>
      <template #footer>
        <button type="button" class="fleet-btn-secondary" @click="completeOpen = false">Cancelar</button>
        <button type="submit" form="complete-form" :disabled="saving" class="fleet-btn-primary">
          {{ saving ? 'Guardando…' : 'Marcar completado' }}
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
import StatusBadge from '@/components/common/StatusBadge.vue';
import TablePagination from '@/components/common/TablePagination.vue';
import { useAuth } from '../composables/useAuth';
import { confirmDeleteDialog, showErrorAlert, showSuccessAlert } from '../utils/alerts';

const { currentUser, isAdmin, canManageFleet, loadMe, logout } = useAuth();

const records = ref([]);
const alerts = ref([]);
const vehicles = ref([]);
const loading = ref(true);
const saving = ref(false);
const filterVehicleId = ref('');
const filterStatus = ref('');
const modalOpen = ref(false);
const completeOpen = ref(false);
const completingItem = ref(null);
const meta = reactive({ current_page: 1, last_page: 1, total: 0, from: 0, to: 0 });

const form = reactive({
  vehicle_id: '',
  title: '',
  status: 'programado',
  scheduled_odometer_km: null,
  completed_odometer_km: null,
  alert_before_km: 500,
  next_interval_km: 5000,
  workshop: '',
  cost_usd: null,
  description: '',
  put_in_maintenance: false,
  release_vehicle: true,
});

const completeForm = reactive({
  completed_odometer_km: null,
  next_maintenance_odometer: null,
  workshop: '',
  cost_usd: null,
  notes: '',
});

const loadVehicles = async () => {
  const { data } = await window.axios.get('/vehicles/options');
  vehicles.value = data.data || [];
};

const loadData = async (page = 1) => {
  loading.value = true;
  try {
    const { data } = await window.axios.get('/maintenances', {
      params: {
        page,
        vehicle_id: filterVehicleId.value || undefined,
        status: filterStatus.value || undefined,
      },
    });
    alerts.value = data.alerts || [];
    const rec = data.records || {};
    records.value = rec.data || [];
    meta.current_page = rec.current_page ?? 1;
    meta.last_page = rec.last_page ?? 1;
    meta.total = rec.total ?? records.value.length;
    meta.from = rec.from ?? 0;
    meta.to = rec.to ?? 0;
  } finally {
    loading.value = false;
  }
};

const onVehicleChange = () => {
  const v = vehicles.value.find((item) => Number(item.id) === Number(form.vehicle_id));
  if (!v) return;
  form.completed_odometer_km = v.current_odometer ?? 0;
  form.scheduled_odometer_km = (v.current_odometer ?? 0) + (form.next_interval_km || 5000);
};

const openCreate = (preselectVehicleId = '', asCompleted = false) => {
  form.vehicle_id = preselectVehicleId || (vehicles.value[0]?.id ?? '');
  form.title = '';
  form.status = asCompleted ? 'completado' : 'programado';
  form.alert_before_km = 500;
  form.next_interval_km = 5000;
  form.workshop = '';
  form.cost_usd = null;
  form.description = '';
  form.put_in_maintenance = false;
  form.release_vehicle = true;
  onVehicleChange();
  modalOpen.value = true;
};

const submitForm = async () => {
  saving.value = true;
  try {
    await window.axios.post('/maintenances', form);
    await showSuccessAlert('Guardado', 'Mantenimiento registrado correctamente.');
    modalOpen.value = false;
    await Promise.all([loadVehicles(), loadData(1)]);
  } catch (err) {
    const errors = err.response?.data?.errors;
    const first = errors ? Object.values(errors).flat()[0] : null;
    await showErrorAlert('Error', first || err.response?.data?.message || 'No se pudo guardar.');
  } finally {
    saving.value = false;
  }
};

const openComplete = (m) => {
  completingItem.value = m;
  const current = m.vehicle?.current_odometer ?? m.scheduled_odometer_km ?? 0;
  const interval = m.vehicle?.maintenance_interval_km ?? 5000;
  completeForm.completed_odometer_km = current;
  completeForm.next_maintenance_odometer = current + interval;
  completeForm.workshop = m.workshop || '';
  completeForm.cost_usd = m.cost_usd ?? null;
  completeForm.notes = m.notes || '';
  completeOpen.value = true;
};

const submitComplete = async () => {
  if (!completingItem.value) return;
  saving.value = true;
  try {
    await window.axios.post(`/maintenances/${completingItem.value.id}/complete`, completeForm);
    await showSuccessAlert('Completado', 'Mantenimiento cerrado y próximo kilometraje actualizado.');
    completeOpen.value = false;
    await Promise.all([loadVehicles(), loadData(meta.current_page)]);
  } catch (err) {
    await showErrorAlert('Error', err.response?.data?.message || 'No se pudo completar.');
  } finally {
    saving.value = false;
  }
};

const removeRecord = async (m) => {
  const r = await confirmDeleteDialog({ title: '¿Eliminar mantenimiento?', text: m.title });
  if (!r.isConfirmed) return;
  await window.axios.delete(`/maintenances/${m.id}`);
  await showSuccessAlert('Eliminado');
  await loadData(meta.current_page);
};

onMounted(async () => {
  await loadMe();
  await Promise.all([loadVehicles(), loadData(1)]);
});
</script>
