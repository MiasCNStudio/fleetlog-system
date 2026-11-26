<template>
  <AdminLayout header-title="Asignaciones" :user-name="currentUser?.name" @logout="logout(true)">
    <PageBreadcrumb
      page-title="Asignaciones"
      subtitle="Agenda de viajes por día, semana o mes con ubicación exacta e instrucciones oficiales."
    >
      <template v-if="canManageFleet" #actions>
        <button type="button" class="fleet-btn-primary" @click="openCreate">
          <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
          </svg>
          Nueva asignación
        </button>
      </template>
    </PageBreadcrumb>

    <ComponentCard title="Agenda operativa" desc="Viajes programados, instrucciones oficiales y reasignaciones de emergencia.">
      <template #header-extra>
        <span class="rounded-lg bg-gray-100 px-2.5 py-1 text-theme-xs font-semibold tabular-nums text-gray-600 dark:bg-gray-800 dark:text-gray-300">
          {{ meta.total }} {{ meta.total === 1 ? 'asignación' : 'asignaciones' }}
        </span>
      </template>

      <!-- Compact filter bar: quick presets + Filters modal trigger -->
      <div class="fleet-filter-bar flex flex-wrap items-center justify-between gap-2.5">
        <div
          class="inline-flex flex-wrap rounded-xl border border-gray-200 bg-white p-1 dark:border-white/10 dark:bg-[#0b1220]"
          role="group"
          aria-label="Rango rápido de fechas"
        >
          <button
            v-for="preset in datePresets"
            :key="preset.key"
            type="button"
            :aria-pressed="activePreset === preset.key"
            :class="[
              'rounded-lg px-2.5 py-1.5 text-theme-xs font-semibold transition-colors sm:px-3',
              activePreset === preset.key
                ? 'bg-brand-500 text-white shadow-theme-xs'
                : 'text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-white',
            ]"
            @click="applyDatePreset(preset.key)"
          >
            {{ preset.label }}
          </button>
        </div>

        <div class="flex items-center gap-2">
          <button
            type="button"
            class="fleet-btn-secondary h-9 px-3 py-1.5 text-theme-xs"
            @click="openFilterModal"
          >
            <svg class="size-4 text-gray-500 dark:text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 6h9.75M10.5 6a1.5 1.5 0 11-3 0m3 0a1.5 1.5 0 10-3 0M3.75 6H7.5m3 12h9.75m-9.75 0a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m-3.75 0H7.5m9-6h3.75m-3.75 0a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m-9.75 0h9.75" />
            </svg>
            <span>Filtros</span>
            <span
              v-if="activeFilterCount > 0"
              class="inline-flex size-5 items-center justify-center rounded-full bg-brand-500 text-[11px] font-bold text-white"
            >
              {{ activeFilterCount }}
            </span>
          </button>

          <button
            v-if="hasFilters"
            type="button"
            class="fleet-btn-secondary h-9 px-2.5 py-1.5 text-theme-xs"
            @click="resetFilters"
          >
            Limpiar
          </button>
        </div>
      </div>

      <!-- Loading & Empty state -->
      <div v-if="loading" class="space-y-3">
        <div v-for="n in 4" :key="`sk-${n}`" class="h-20 animate-pulse rounded-xl bg-gray-100 dark:bg-gray-800/70" />
      </div>

      <div v-else-if="assignments.length === 0" class="fleet-table-wrap">
        <TableEmptyState
          icon="clipboard"
          :has-filters="hasFilters"
          :title="hasFilters ? 'Sin asignaciones para estos filtros' : 'No hay viajes programados'"
          :description="
            hasFilters
              ? 'Prueba ampliando el rango de fechas o limpiando los filtros.'
              : canManageFleet
                ? 'Agenda asignaciones diarias, semanales o mensuales para los motoristas.'
                : 'Cuando te asignen un viaje aparecerá aquí con su ruta e instrucciones.'
          "
          @reset="resetFilters"
        />
      </div>

      <template v-else>
        <!-- Mobile Cards (< md) -->
        <div class="space-y-3 md:hidden">
          <article
            v-for="a in assignments"
            :key="`mob-${a.id}`"
            class="rounded-2xl border border-gray-200/80 bg-white p-4 shadow-theme-xs dark:border-white/[0.08] dark:bg-[#0b1220]/70"
          >
            <div class="flex items-start justify-between gap-2">
              <div>
                <p class="text-theme-xs font-semibold tabular-nums text-gray-500 dark:text-gray-400">
                  {{ formatDate(a.scheduled_date) }} · {{ a.scheduled_time || 'Hora abierta' }}
                </p>
                <h4 class="mt-0.5 text-theme-sm font-semibold text-gray-900 dark:text-white">
                  {{ a.destination }}
                </h4>
              </div>
              <StatusBadge kind="assignmentStatus" :value="a.status" />
            </div>

            <div class="mt-2.5 flex flex-wrap items-center gap-2 text-theme-xs">
              <span class="rounded-md bg-gray-100 px-2 py-0.5 font-mono font-semibold text-gray-900 dark:bg-gray-800 dark:text-white">
                {{ a.vehicle?.license_plate }}
              </span>
              <span class="text-gray-600 dark:text-gray-300">{{ a.driver?.name || '—' }}</span>
              <span
                v-if="a.is_emergency_reassigned"
                class="rounded-full bg-rose-500/15 px-2 py-0.5 text-[10px] font-semibold text-rose-700 dark:text-rose-300"
              >
                Emergencia
              </span>
            </div>

            <div
              v-if="a.official_instruction"
              class="mt-2.5 rounded-xl border border-amber-300/70 bg-amber-50/80 px-3 py-2 text-theme-xs text-amber-950 dark:border-amber-500/30 dark:bg-amber-500/10 dark:text-amber-100"
            >
              <span class="font-bold uppercase tracking-wider text-amber-800 dark:text-amber-300">Instrucción: </span>
              {{ a.official_instruction }}
            </div>

            <div class="mt-3 flex flex-wrap items-center justify-between gap-2 border-t border-gray-100 pt-3 dark:border-white/[0.06]">
              <div class="flex items-center gap-2">
                <a
                  :href="gmapsLink(a)"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="fleet-btn-secondary h-8 px-2.5 py-1 text-[11px]"
                >
                  Maps ↗
                </a>
                <a
                  :href="wazeLink(a)"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="fleet-btn-secondary h-8 px-2.5 py-1 text-[11px]"
                >
                  Waze ↗
                </a>
              </div>

              <div class="flex flex-wrap items-center gap-1.5">
                <button
                  v-if="canStartAssignment(a)"
                  type="button"
                  class="fleet-btn-primary h-8 px-3 py-1 text-theme-xs"
                  @click="openTripModal(a, 'salida')"
                >
                  Iniciar
                </button>
                <button
                  v-else-if="canReturnAssignment(a)"
                  type="button"
                  class="inline-flex h-8 items-center rounded-xl bg-emerald-600 px-3 text-theme-xs font-semibold text-white"
                  @click="openTripModal(a, 'regreso')"
                >
                  Regreso
                </button>
                <button
                  v-if="canEmergencyTake(a)"
                  type="button"
                  class="inline-flex h-8 items-center rounded-xl bg-amber-500/20 px-2.5 text-theme-xs font-semibold text-amber-900 dark:text-amber-200"
                  @click="openEmergencyModal(a)"
                >
                  Emergencia
                </button>

                <TableRowActions
                  :group-label="`Acciones asignación ${a.id}`"
                  :show-edit="canManageFleet"
                  :show-delete="canManageFleet"
                  @view="openView(a)"
                  @edit="openEdit(a)"
                  @delete="confirmDelete(a)"
                />
              </div>
            </div>
          </article>
        </div>

        <!-- Desktop Table (>= md) -->
        <div class="fleet-table-wrap hidden md:block">
          <div class="max-w-full overflow-x-auto">
            <table class="w-full divide-y divide-gray-200 dark:divide-gray-800">
              <thead>
                <tr>
                  <th scope="col" class="fleet-th">Fecha / Hora</th>
                  <th scope="col" class="fleet-th">Vehículo</th>
                  <th scope="col" class="fleet-th">Motorista</th>
                  <th scope="col" class="fleet-th">Destino</th>
                  <th scope="col" class="fleet-th">Instrucción / Motivo</th>
                  <th scope="col" class="fleet-th">Estado</th>
                  <th scope="col" class="fleet-th text-right">Acciones</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
                <tr v-for="a in assignments" :key="a.id" class="fleet-tr">
                  <td class="fleet-td whitespace-nowrap tabular-nums">
                    <p class="font-medium text-gray-900 dark:text-white">{{ formatDate(a.scheduled_date) }}</p>
                    <p class="text-theme-xs text-gray-500 dark:text-gray-400">
                      {{ a.scheduled_time || 'Hora abierta' }}
                    </p>
                  </td>
                  <td class="fleet-td whitespace-nowrap">
                    <span class="rounded-md bg-gray-100 px-2 py-0.5 font-mono text-theme-xs font-semibold text-gray-900 dark:bg-gray-800 dark:text-white">
                      {{ a.vehicle?.license_plate }}
                    </span>
                    <p class="mt-0.5 text-[11px] text-gray-500 dark:text-gray-400">
                      {{ a.vehicle?.brand }} {{ a.vehicle?.model }}
                    </p>
                  </td>
                  <td class="fleet-td">
                    <div class="space-y-1">
                      <p class="font-medium text-gray-900 dark:text-white">
                        {{ a.driver?.name || '—' }}
                      </p>
                      <div v-if="a.is_emergency_reassigned" class="flex flex-wrap items-center gap-1">
                        <span
                          class="inline-flex items-center gap-1 rounded-full bg-rose-500/15 px-2 py-0.5 text-[11px] font-semibold text-rose-700 ring-1 ring-inset ring-rose-500/20 dark:text-rose-300"
                          :title="a.reassignment_reason || ''"
                        >
                          Emergencia
                        </span>
                        <span v-if="a.original_driver?.name" class="text-[11px] text-gray-500 dark:text-gray-400">
                          por {{ a.original_driver.name }}
                        </span>
                      </div>
                    </div>
                  </td>
                  <td class="fleet-td max-w-[180px]">
                    <p class="truncate font-medium text-gray-900 dark:text-white" :title="a.destination">
                      {{ a.destination }}
                    </p>
                    <div class="mt-1 flex flex-wrap items-center gap-2 text-[11px]">
                      <a
                        :href="gmapsLink(a)"
                        target="_blank"
                        rel="noopener noreferrer"
                        class="font-medium text-brand-600 hover:underline dark:text-brand-400"
                      >
                        Maps ↗
                      </a>
                      <a
                        :href="wazeLink(a)"
                        target="_blank"
                        rel="noopener noreferrer"
                        class="font-medium text-sky-600 hover:underline dark:text-sky-400"
                      >
                        Waze ↗
                      </a>
                    </div>
                  </td>
                  <td class="fleet-td max-w-[190px]">
                    <div v-if="a.official_instruction" class="mb-1">
                      <span class="inline-flex items-center gap-1 rounded-md bg-amber-500/15 px-1.5 py-0.5 text-[11px] font-semibold text-amber-800 dark:text-amber-300">
                        Instrucción oficial
                      </span>
                      <p class="mt-0.5 truncate text-theme-xs font-medium text-gray-800 dark:text-gray-200" :title="a.official_instruction">
                        {{ a.official_instruction }}
                      </p>
                    </div>
                    <p v-if="a.description" class="truncate text-theme-xs text-gray-500 dark:text-gray-400" :title="a.description">
                      {{ a.description }}
                    </p>
                    <span v-if="!a.official_instruction && !a.description" class="text-theme-xs text-gray-400">—</span>
                  </td>
                  <td class="fleet-td whitespace-nowrap">
                    <StatusBadge kind="assignmentStatus" :value="a.status" />
                  </td>
                  <td class="fleet-td whitespace-nowrap text-right">
                    <div class="inline-flex items-center justify-end gap-1">
                      <button
                        v-if="canStartAssignment(a)"
                        type="button"
                        class="inline-flex h-8 items-center gap-1 rounded-lg bg-brand-500/10 px-2.5 text-theme-xs font-semibold text-brand-600 transition-colors hover:bg-brand-500/20 dark:text-brand-300"
                        title="Iniciar viaje en bitácora"
                        @click="openTripModal(a, 'salida')"
                      >
                        Iniciar
                      </button>
                      <button
                        v-else-if="canReturnAssignment(a)"
                        type="button"
                        class="inline-flex h-8 items-center gap-1 rounded-lg bg-emerald-500/15 px-2.5 text-theme-xs font-semibold text-emerald-700 transition-colors hover:bg-emerald-500/25 dark:text-emerald-300"
                        title="Registrar regreso"
                        @click="openTripModal(a, 'regreso')"
                      >
                        Regreso
                      </button>
                      <button
                        v-if="canEmergencyTake(a)"
                        type="button"
                        class="inline-flex h-8 items-center gap-1 rounded-lg bg-amber-500/15 px-2.5 text-theme-xs font-semibold text-amber-800 transition-colors hover:bg-amber-500/25 dark:text-amber-300"
                        title="Tomar asignación por emergencia"
                        @click="openEmergencyModal(a)"
                      >
                        Emergencia
                      </button>

                      <TableRowActions
                        :group-label="`Acciones asignación ${a.id}`"
                        :show-edit="canManageFleet"
                        :show-delete="canManageFleet"
                        @view="openView(a)"
                        @edit="openEdit(a)"
                        @delete="confirmDelete(a)"
                      />
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <TablePagination
          :current-page="meta.current_page"
          :last-page="meta.last_page"
          :total="meta.total"
          :from="meta.from"
          :to="meta.to"
          @change="changePage"
        />
      </template>
    </ComponentCard>

    <!-- Filters Modal -->
    <BaseModal
      :open="filterModalOpen"
      title="Filtrar asignaciones"
      subtitle="Elige los criterios y presiona aplicar para actualizar la agenda."
      @close="filterModalOpen = false"
    >
      <form id="assign-filters-form" class="space-y-4" @submit.prevent="applyFilterModal">
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div>
            <label for="modal-filter-from" class="fleet-field-label">Desde</label>
            <input id="modal-filter-from" v-model="draftFilters.dateFrom" type="date" class="fleet-input" />
          </div>
          <div>
            <label for="modal-filter-to" class="fleet-field-label">Hasta</label>
            <input id="modal-filter-to" v-model="draftFilters.dateTo" type="date" class="fleet-input" />
          </div>
        </div>

        <div>
          <label for="modal-filter-driver" class="fleet-field-label">Motorista</label>
          <select id="modal-filter-driver" v-model="draftFilters.driverId" class="fleet-select">
            <option value="">Todos los motoristas</option>
            <option v-for="d in driverOptions" :key="d.id" :value="String(d.id)">
              {{ d.name }} {{ d.driver_code ? `(${d.driver_code})` : '' }}
            </option>
          </select>
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div>
            <label for="modal-filter-vehicle" class="fleet-field-label">Vehículo</label>
            <select id="modal-filter-vehicle" v-model="draftFilters.vehicleId" class="fleet-select">
              <option value="">Todos los vehículos</option>
              <option v-for="v in vehicleOptions" :key="v.id" :value="String(v.id)">
                {{ v.license_plate }} — {{ v.brand }} {{ v.model }}
              </option>
            </select>
          </div>
          <div>
            <label for="modal-filter-status" class="fleet-field-label">Estado</label>
            <select id="modal-filter-status" v-model="draftFilters.status" class="fleet-select">
              <option value="">Todos</option>
              <option value="pendiente">Pendiente</option>
              <option value="en_curso">En curso</option>
              <option value="completada">Completada</option>
              <option value="cancelada">Cancelada</option>
            </select>
          </div>
        </div>

        <label class="flex cursor-pointer items-center gap-2.5 rounded-xl border border-gray-200/80 bg-gray-50/70 px-3.5 py-2.5 text-theme-sm font-medium text-gray-700 dark:border-white/10 dark:bg-white/[0.02] dark:text-gray-200">
          <input
            v-model="draftFilters.mine"
            type="checkbox"
            class="size-4 rounded border-gray-300 text-brand-500 focus:ring-brand-500"
          />
          Mostrar solo mis viajes asignados
        </label>
      </form>

      <template #footer>
        <button type="button" class="fleet-btn-secondary" @click="clearFilterModal">
          Limpiar todo
        </button>
        <button type="submit" form="assign-filters-form" class="fleet-btn-primary">
          Aplicar filtros
        </button>
      </template>
    </BaseModal>

    <!-- Create / Edit Assignment Modal -->
    <BaseModal
      :open="modalOpen"
      max-width="xl"
      :title="editingId ? 'Editar asignación' : 'Nueva asignación'"
      :subtitle="editingId ? 'Actualiza los datos del viaje programado.' : 'Programa un día específico o agenda semanas y meses completos.'"
      @close="closeModal"
    >
      <form id="assignment-form" class="space-y-4" @submit.prevent="submitAssignment">
        <div v-if="!editingId" class="rounded-xl border border-gray-200/80 bg-gray-50/80 p-3 dark:border-white/[0.07] dark:bg-white/[0.02]">
          <p class="fleet-label mb-2">Modo de programación</p>
          <div class="grid grid-cols-2 gap-2">
            <button
              type="button"
              :class="[
                'rounded-xl border px-3 py-2 text-theme-xs font-semibold transition-colors',
                scheduleMode === 'single'
                  ? 'border-brand-500 bg-brand-50 text-brand-700 dark:bg-brand-500/15 dark:text-brand-300'
                  : 'border-gray-200 bg-white text-gray-600 dark:border-white/10 dark:bg-[#0b1220] dark:text-gray-300',
              ]"
              @click="scheduleMode = 'single'"
            >
              Día específico
            </button>
            <button
              type="button"
              :class="[
                'rounded-xl border px-3 py-2 text-theme-xs font-semibold transition-colors',
                scheduleMode === 'range'
                  ? 'border-brand-500 bg-brand-50 text-brand-700 dark:bg-brand-500/15 dark:text-brand-300'
                  : 'border-gray-200 bg-white text-gray-600 dark:border-white/10 dark:bg-[#0b1220] dark:text-gray-300',
              ]"
              @click="scheduleMode = 'range'"
            >
              Semanas / Meses
            </button>
          </div>
        </div>

        <div v-if="editingId || scheduleMode === 'single'" class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div>
            <label for="assign-date" class="fleet-field-label">
              Fecha programada <span class="text-rose-500">*</span>
            </label>
            <input id="assign-date" v-model="form.scheduled_date" type="date" class="fleet-input" required />
          </div>
          <div>
            <label for="assign-time" class="fleet-field-label">Hora sugerida (opcional)</label>
            <input id="assign-time" v-model="form.scheduled_time" type="time" class="fleet-input" />
          </div>
        </div>

        <div v-else class="space-y-3 rounded-xl border border-gray-200/80 p-3.5 dark:border-white/10">
          <div class="grid grid-cols-1 gap-3 sm:grid-cols-3">
            <div>
              <label for="assign-from" class="fleet-field-label">
                Desde <span class="text-rose-500">*</span>
              </label>
              <input id="assign-from" v-model="form.date_from" type="date" class="fleet-input" required />
            </div>
            <div>
              <label for="assign-to" class="fleet-field-label">
                Hasta <span class="text-rose-500">*</span>
              </label>
              <input id="assign-to" v-model="form.date_to" type="date" class="fleet-input" required />
            </div>
            <div>
              <label for="assign-time-range" class="fleet-field-label">Hora sugerida</label>
              <input id="assign-time-range" v-model="form.scheduled_time" type="time" class="fleet-input" />
            </div>
          </div>

          <div>
            <p class="fleet-label mb-1.5">Días de la semana</p>
            <div class="flex flex-wrap gap-1.5">
              <button
                v-for="wd in weekdayChoices"
                :key="wd.value"
                type="button"
                :class="[
                  'rounded-lg border px-2.5 py-1 text-theme-xs font-semibold transition-colors',
                  form.weekdays.includes(wd.value)
                    ? 'border-brand-500 bg-brand-500 text-white'
                    : 'border-gray-200 bg-white text-gray-600 dark:border-white/10 dark:bg-[#0b1220] dark:text-gray-300',
                ]"
                @click="toggleWeekday(wd.value)"
              >
                {{ wd.label }}
              </button>
            </div>
            <p class="mt-2 text-theme-xs font-medium text-brand-600 dark:text-brand-300">
              Se programarán {{ plannedDaysCount }} {{ plannedDaysCount === 1 ? 'asignación' : 'asignaciones' }} en el calendario.
            </p>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div>
            <label for="assign-driver" class="fleet-field-label">
              Motorista asignado <span class="text-rose-500">*</span>
            </label>
            <select id="assign-driver" v-model="form.driver_id" required class="fleet-select">
              <option value="" disabled>Seleccione motorista…</option>
              <option v-for="d in driverOptions" :key="d.id" :value="String(d.id)">
                {{ d.name }} {{ d.driver_code ? `(${d.driver_code})` : '' }}
              </option>
            </select>
          </div>

          <div>
            <label for="assign-vehicle" class="fleet-field-label">
              Vehículo <span class="text-rose-500">*</span>
            </label>
            <select id="assign-vehicle" v-model="form.vehicle_id" required class="fleet-select">
              <option value="" disabled>Seleccione unidad…</option>
              <option v-for="v in vehicleOptions" :key="v.id" :value="String(v.id)">
                {{ v.license_plate }} — {{ v.brand }} {{ v.model }}
              </option>
            </select>
          </div>
        </div>

        <div v-if="editingId">
          <label for="assign-status-edit" class="fleet-field-label">Estado</label>
          <select id="assign-status-edit" v-model="form.status" class="fleet-select">
            <option value="pendiente">Pendiente</option>
            <option value="en_curso">En curso</option>
            <option value="completada">Completada</option>
            <option value="cancelada">Cancelada</option>
          </select>
        </div>

        <MapLocationPicker
          v-model:destination="form.destination"
          v-model:destination-address="form.destination_address"
          v-model:latitude="form.latitude"
          v-model:longitude="form.longitude"
          v-model:place-id="form.place_id"
          label="Destino exacto en el mapa"
          required
        />

        <div>
          <label for="assign-companions" class="fleet-field-label">Acompañantes / personas (opcional)</label>
          <input
            id="assign-companions"
            v-model="form.companions"
            type="text"
            class="fleet-input"
            placeholder="Nombres de compañeros que viajan, o dejar vacío si va solo"
          />
        </div>

        <div>
          <label for="assign-description" class="fleet-field-label">Descripción del viaje</label>
          <textarea
            id="assign-description"
            v-model="form.description"
            rows="2"
            class="fleet-textarea"
            placeholder="Ej. Ir a entregar regalos en evento institucional"
          />
        </div>

        <div class="rounded-xl border border-amber-300/80 bg-amber-50/70 p-3.5 dark:border-amber-500/30 dark:bg-amber-500/10">
          <label for="assign-instruction" class="fleet-field-label text-amber-900 dark:text-amber-200">
            Instrucción oficial (indicación obligatoria para el motorista)
          </label>
          <textarea
            id="assign-instruction"
            v-model="form.official_instruction"
            rows="2"
            class="fleet-textarea border-amber-300/80 focus:border-amber-500 focus:ring-amber-500/20 dark:border-amber-500/30"
            placeholder="Ej. Esperar a los compañeros a que regresen antes de mover la unidad"
          />
        </div>
      </form>

      <template #footer>
        <button type="button" class="fleet-btn-secondary" @click="closeModal">Cancelar</button>
        <button type="submit" form="assignment-form" :disabled="saving" class="fleet-btn-primary">
          {{ saving ? 'Guardando…' : editingId ? 'Guardar cambios' : 'Programar asignación' }}
        </button>
      </template>
    </BaseModal>

    <!-- Detail Modal -->
    <BaseModal
      :open="detailOpen"
      max-width="xl"
      :title="detailItem?.destination || 'Detalle de asignación'"
      :subtitle="detailItem ? `${formatDate(detailItem.scheduled_date)}${detailItem.scheduled_time ? ` · ${detailItem.scheduled_time}` : ''}` : ''"
      @close="detailOpen = false"
    >
      <div v-if="detailItem" class="space-y-4">
        <div class="flex flex-wrap items-center justify-between gap-2 rounded-xl border border-gray-200/80 bg-gray-50/80 px-4 py-3 dark:border-white/[0.07] dark:bg-white/[0.02]">
          <StatusBadge kind="assignmentStatus" :value="detailItem.status" />
          <span class="font-mono text-theme-xs font-semibold text-gray-800 dark:text-gray-200">
            {{ detailItem.vehicle?.license_plate }} · {{ detailItem.vehicle?.brand }} {{ detailItem.vehicle?.model }}
          </span>
        </div>

        <div
          v-if="detailItem.official_instruction"
          class="rounded-xl border border-amber-300 bg-amber-50 p-4 dark:border-amber-500/35 dark:bg-amber-500/10"
        >
          <p class="text-[11px] font-bold uppercase tracking-wider text-amber-800 dark:text-amber-300">
            Instrucción oficial obligatoria
          </p>
          <p class="mt-1 whitespace-pre-line text-theme-sm font-medium text-amber-950 dark:text-amber-100">
            {{ detailItem.official_instruction }}
          </p>
        </div>

        <div
          v-if="detailItem.is_emergency_reassigned"
          class="rounded-xl border border-rose-200 bg-rose-50 p-4 dark:border-rose-500/30 dark:bg-rose-500/10"
        >
          <p class="text-[11px] font-bold uppercase tracking-wider text-rose-700 dark:text-rose-300">
            Reasignación por emergencia (no oficial)
          </p>
          <p class="mt-1 text-theme-sm text-rose-900 dark:text-rose-100">
            <strong>{{ detailItem.driver?.name }}</strong> cubrió el viaje en lugar de
            <strong>{{ detailItem.original_driver?.name || 'motorista original' }}</strong>.
          </p>
          <p class="mt-1 text-theme-xs text-rose-800 dark:text-rose-200">
            <strong>Razón reportada:</strong> {{ detailItem.reassignment_reason }}
          </p>
        </div>

        <dl class="grid grid-cols-1 gap-3 text-theme-sm sm:grid-cols-2">
          <div class="rounded-xl border border-gray-100 p-3 dark:border-white/[0.07]">
            <dt class="text-theme-xs text-gray-500 dark:text-gray-400">Motorista asignado</dt>
            <dd class="mt-0.5 font-medium text-gray-900 dark:text-white">{{ detailItem.driver?.name || '—' }}</dd>
          </div>
          <div class="rounded-xl border border-gray-100 p-3 dark:border-white/[0.07]">
            <dt class="text-theme-xs text-gray-500 dark:text-gray-400">Acompañantes</dt>
            <dd class="mt-0.5 font-medium text-gray-900 dark:text-white">{{ detailItem.companions || 'Sin acompañantes' }}</dd>
          </div>
        </dl>

        <div v-if="detailItem.description" class="rounded-xl border border-gray-100 p-3.5 text-theme-sm dark:border-white/[0.07]">
          <p class="text-theme-xs font-medium text-gray-500 dark:text-gray-400">Descripción del viaje</p>
          <p class="mt-1 whitespace-pre-line text-gray-900 dark:text-gray-100">{{ detailItem.description }}</p>
        </div>

        <div class="rounded-xl border border-gray-100 p-3.5 text-theme-sm dark:border-white/[0.07]">
          <p class="text-theme-xs font-medium text-gray-500 dark:text-gray-400">Ubicación exacta</p>
          <p class="mt-1 font-medium text-gray-900 dark:text-white">{{ detailItem.destination }}</p>
          <p v-if="detailItem.destination_address" class="mt-0.5 text-theme-xs text-gray-500 dark:text-gray-400">
            {{ detailItem.destination_address }}
          </p>
          <p v-if="hasCoordinates(detailItem.latitude, detailItem.longitude)" class="mt-1 font-mono text-[11px] text-gray-500">
            {{ formatCoordinates(detailItem.latitude, detailItem.longitude) }}
          </p>

          <div class="mt-3 flex flex-wrap gap-2">
            <a :href="gmapsLink(detailItem)" target="_blank" rel="noopener noreferrer" class="fleet-btn-primary h-9 px-3.5 py-1.5 text-theme-xs">
              Abrir en Google Maps ↗
            </a>
            <a :href="wazeLink(detailItem)" target="_blank" rel="noopener noreferrer" class="fleet-btn-secondary h-9 px-3.5 py-1.5 text-theme-xs">
              Abrir en Waze ↗
            </a>
          </div>
        </div>
      </div>

      <template #footer>
        <button
          v-if="detailItem && canStartAssignment(detailItem)"
          type="button"
          class="fleet-btn-primary"
          @click="detailOpen = false; openTripModal(detailItem, 'salida')"
        >
          Iniciar viaje en bitácora
        </button>
        <button
          v-else-if="detailItem && canReturnAssignment(detailItem)"
          type="button"
          class="fleet-btn-primary"
          @click="detailOpen = false; openTripModal(detailItem, 'regreso')"
        >
          Registrar regreso
        </button>
        <button
          v-if="detailItem && canEmergencyTake(detailItem)"
          type="button"
          class="fleet-btn-secondary"
          @click="detailOpen = false; openEmergencyModal(detailItem)"
        >
          Tomar por emergencia
        </button>
        <button type="button" class="fleet-btn-secondary" @click="detailOpen = false">Cerrar</button>
      </template>
    </BaseModal>

    <!-- Trip Execution Modal -->
    <BaseModal
      :open="tripModalOpen"
      :title="tripType === 'salida' ? 'Iniciar viaje asignado' : 'Registrar regreso de unidad'"
      :subtitle="tripAssignment ? `${tripAssignment.vehicle?.license_plate} · ${tripAssignment.destination}` : ''"
      @close="tripModalOpen = false"
    >
      <form id="trip-exec-form" class="space-y-4" @submit.prevent="submitTrip">
        <div
          v-if="tripType === 'salida' && tripAssignment?.official_instruction"
          class="rounded-xl border border-amber-300 bg-amber-50 p-3.5 dark:border-amber-500/35 dark:bg-amber-500/10"
        >
          <p class="text-[11px] font-bold uppercase tracking-wider text-amber-800 dark:text-amber-300">
            Toma en cuenta esta instrucción oficial
          </p>
          <p class="mt-1 text-theme-sm font-medium text-amber-950 dark:text-amber-100">
            {{ tripAssignment.official_instruction }}
          </p>
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div>
            <label for="trip-odometer" class="fleet-field-label">Odómetro actual (km)</label>
            <input
              id="trip-odometer"
              v-model.number="tripForm.odometer_km"
              type="number"
              min="0"
              class="fleet-input tabular-nums"
            />
          </div>
          <div>
            <label for="trip-fuel" class="fleet-field-label">Combustible</label>
            <select id="trip-fuel" v-model="tripForm.fuel_level" class="fleet-select">
              <option value="">Sin especificar</option>
              <option value="lleno">Lleno</option>
              <option value="3/4">3/4</option>
              <option value="1/2">1/2</option>
              <option value="1/4">1/4</option>
              <option value="reserva">Reserva</option>
            </select>
          </div>
        </div>

        <div v-if="tripType === 'regreso'">
          <label for="trip-notes" class="fleet-field-label">Notas de regreso (opcional)</label>
          <textarea
            id="trip-notes"
            v-model="tripForm.destination"
            rows="2"
            class="fleet-textarea"
            placeholder="Novedades del recorrido al regresar"
          />
        </div>
      </form>

      <template #footer>
        <button type="button" class="fleet-btn-secondary" @click="tripModalOpen = false">Cancelar</button>
        <button type="submit" form="trip-exec-form" :disabled="saving" class="fleet-btn-primary">
          {{ saving ? 'Registrando…' : tripType === 'salida' ? 'Confirmar salida' : 'Confirmar regreso' }}
        </button>
      </template>
    </BaseModal>

    <!-- Emergency Reassign Modal -->
    <BaseModal
      :open="emergencyOpen"
      title="Tomar asignación por emergencia"
      subtitle="Este cambio quedará reportado como sustitución de emergencia (no oficial) con su justificación."
      @close="emergencyOpen = false"
    >
      <form id="emergency-form" class="space-y-4" @submit.prevent="submitEmergency">
        <div v-if="emergencyItem" class="rounded-xl border border-gray-200/80 bg-gray-50/80 p-3.5 text-theme-sm dark:border-white/[0.07] dark:bg-white/[0.02]">
          <p class="font-semibold text-gray-900 dark:text-white">{{ emergencyItem.destination }}</p>
          <p class="mt-1 text-theme-xs text-gray-600 dark:text-gray-300">
            Originalmente asignado a: <strong>{{ emergencyItem.driver?.name }}</strong> · Unidad: <strong>{{ emergencyItem.vehicle?.license_plate }}</strong>
          </p>
        </div>

        <div v-if="canManageFleet">
          <label for="emergency-driver" class="fleet-field-label">Nuevo motorista que cubrirá el viaje</label>
          <select id="emergency-driver" v-model="emergencyForm.new_driver_id" class="fleet-select" required>
            <option value="" disabled>Seleccione motorista…</option>
            <option v-for="d in driverOptions" :key="d.id" :value="String(d.id)">
              {{ d.name }} {{ d.driver_code ? `(${d.driver_code})` : '' }}
            </option>
          </select>
        </div>

        <div>
          <label for="emergency-reason" class="fleet-field-label">
            Razón justificada de la emergencia <span class="text-rose-500">*</span>
          </label>
          <textarea
            id="emergency-reason"
            v-model="emergencyForm.reassignment_reason"
            rows="3"
            minlength="5"
            required
            class="fleet-textarea"
            placeholder="Ej. El motorista titular tuvo un percance médico y se requiere cubrir la ruta de inmediato."
          />
        </div>
      </form>

      <template #footer>
        <button type="button" class="fleet-btn-secondary" @click="emergencyOpen = false">Cancelar</button>
        <button type="submit" form="emergency-form" :disabled="saving" class="fleet-btn-primary">
          {{ saving ? 'Reportando…' : 'Confirmar reasignación' }}
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
import MapLocationPicker from '@/components/common/MapLocationPicker.vue';
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue';
import StatusBadge from '@/components/common/StatusBadge.vue';
import TableEmptyState from '@/components/common/TableEmptyState.vue';
import TablePagination from '@/components/common/TablePagination.vue';
import TableRowActions from '@/components/common/TableRowActions.vue';
import { useAuth } from '../composables/useAuth';
import { confirmDeleteDialog, showErrorAlert, showSuccessAlert } from '../utils/alerts';
import { formatCoordinates, googleMapsUrl, hasCoordinates, wazeUrl } from '../utils/maps';

const { currentUser, canManageFleet, ensureMe, logout } = useAuth();

const assignments = ref([]);
const vehicleOptions = ref([]);
const driverOptions = ref([]);
const loading = ref(true);
const saving = ref(false);
const meta = ref({ current_page: 1, last_page: 1, total: 0, from: 0, to: 0 });

const activePreset = ref('all');
const filterDateFrom = ref('');
const filterDateTo = ref('');
const filterDriverId = ref('');
const filterVehicleId = ref('');
const filterStatus = ref('');
const filterMine = ref(false);

const filterModalOpen = ref(false);
const draftFilters = reactive({
  dateFrom: '',
  dateTo: '',
  driverId: '',
  vehicleId: '',
  status: '',
  mine: false,
});

const modalOpen = ref(false);
const editingId = ref(null);
const scheduleMode = ref('single');

const detailOpen = ref(false);
const detailItem = ref(null);

const tripModalOpen = ref(false);
const tripAssignment = ref(null);
const tripType = ref('salida');
const tripForm = reactive({ odometer_km: null, fuel_level: '', destination: '' });

const emergencyOpen = ref(false);
const emergencyItem = ref(null);
const emergencyForm = reactive({ new_driver_id: '', reassignment_reason: '' });

const todayIso = () => new Date().toISOString().slice(0, 10);

const form = reactive({
  vehicle_id: '',
  driver_id: '',
  scheduled_date: todayIso(),
  date_from: todayIso(),
  date_to: todayIso(),
  weekdays: [1, 2, 3, 4, 5],
  scheduled_time: '',
  destination: '',
  destination_address: '',
  latitude: null,
  longitude: null,
  place_id: '',
  companions: '',
  description: '',
  official_instruction: '',
  status: 'pendiente',
});

const datePresets = [
  { key: 'today', label: 'Hoy' },
  { key: 'week', label: 'Semana' },
  { key: 'month', label: 'Mes' },
  { key: 'all', label: 'Todas' },
];

const weekdayChoices = [
  { value: 1, label: 'Lun' },
  { value: 2, label: 'Mar' },
  { value: 3, label: 'Mié' },
  { value: 4, label: 'Jue' },
  { value: 5, label: 'Vie' },
  { value: 6, label: 'Sáb' },
  { value: 0, label: 'Dom' },
];

const activeFilterCount = computed(() => {
  let count = 0;
  if (filterDateFrom.value || filterDateTo.value) count += 1;
  if (filterDriverId.value) count += 1;
  if (filterVehicleId.value) count += 1;
  if (filterStatus.value) count += 1;
  if (filterMine.value) count += 1;
  return count;
});

const hasFilters = computed(() => activeFilterCount.value > 0);

const plannedDaysCount = computed(() => {
  if (!form.date_from || !form.date_to) return 0;
  const start = new Date(`${form.date_from}T00:00:00`);
  const end = new Date(`${form.date_to}T00:00:00`);
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime()) || end < start) return 0;

  let count = 0;
  const cur = new Date(start);
  let guard = 0;
  while (cur <= end && guard < 120) {
    if (form.weekdays.length === 0 || form.weekdays.includes(cur.getDay())) {
      count += 1;
    }
    cur.setDate(cur.getDate() + 1);
    guard += 1;
  }
  return count;
});

const formatDate = (dateStr) => {
  if (!dateStr) return '—';
  const clean = String(dateStr).slice(0, 10);
  const [y, m, d] = clean.split('-');
  if (!y || !m || !d) return dateStr;
  return `${d}/${m}/${y}`;
};

const gmapsLink = (a) =>
  googleMapsUrl({
    destination: a.destination,
    destinationAddress: a.destination_address,
    latitude: a.latitude,
    longitude: a.longitude,
  });

const wazeLink = (a) =>
  wazeUrl({
    destination: a.destination,
    destinationAddress: a.destination_address,
    latitude: a.latitude,
    longitude: a.longitude,
  });

const canStartAssignment = (a) =>
  a.status === 'pendiente' && (canManageFleet.value || Number(a.driver_id) === Number(currentUser.value?.id));

const canReturnAssignment = (a) =>
  a.status === 'en_curso' && (canManageFleet.value || Number(a.driver_id) === Number(currentUser.value?.id));

const canEmergencyTake = (a) =>
  a.status === 'pendiente' && Number(a.driver_id) !== Number(currentUser.value?.id);

const openFilterModal = () => {
  draftFilters.dateFrom = filterDateFrom.value;
  draftFilters.dateTo = filterDateTo.value;
  draftFilters.driverId = filterDriverId.value;
  draftFilters.vehicleId = filterVehicleId.value;
  draftFilters.status = filterStatus.value;
  draftFilters.mine = filterMine.value;
  filterModalOpen.value = true;
};

const applyFilterModal = () => {
  filterDateFrom.value = draftFilters.dateFrom;
  filterDateTo.value = draftFilters.dateTo;
  filterDriverId.value = draftFilters.driverId;
  filterVehicleId.value = draftFilters.vehicleId;
  filterStatus.value = draftFilters.status;
  filterMine.value = draftFilters.mine;
  activePreset.value = filterDateFrom.value || filterDateTo.value ? 'custom' : 'all';
  filterModalOpen.value = false;
  loadAssignments(1);
};

const clearFilterModal = () => {
  draftFilters.dateFrom = '';
  draftFilters.dateTo = '';
  draftFilters.driverId = '';
  draftFilters.vehicleId = '';
  draftFilters.status = '';
  draftFilters.mine = false;
  applyFilterModal();
};

const applyDatePreset = (key) => {
  activePreset.value = key;
  const now = new Date();
  const toIso = (dt) => dt.toISOString().slice(0, 10);

  if (key === 'today') {
    const t = toIso(now);
    filterDateFrom.value = t;
    filterDateTo.value = t;
  } else if (key === 'week') {
    const start = new Date(now);
    const day = start.getDay();
    const diff = day === 0 ? -6 : 1 - day;
    start.setDate(start.getDate() + diff);
    const end = new Date(start);
    end.setDate(start.getDate() + 6);
    filterDateFrom.value = toIso(start);
    filterDateTo.value = toIso(end);
  } else if (key === 'month') {
    const start = new Date(now.getFullYear(), now.getMonth(), 1);
    const end = new Date(now.getFullYear(), now.getMonth() + 1, 0);
    filterDateFrom.value = toIso(start);
    filterDateTo.value = toIso(end);
  } else {
    filterDateFrom.value = '';
    filterDateTo.value = '';
  }

  loadAssignments(1);
};

const resetFilters = () => {
  activePreset.value = 'all';
  filterDateFrom.value = '';
  filterDateTo.value = '';
  filterDriverId.value = '';
  filterVehicleId.value = '';
  filterStatus.value = '';
  filterMine.value = false;
  loadAssignments(1);
};

const loadVehicles = async () => {
  const { data } = await window.axios.get('/vehicles/options');
  vehicleOptions.value = data.data || [];
};

const loadDrivers = async () => {
  const { data } = await window.axios.get('/drivers/options');
  driverOptions.value = data.data || [];
};

const loadAssignments = async (page = 1) => {
  loading.value = true;
  try {
    const params = { page, per_page: 20 };
    if (filterDateFrom.value) params.date_from = filterDateFrom.value;
    if (filterDateTo.value) params.date_to = filterDateTo.value;
    if (filterDriverId.value) params.driver_id = filterDriverId.value;
    if (filterVehicleId.value) params.vehicle_id = filterVehicleId.value;
    if (filterStatus.value) params.status = filterStatus.value;
    if (filterMine.value) params.mine = 1;

    const { data } = await window.axios.get('/assignments', { params });
    assignments.value = data.data || [];
    meta.value = {
      current_page: data.current_page ?? 1,
      last_page: data.last_page ?? 1,
      total: data.total ?? assignments.value.length,
      from: data.from ?? 0,
      to: data.to ?? 0,
    };
  } catch (_) {
    /* manejado */
  } finally {
    loading.value = false;
  }
};

const changePage = (page) => {
  if (page < 1 || page > meta.value.last_page) return;
  loadAssignments(page);
};

const toggleWeekday = (val) => {
  const idx = form.weekdays.indexOf(val);
  if (idx >= 0) {
    form.weekdays.splice(idx, 1);
  } else {
    form.weekdays.push(val);
  }
};

const openCreate = () => {
  editingId.value = null;
  scheduleMode.value = 'single';
  form.vehicle_id = '';
  form.driver_id = '';
  form.scheduled_date = todayIso();
  form.date_from = todayIso();
  form.date_to = todayIso();
  form.weekdays = [1, 2, 3, 4, 5];
  form.scheduled_time = '';
  form.destination = '';
  form.destination_address = '';
  form.latitude = null;
  form.longitude = null;
  form.place_id = '';
  form.companions = '';
  form.description = '';
  form.official_instruction = '';
  form.status = 'pendiente';
  modalOpen.value = true;
};

const openEdit = (a) => {
  editingId.value = a.id;
  scheduleMode.value = 'single';
  form.vehicle_id = String(a.vehicle_id);
  form.driver_id = String(a.driver_id);
  form.scheduled_date = String(a.scheduled_date || '').slice(0, 10);
  form.scheduled_time = a.scheduled_time || '';
  form.destination = a.destination || '';
  form.destination_address = a.destination_address || '';
  form.latitude = a.latitude ?? null;
  form.longitude = a.longitude ?? null;
  form.place_id = a.place_id || '';
  form.companions = a.companions || '';
  form.description = a.description || '';
  form.official_instruction = a.official_instruction || '';
  form.status = a.status || 'pendiente';
  modalOpen.value = true;
};

const closeModal = () => {
  modalOpen.value = false;
};

const openView = (a) => {
  detailItem.value = a;
  detailOpen.value = true;
};

const submitAssignment = async () => {
  if (saving.value) return;
  saving.value = true;
  try {
    const basePayload = {
      vehicle_id: Number(form.vehicle_id),
      driver_id: Number(form.driver_id),
      scheduled_time: form.scheduled_time || null,
      destination: form.destination.trim(),
      destination_address: form.destination_address?.trim() || null,
      latitude: form.latitude !== null && form.latitude !== '' ? Number(form.latitude) : null,
      longitude: form.longitude !== null && form.longitude !== '' ? Number(form.longitude) : null,
      place_id: form.place_id || null,
      companions: form.companions?.trim() || null,
      description: form.description?.trim() || null,
      official_instruction: form.official_instruction?.trim() || null,
    };

    if (editingId.value) {
      await window.axios.put(`/assignments/${editingId.value}`, {
        ...basePayload,
        scheduled_date: form.scheduled_date,
        status: form.status,
      });
      await showSuccessAlert('Asignación actualizada');
    } else if (scheduleMode.value === 'range') {
      const { data } = await window.axios.post('/assignments', {
        ...basePayload,
        date_from: form.date_from,
        date_to: form.date_to,
        weekdays: form.weekdays,
      });
      await showSuccessAlert(`${data.created_count || 1} asignaciones programadas`);
    } else {
      await window.axios.post('/assignments', {
        ...basePayload,
        scheduled_date: form.scheduled_date,
      });
      await showSuccessAlert('Asignación creada');
    }

    closeModal();
    await loadAssignments(meta.value.current_page);
  } catch (err) {
    const errors = err.response?.data?.errors;
    const firstErr = errors ? Object.values(errors).flat()[0] : null;
    await showErrorAlert('Error', firstErr || err.response?.data?.message || 'No se pudo guardar');
  } finally {
    saving.value = false;
  }
};

const openTripModal = (a, type) => {
  tripAssignment.value = a;
  tripType.value = type;
  tripForm.odometer_km = a.vehicle?.current_odometer ?? null;
  tripForm.fuel_level = '';
  tripForm.destination = '';
  tripModalOpen.value = true;
};

const submitTrip = async () => {
  if (saving.value || !tripAssignment.value) return;
  saving.value = true;
  try {
    const payload = {
      assignment_id: tripAssignment.value.id,
      vehicle_id: tripAssignment.value.vehicle_id,
      odometer_km:
        tripForm.odometer_km !== null && tripForm.odometer_km !== '' ? Number(tripForm.odometer_km) : null,
      fuel_level: tripForm.fuel_level || null,
    };
    if (tripType.value === 'regreso' && tripForm.destination.trim()) {
      payload.destination = tripForm.destination.trim();
    }

    await window.axios.post('/bitacoras', payload);
    tripModalOpen.value = false;
    await showSuccessAlert(tripType.value === 'salida' ? 'Salida registrada' : 'Regreso registrado');
    await Promise.all([loadVehicles(), loadAssignments(meta.value.current_page)]);
  } catch (err) {
    const errors = err.response?.data?.errors;
    const firstErr = errors ? Object.values(errors).flat()[0] : null;
    await showErrorAlert('Error', firstErr || err.response?.data?.message || 'No se pudo registrar el movimiento');
  } finally {
    saving.value = false;
  }
};

const openEmergencyModal = (a) => {
  emergencyItem.value = a;
  emergencyForm.new_driver_id = canManageFleet.value ? '' : String(currentUser.value?.id || '');
  emergencyForm.reassignment_reason = '';
  emergencyOpen.value = true;
};

const submitEmergency = async () => {
  if (saving.value || !emergencyItem.value) return;
  saving.value = true;
  try {
    const payload = {
      reassignment_reason: emergencyForm.reassignment_reason.trim(),
    };
    if (canManageFleet.value && emergencyForm.new_driver_id) {
      payload.new_driver_id = Number(emergencyForm.new_driver_id);
    }

    await window.axios.post(`/assignments/${emergencyItem.value.id}/emergency-reassign`, payload);
    emergencyOpen.value = false;
    await showSuccessAlert('Reasignación reportada');
    await loadAssignments(meta.value.current_page);
  } catch (err) {
    const errors = err.response?.data?.errors;
    const firstErr = errors ? Object.values(errors).flat()[0] : null;
    await showErrorAlert('Error', firstErr || err.response?.data?.message || 'No se pudo reasignar');
  } finally {
    saving.value = false;
  }
};

const confirmDelete = async (a) => {
  const r = await confirmDeleteDialog({
    title: '¿Eliminar asignación?',
    text: `${formatDate(a.scheduled_date)} · ${a.destination}`,
  });
  if (!r.isConfirmed) return;
  try {
    await window.axios.delete(`/assignments/${a.id}`);
    await showSuccessAlert('Eliminada');
    await loadAssignments(meta.value.current_page);
  } catch (err) {
    await showErrorAlert('Error', err.response?.data?.message || 'No se pudo eliminar');
  }
};

onMounted(async () => {
  await ensureMe();
  await Promise.all([loadVehicles(), loadDrivers(), loadAssignments(1)]);
});
</script>
