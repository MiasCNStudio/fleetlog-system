<template>
  <AdminLayout header-title="Dashboard" :user-name="currentUser?.name" @logout="logout(true)">
    <!-- DEDICATED MOTORISTA DASHBOARD -->
    <template v-if="isMotorista">
      <PageBreadcrumb
        page-title="Mi panel de conductor"
        subtitle="Tus viajes asignados, unidades disponibles y acceso rápido a ruta."
      >
        <template #actions>
          <router-link to="/asignaciones" class="fleet-btn-primary">
            Ver asignaciones
          </router-link>
        </template>
      </PageBreadcrumb>

      <section class="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <article class="fleet-card relative overflow-hidden p-5">
          <span class="absolute inset-x-0 top-0 h-[3px] bg-gradient-to-r from-emerald-500/80 to-emerald-400/20" aria-hidden="true" />
          <p class="text-theme-sm font-medium text-gray-500 dark:text-gray-400">Unidades libres</p>
          <p class="mt-2 text-3xl font-bold tabular-nums text-gray-900 dark:text-white">
            {{ summary.unidades_disponibles ?? 0 }}
          </p>
          <p class="mt-1.5 text-theme-xs text-gray-500 dark:text-gray-400">
            Flota total: {{ formatUnits(summary.total_vehiculos ?? 0) }}
          </p>
        </article>

        <article class="fleet-card relative overflow-hidden p-5">
          <span class="absolute inset-x-0 top-0 h-[3px] bg-gradient-to-r from-brand-500/80 to-brand-400/20" aria-hidden="true" />
          <p class="text-theme-sm font-medium text-gray-500 dark:text-gray-400">Mis viajes pendientes</p>
          <p class="mt-2 text-3xl font-bold tabular-nums text-gray-900 dark:text-white">
            {{ myPendingAssignments.length }}
          </p>
          <p class="mt-1.5 text-theme-xs text-gray-500 dark:text-gray-400">
            Listos para iniciar desde Asignaciones
          </p>
        </article>

        <article class="fleet-card relative overflow-hidden p-5">
          <span class="absolute inset-x-0 top-0 h-[3px] bg-gradient-to-r from-amber-500/80 to-amber-400/20" aria-hidden="true" />
          <p class="text-theme-sm font-medium text-gray-500 dark:text-gray-400">Estado actual</p>
          <p class="mt-2 text-xl font-bold text-gray-900 dark:text-white">
            {{ myActiveTrip ? myActiveTrip.license_plate : 'En base' }}
          </p>
          <p class="mt-1.5 truncate text-theme-xs text-gray-500 dark:text-gray-400">
            {{ myActiveTrip ? `En ruta hacia ${myActiveTrip.destination || 'destino'}` : 'Sin viaje en curso' }}
          </p>
        </article>
      </section>

      <!-- Active trip banner for driver -->
      <section
        v-if="myActiveTrip"
        class="mt-5 rounded-2xl border border-amber-300/80 bg-amber-50/90 p-5 dark:border-amber-500/30 dark:bg-amber-500/10"
      >
        <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <span class="inline-flex rounded-full bg-amber-500/20 px-2.5 py-0.5 text-[11px] font-bold uppercase tracking-wider text-amber-900 dark:text-amber-200">
              Viaje en curso
            </span>
            <h2 class="mt-1.5 text-lg font-bold text-gray-900 dark:text-white">
              {{ myActiveTrip.license_plate }} · {{ myActiveTrip.brand }} {{ myActiveTrip.model }}
            </h2>
            <p class="text-theme-sm text-gray-700 dark:text-gray-200">
              Destino: {{ myActiveTrip.destination || '—' }}
            </p>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <a
              v-if="myActiveTrip.destination || myActiveTrip.latitude"
              :href="googleMapsUrl({ destination: myActiveTrip.destination, destinationAddress: myActiveTrip.destination_address, latitude: myActiveTrip.latitude, longitude: myActiveTrip.longitude })"
              target="_blank"
              rel="noopener noreferrer"
              class="fleet-btn-secondary h-9 px-3.5 py-1.5 text-theme-xs"
            >
              Google Maps ↗
            </a>
            <a
              v-if="myActiveTrip.destination || myActiveTrip.latitude"
              :href="wazeUrl({ destination: myActiveTrip.destination, destinationAddress: myActiveTrip.destination_address, latitude: myActiveTrip.latitude, longitude: myActiveTrip.longitude })"
              target="_blank"
              rel="noopener noreferrer"
              class="fleet-btn-secondary h-9 px-3.5 py-1.5 text-theme-xs"
            >
              Waze ↗
            </a>
            <router-link to="/bitacora" class="fleet-btn-primary h-9 px-4 py-1.5 text-theme-xs">
              Registrar regreso
            </router-link>
          </div>
        </div>
      </section>

      <section class="mt-5 grid grid-cols-1 gap-5 lg:grid-cols-3">
        <div class="fleet-card flex flex-col lg:col-span-2">
          <div class="flex items-center justify-between gap-3 border-b border-gray-100 px-5 py-4 dark:border-white/[0.07] sm:px-6">
            <div>
              <h2 class="text-base font-semibold text-gray-900 dark:text-white">
                Mis viajes asignados
              </h2>
              <p class="text-theme-xs text-gray-500 dark:text-gray-400">
                Agenda asignada para iniciar o tomar en cuenta instrucciones oficiales.
              </p>
            </div>
            <router-link to="/asignaciones" class="text-theme-xs font-semibold text-brand-600 hover:underline dark:text-brand-400">
              Ver todo →
            </router-link>
          </div>

          <div v-if="loading" class="space-y-3 p-5">
            <div v-for="i in 3" :key="i" class="h-16 animate-pulse rounded-xl bg-gray-100 dark:bg-gray-800/70" />
          </div>

          <div v-else-if="myAssignments.length === 0" class="px-6 py-10 text-center">
            <p class="text-theme-sm font-semibold text-gray-800 dark:text-gray-200">
              No tienes asignaciones activas
            </p>
            <p class="mt-1 text-theme-xs text-gray-500 dark:text-gray-400">
              Si necesitas cubrir una ruta de emergencia o registrar un viaje personal, usa los accesos rápidos.
            </p>
          </div>

          <ul v-else class="divide-y divide-gray-100 dark:divide-white/[0.06]">
            <li
              v-for="a in myAssignments"
              :key="a.id"
              class="flex flex-col gap-3 px-5 py-4 sm:flex-row sm:items-center sm:justify-between sm:px-6"
            >
              <div class="min-w-0 space-y-1">
                <div class="flex flex-wrap items-center gap-2">
                  <span class="text-theme-xs font-semibold tabular-nums text-gray-500 dark:text-gray-400">
                    {{ formatDate(a.scheduled_date) }}{{ a.scheduled_time ? ` · ${a.scheduled_time}` : '' }}
                  </span>
                  <span class="rounded bg-gray-100 px-2 py-0.5 font-mono text-theme-xs font-semibold text-gray-900 dark:bg-gray-800 dark:text-white">
                    {{ a.vehicle?.license_plate }}
                  </span>
                  <StatusBadge kind="assignmentStatus" :value="a.status" />
                </div>
                <p class="text-theme-sm font-semibold text-gray-900 dark:text-white">{{ a.destination }}</p>
                <p
                  v-if="a.official_instruction"
                  class="rounded-lg bg-amber-50 px-2.5 py-1 text-theme-xs font-medium text-amber-900 dark:bg-amber-500/10 dark:text-amber-200"
                >
                  <strong>Instrucción oficial:</strong> {{ a.official_instruction }}
                </p>
              </div>

              <div class="flex shrink-0 items-center gap-2">
                <a
                  :href="googleMapsUrl({ destination: a.destination, destinationAddress: a.destination_address, latitude: a.latitude, longitude: a.longitude })"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="fleet-btn-secondary h-8 px-2.5 py-1 text-[11px]"
                >
                  Maps ↗
                </a>
                <a
                  :href="wazeUrl({ destination: a.destination, destinationAddress: a.destination_address, latitude: a.latitude, longitude: a.longitude })"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="fleet-btn-secondary h-8 px-2.5 py-1 text-[11px]"
                >
                  Waze ↗
                </a>
                <router-link to="/asignaciones" class="fleet-btn-primary h-8 px-3 py-1 text-theme-xs">
                  Abrir
                </router-link>
              </div>
            </li>
          </ul>
        </div>

        <div class="fleet-card flex flex-col justify-between p-5">
          <div>
            <h2 class="text-base font-semibold text-gray-900 dark:text-white">Acciones rápidas</h2>
            <p class="mt-1 text-theme-xs text-gray-500 dark:text-gray-400">
              Operación diaria de conductor
            </p>
          </div>
          <div class="mt-4 space-y-2.5">
            <router-link to="/asignaciones" class="fleet-btn-primary h-10 w-full justify-between px-3.5">
              <span>Mis asignaciones / Emergencias</span>
              <span>→</span>
            </router-link>
            <router-link to="/bitacora" class="fleet-btn-secondary h-10 w-full justify-between px-3.5">
              <span>Registrar salida Personal</span>
              <span>→</span>
            </router-link>
            <router-link to="/incidencias" class="fleet-btn-secondary h-10 w-full justify-between px-3.5">
              <span>Reportar incidencia</span>
              <span>→</span>
            </router-link>
          </div>
        </div>
      </section>
    </template>

    <!-- ADMIN & JEFE DE MOTORISTAS DASHBOARD -->
    <template v-else>
      <PageBreadcrumb page-title="Dashboard Fleetlog" subtitle="Resumen operativo en tiempo real de la flota">
        <template #actions>
          <router-link to="/asignaciones" class="fleet-btn-primary">
            <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
            </svg>
            Programar asignación
          </router-link>
        </template>
      </PageBreadcrumb>

      <div
        v-if="loadError"
        class="mb-6 flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-theme-sm text-rose-800 dark:border-rose-500/30 dark:bg-rose-500/10 dark:text-rose-200"
        role="alert"
      >
        <span>{{ loadError }}</span>
        <button type="button" class="fleet-btn-secondary h-8 px-3 py-1 text-theme-xs" @click="loadData">
          Reintentar
        </button>
      </div>

      <div
        v-if="maintenanceAlerts.length > 0"
        class="mb-5 grid grid-cols-1 gap-3 md:grid-cols-2"
      >
        <div
          v-for="v in maintenanceAlerts"
          :key="`mal-${v.id}`"
          :class="[
            'flex items-center justify-between gap-3 rounded-2xl border p-4',
            v.maintenance_status === 'vencido'
              ? 'border-rose-400 bg-rose-50 text-rose-950 dark:border-rose-500/50 dark:bg-rose-500/15 dark:text-rose-100'
              : 'border-amber-300 bg-amber-50 text-amber-950 dark:border-amber-500/40 dark:bg-amber-500/15 dark:text-amber-100',
          ]"
        >
          <div class="min-w-0">
            <p class="text-theme-xs font-extrabold uppercase tracking-wide">
              {{ v.maintenance_status === 'vencido' ? '¡Mantenimiento pasado!' : 'Mantenimiento próximo' }} · {{ v.license_plate }}
            </p>
            <p class="mt-0.5 text-theme-xs">
              {{
                v.km_to_maintenance <= 0
                  ? `Superó el límite por ${Math.abs(v.km_to_maintenance).toLocaleString()} km`
                  : `Faltan ${Number(v.km_to_maintenance).toLocaleString()} km`
              }}
            </p>
          </div>
          <router-link to="/mantenimiento" class="fleet-btn-secondary h-8 shrink-0 px-3 py-1 text-theme-xs">
            Ver
          </router-link>
        </div>
      </div>

      <section
        aria-label="Indicadores clave de la flota"
        class="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-3 xl:grid-cols-5"
      >
        <template v-if="loading && cards.length === 0">
          <div
            v-for="idx in 5"
            :key="idx"
            :class="['fleet-card animate-pulse p-4 sm:p-5', idx === 5 ? 'col-span-2 sm:col-span-1' : '']"
          >
            <div class="flex items-center justify-between">
              <div class="h-4 w-24 rounded bg-gray-200 dark:bg-gray-800" />
              <div class="size-9 rounded-xl bg-gray-200 dark:bg-gray-800" />
            </div>
            <div class="mt-4 h-8 w-14 rounded bg-gray-200 dark:bg-gray-800" />
            <div class="mt-2 h-3 w-24 rounded bg-gray-100 dark:bg-gray-800/70" />
          </div>
        </template>

        <article
          v-for="(card, idx) in cards"
          v-else
          :key="card.key"
          :class="[
            'fleet-card relative flex flex-col justify-between overflow-hidden p-4 transition-all duration-200 hover:-translate-y-0.5 hover:shadow-theme-md sm:p-5',
            idx === 4 ? 'col-span-2 sm:col-span-1' : '',
          ]"
        >
          <span :class="['absolute inset-x-0 top-0 h-[3px]', card.accentBar]" aria-hidden="true" />

          <div class="flex items-start justify-between gap-2.5">
            <p class="min-h-[2.25rem] text-theme-xs font-semibold leading-snug text-gray-500 dark:text-gray-400 sm:text-theme-sm">
              {{ card.label }}
            </p>
            <span
              class="flex size-9 shrink-0 items-center justify-center rounded-xl ring-1 ring-inset sm:size-10"
              :class="card.iconWrap"
              aria-hidden="true"
            >
              <component :is="card.icon" class="size-[1.125rem] sm:size-5" />
            </span>
          </div>

          <div class="mt-2.5">
            <p class="text-[28px] font-bold leading-none tracking-tight tabular-nums text-gray-900 dark:text-white sm:text-[32px]">
              {{ card.value }}
            </p>
            <p class="mt-2 flex items-center gap-1.5 text-theme-xs text-gray-500 dark:text-gray-400">
              <span :class="['size-1.5 shrink-0 rounded-full', card.dotClass]" aria-hidden="true" />
              <span class="truncate">{{ card.hint }}</span>
            </p>
          </div>
        </article>
      </section>

      <section class="mt-5 grid grid-cols-1 gap-5 lg:grid-cols-3">
        <div class="fleet-card flex flex-col p-5 sm:p-6 lg:col-span-2">
          <div class="mb-3 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <h2 class="text-base font-semibold text-gray-900 dark:text-white">
                Movimientos de flota
              </h2>
              <p class="mt-0.5 text-theme-xs text-gray-500 dark:text-gray-400">
                Comparativa diaria de salidas y regresos registrados
              </p>
            </div>

            <div
              class="inline-flex self-start rounded-xl border border-gray-200 bg-gray-50 p-1 dark:border-white/10 dark:bg-[#0b1220] sm:self-auto"
              role="group"
              aria-label="Rango de días"
            >
              <button
                v-for="opt in [7, 30]"
                :key="opt"
                type="button"
                :aria-pressed="daysFilter === opt"
                :class="[
                  'rounded-lg px-3 py-1.5 text-theme-xs font-semibold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/40',
                  daysFilter === opt
                    ? 'bg-white text-gray-900 shadow-theme-xs dark:bg-[#1e293b] dark:text-white'
                    : 'text-gray-500 hover:text-gray-800 dark:text-gray-400 dark:hover:text-gray-200',
                ]"
                @click="setDaysFilter(opt)"
              >
                {{ opt }} días
              </button>
            </div>
          </div>

          <div class="mb-4 flex flex-wrap items-center justify-between gap-3 border-b border-gray-100 pb-3 text-theme-xs dark:border-white/[0.07]">
            <div class="flex flex-wrap items-center gap-4">
              <div class="flex items-center gap-2">
                <span class="size-2.5 rounded-full bg-brand-500" aria-hidden="true" />
                <span class="text-gray-500 dark:text-gray-400">Salidas:</span>
                <span class="font-semibold tabular-nums text-gray-900 dark:text-white">{{ periodTotals.salidas }}</span>
              </div>
              <div class="flex items-center gap-2">
                <span class="size-2.5 rounded-full bg-success-500" aria-hidden="true" />
                <span class="text-gray-500 dark:text-gray-400">Regresos:</span>
                <span class="font-semibold tabular-nums text-gray-900 dark:text-white">{{ periodTotals.regresos }}</span>
              </div>
            </div>
            <span class="rounded-md bg-gray-100 px-2 py-0.5 text-[11px] font-medium tabular-nums text-gray-600 dark:bg-white/[0.06] dark:text-gray-300">
              Total período: {{ periodTotals.salidas + periodTotals.regresos }}
            </span>
          </div>

          <div class="relative min-h-[270px] flex-1">
            <div
              ref="chartEl"
              class="h-[270px] w-full"
              :class="{ invisible: loading || isChartEmpty }"
            />

            <div
              v-if="loading"
              class="absolute inset-0 flex flex-col items-center justify-center rounded-xl bg-gray-50/70 dark:bg-[#0b1220]/70"
            >
              <div class="size-7 animate-spin rounded-full border-2 border-brand-500 border-t-transparent" />
              <p class="mt-2.5 text-theme-xs font-medium text-gray-500 dark:text-gray-400">
                Cargando actividad de flota…
              </p>
            </div>

            <div
              v-else-if="isChartEmpty"
              class="absolute inset-0 flex flex-col items-center justify-center rounded-xl border border-dashed border-gray-200/90 bg-gray-50/70 px-6 text-center dark:border-white/10 dark:bg-[#0b1220]/60"
            >
              <p class="text-theme-sm font-semibold text-gray-800 dark:text-gray-100">
                Sin movimientos en este período
              </p>
              <p class="mt-1 max-w-xs text-theme-xs text-gray-500 dark:text-gray-400">
                No se registraron salidas ni regresos en los últimos {{ daysFilter }} días.
              </p>
              <router-link to="/asignaciones" class="fleet-btn-secondary mt-4 h-9 px-3.5 py-1.5 text-theme-xs">
                Ir a Asignaciones
              </router-link>
            </div>
          </div>
        </div>

        <div class="fleet-card flex flex-col justify-between p-5">
          <div>
            <div class="flex flex-wrap items-center justify-between gap-2">
              <h2 class="text-base font-semibold text-gray-900 dark:text-white">
                Estado y control
              </h2>
              <span class="inline-flex shrink-0 items-center gap-1.5 whitespace-nowrap rounded-lg border border-gray-200/80 bg-gray-50 px-2.5 py-1 text-theme-xs font-medium tabular-nums text-gray-700 dark:border-white/10 dark:bg-white/[0.04] dark:text-gray-200">
                <span class="size-1.5 rounded-full bg-emerald-500" aria-hidden="true" />
                {{ nowLabel }}
              </span>
            </div>

            <div class="mt-3.5 rounded-xl border border-gray-200/70 bg-gray-50/80 p-3.5 dark:border-white/[0.07] dark:bg-white/[0.02]">
              <div class="flex items-center justify-between text-theme-xs">
                <span class="font-medium text-gray-600 dark:text-gray-300">Disponibilidad operativa</span>
                <span class="font-semibold tabular-nums text-gray-900 dark:text-white">
                  {{ formatUnits(summary.total_vehiculos ?? 0) }}
                </span>
              </div>

              <div class="mt-2.5 flex h-2 w-full overflow-hidden rounded-full bg-gray-200 dark:bg-gray-800">
                <div
                  v-if="fleetBreakdown.availablePct > 0"
                  class="bg-emerald-500 transition-all duration-300"
                  :style="{ width: `${fleetBreakdown.availablePct}%` }"
                />
                <div
                  v-if="fleetBreakdown.inRoutePct > 0"
                  class="bg-amber-500 transition-all duration-300"
                  :style="{ width: `${fleetBreakdown.inRoutePct}%` }"
                />
                <div
                  v-if="fleetBreakdown.maintenancePct > 0"
                  class="bg-rose-500 transition-all duration-300"
                  :style="{ width: `${fleetBreakdown.maintenancePct}%` }"
                />
              </div>

              <div class="mt-2.5 grid grid-cols-3 gap-2 text-[11px] font-medium">
                <div class="flex items-center gap-1.5 text-gray-600 dark:text-gray-300">
                  <span class="size-2 shrink-0 rounded-full bg-emerald-500" />
                  <span class="truncate">Disp: {{ summary.unidades_disponibles ?? 0 }}</span>
                </div>
                <div class="flex items-center gap-1.5 text-gray-600 dark:text-gray-300">
                  <span class="size-2 shrink-0 rounded-full bg-amber-500" />
                  <span class="truncate">Ruta: {{ summary.viajes_activos ?? 0 }}</span>
                </div>
                <div class="flex items-center gap-1.5 text-gray-600 dark:text-gray-300">
                  <span class="size-2 shrink-0 rounded-full bg-rose-500" />
                  <span class="truncate">Mant: {{ summary.unidades_mantenimiento ?? 0 }}</span>
                </div>
              </div>
            </div>

            <dl class="mt-3.5 space-y-2 rounded-xl border border-gray-100 px-3.5 py-2.5 text-theme-xs dark:border-white/[0.06]">
              <div class="flex items-center justify-between gap-3">
                <dt class="text-gray-500 dark:text-gray-400">Operador</dt>
                <dd class="truncate font-semibold text-gray-900 dark:text-white">{{ currentUser?.name || '—' }}</dd>
              </div>
              <div class="flex items-center justify-between gap-3">
                <dt class="text-gray-500 dark:text-gray-400">Rol de acceso</dt>
                <dd>
                  <StatusBadge kind="userRole" :value="currentUser?.role || 'motorista'" />
                </dd>
              </div>
            </dl>
          </div>

          <div class="mt-4 space-y-2">
            <router-link to="/asignaciones" class="fleet-btn-primary group h-10 w-full justify-between px-3.5">
              <span>Agenda y asignaciones</span>
              <span>→</span>
            </router-link>
            <router-link to="/rastreo" class="fleet-btn-secondary group h-10 w-full justify-between px-3.5">
              <span>Rastreo GPS en vivo</span>
              <span>→</span>
            </router-link>
            <router-link to="/bitacora-sistema" class="fleet-btn-secondary group h-10 w-full justify-between px-3.5">
              <span>Bitácora del sistema</span>
              <span>→</span>
            </router-link>
            <router-link to="/incidencias" class="fleet-btn-secondary group h-10 w-full justify-between px-3.5">
              <span>Reportar incidencia</span>
              <span>→</span>
            </router-link>
          </div>
        </div>
      </section>

      <section class="mt-5 grid grid-cols-1 gap-5 lg:grid-cols-2">
        <div class="fleet-card flex flex-col">
          <div class="flex items-center justify-between gap-3 border-b border-gray-100 px-5 py-4 dark:border-white/[0.07] sm:px-6">
            <div class="flex items-center gap-2.5">
              <h2 class="text-base font-semibold text-gray-900 dark:text-white">
                Unidades en ruta ahora
              </h2>
              <span class="rounded-full bg-amber-500/15 px-2.5 py-0.5 text-theme-xs font-semibold tabular-nums text-amber-800 dark:text-amber-300">
                {{ activeTrips.length }}
              </span>
            </div>
            <router-link to="/rastreo" class="text-theme-xs font-semibold text-brand-600 hover:underline dark:text-brand-400">
              Ver rastreo →
            </router-link>
          </div>

          <div v-if="loading && activeTrips.length === 0" class="space-y-3 p-5">
            <div v-for="i in 3" :key="i" class="h-16 animate-pulse rounded-xl bg-gray-100 dark:bg-gray-800/70" />
          </div>

          <div v-else-if="activeTrips.length === 0" class="px-6 py-10 text-center">
            <p class="text-theme-sm font-semibold text-gray-800 dark:text-gray-200">
              Todas las unidades están en base
            </p>
            <p class="mt-0.5 text-theme-xs text-gray-500 dark:text-gray-400">
              No hay salidas pendientes de regreso en este momento.
            </p>
          </div>

          <ul v-else class="divide-y divide-gray-100 dark:divide-white/[0.06]">
            <li
              v-for="t in activeTrips"
              :key="t.vehicle_id"
              class="flex flex-col gap-2.5 px-5 py-4 transition-colors hover:bg-gray-50/70 dark:hover:bg-white/[0.02] sm:flex-row sm:items-center sm:justify-between sm:px-6"
            >
              <div class="min-w-0 space-y-1">
                <div class="flex flex-wrap items-center gap-2">
                  <span class="rounded-md bg-gray-100 px-2 py-0.5 font-mono text-theme-xs font-semibold text-gray-900 dark:bg-white/10 dark:text-white">
                    {{ t.license_plate }}
                  </span>
                  <span class="text-theme-sm font-medium text-gray-800 dark:text-gray-200">
                    {{ t.brand }} {{ t.model }}
                  </span>
                </div>
                <p class="truncate text-theme-xs text-gray-500 dark:text-gray-400">
                  {{ t.driver_name || 'Sin asignar' }} · {{ t.destination || 'Destino sin especificar' }}
                </p>
              </div>

              <div class="flex shrink-0 flex-row items-center justify-between gap-3 sm:flex-col sm:items-end sm:gap-1">
                <div class="flex items-center gap-2">
                  <a
                    v-if="t.destination || t.latitude"
                    :href="googleMapsUrl({ destination: t.destination, destinationAddress: t.destination_address, latitude: t.latitude, longitude: t.longitude })"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="text-[11px] font-medium text-brand-600 hover:underline dark:text-brand-400"
                  >
                    Maps ↗
                  </a>
                  <a
                    v-if="t.destination || t.latitude"
                    :href="wazeUrl({ destination: t.destination, destinationAddress: t.destination_address, latitude: t.latitude, longitude: t.longitude })"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="text-[11px] font-medium text-sky-600 hover:underline dark:text-sky-400"
                  >
                    Waze ↗
                  </a>
                  <StatusBadge kind="vehicleStatus" value="en_ruta" />
                </div>
                <div class="flex items-center gap-2 text-[11px] tabular-nums text-gray-500 dark:text-gray-400">
                  <span v-if="t.recorded_at">{{ formatShortTime(t.recorded_at) }}</span>
                  <span v-if="t.odometer_km !== null && t.odometer_km !== undefined">
                    · {{ Number(t.odometer_km).toLocaleString() }} km
                  </span>
                </div>
              </div>
            </li>
          </ul>
        </div>

        <div class="fleet-card flex flex-col">
          <div class="flex items-center justify-between gap-3 border-b border-gray-100 px-5 py-4 dark:border-white/[0.07] sm:px-6">
            <div class="flex items-center gap-2.5">
              <h2 class="text-base font-semibold text-gray-900 dark:text-white">
                Incidencias abiertas recientes
              </h2>
              <span class="rounded-full bg-rose-500/15 px-2.5 py-0.5 text-theme-xs font-semibold tabular-nums text-rose-700 dark:text-rose-300">
                {{ summary.incidencias_abiertas ?? recentIncidents.length }}
              </span>
            </div>
            <router-link to="/incidencias" class="text-theme-xs font-semibold text-brand-600 hover:underline dark:text-brand-400">
              Ver todas →
            </router-link>
          </div>

          <div v-if="loading && recentIncidents.length === 0" class="space-y-3 p-5">
            <div v-for="i in 3" :key="i" class="h-16 animate-pulse rounded-xl bg-gray-100 dark:bg-gray-800/70" />
          </div>

          <div v-else-if="recentIncidents.length === 0" class="px-6 py-10 text-center">
            <p class="text-theme-sm font-semibold text-gray-800 dark:text-gray-200">
              Sin incidencias abiertas
            </p>
            <p class="mt-0.5 text-theme-xs text-gray-500 dark:text-gray-400">
              No hay novedades mecánicas o operativas pendientes de atención.
            </p>
          </div>

          <ul v-else class="divide-y divide-gray-100 dark:divide-white/[0.06]">
            <li
              v-for="inc in recentIncidents"
              :key="inc.id"
              class="flex flex-col gap-2.5 px-5 py-4 transition-colors hover:bg-gray-50/70 dark:hover:bg-white/[0.02] sm:flex-row sm:items-center sm:justify-between sm:px-6"
            >
              <div class="min-w-0 space-y-1">
                <p class="truncate text-theme-sm font-semibold text-gray-900 dark:text-white" :title="inc.title">
                  {{ inc.title }}
                </p>
                <div class="flex flex-wrap items-center gap-x-2.5 gap-y-1 text-theme-xs text-gray-500 dark:text-gray-400">
                  <span v-if="inc.vehicle?.license_plate" class="rounded bg-gray-100 px-1.5 py-0.5 font-mono text-[11px] font-semibold text-gray-800 dark:bg-white/10 dark:text-gray-200">
                    {{ inc.vehicle.license_plate }}
                  </span>
                  <span>Reportó: {{ inc.reporter?.name || '—' }}</span>
                  <span v-if="inc.reported_at" class="tabular-nums">· {{ formatShortTime(inc.reported_at) }}</span>
                </div>
              </div>

              <div class="flex shrink-0 items-center gap-2">
                <StatusBadge kind="incidentStatus" :value="inc.status" />
                <StatusBadge kind="incidentSeverity" :value="inc.severity" />
              </div>
            </li>
          </ul>
        </div>
      </section>
    </template>
  </AdminLayout>
</template>

<script setup>
import ApexCharts from 'apexcharts';
import { computed, h, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import { useDark, useNow } from '@vueuse/core';
import AdminLayout from '@/components/layout/AdminLayout.vue';
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue';
import StatusBadge from '@/components/common/StatusBadge.vue';
import { setCurrentUser, useAuth } from '../composables/useAuth';
import { googleMapsUrl, wazeUrl } from '../utils/maps';

const { currentUser, logout } = useAuth();

const isMotorista = computed(() => currentUser.value?.role === 'motorista');

const chartEl = ref(null);
const loading = ref(true);
const loadError = ref('');
const summary = ref({});
const seriesRaw = ref({ categories: [], salidas: [], regresos: [] });
const activeTrips = ref([]);
const recentIncidents = ref([]);
const maintenanceAlerts = ref([]);
const myAssignments = ref([]);
const myActiveTrip = ref(null);
const daysFilter = ref(7);

const now = useNow({ interval: 1000 });
const isDark = useDark();
const nowLabel = computed(() =>
  now.value.toLocaleTimeString('es-HN', { hour: '2-digit', minute: '2-digit', second: '2-digit' }),
);

let chartInstance = null;

const myPendingAssignments = computed(() =>
  myAssignments.value.filter((a) => a.status === 'pendiente'),
);

const formatUnits = (count) => {
  const n = Number(count ?? 0);
  return `${n} ${n === 1 ? 'unidad' : 'unidades'}`;
};

const formatDate = (dateStr) => {
  if (!dateStr) return '—';
  const clean = String(dateStr).slice(0, 10);
  const [y, m, d] = clean.split('-');
  return y && m && d ? `${d}/${m}/${y}` : dateStr;
};

const IconRoute = {
  render() {
    return h('svg', { fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', 'stroke-width': '1.8' }, [
      h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', d: 'M15 10.5a3 3 0 11-6 0 3 3 0 016 0z' }),
      h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', d: 'M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z' }),
    ]);
  },
};

const IconCheckTruck = {
  render() {
    return h('svg', { fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', 'stroke-width': '1.8' }, [
      h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', d: 'M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z' }),
    ]);
  },
};

const IconDriver = {
  render() {
    return h('svg', { fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', 'stroke-width': '1.8' }, [
      h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', d: 'M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0z' }),
    ]);
  },
};

const IconAlert = {
  render() {
    return h('svg', { fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', 'stroke-width': '1.8' }, [
      h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', d: 'M12 9v3.75m9.303 3.376c-.866 1.5.217 3.374 1.948 3.374H2.697c-1.73 0-2.813-1.874-1.948-3.374L10.051 3.378c.866-1.5 3.032-1.5 3.898 0l7.354 12.748zM12 15.75h.007v.008H12v-.008z' }),
    ]);
  },
};

const IconWrench = {
  render() {
    return h('svg', { fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor', 'stroke-width': '1.8' }, [
      h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', d: 'M11.42 15.17L17.25 21A2.652 2.652 0 0021 17.25l-5.877-5.877M11.42 15.17l2.496-3.03c.317-.384.74-.626 1.208-.766M11.42 15.17l-4.655 5.653a2.548 2.548 0 11-3.586-3.586l6.837-5.63m5.108-.233c.55-.164 1.163-.188 1.743-.14a4.5 4.5 0 004.486-6.336l-3.276 3.277a3.004 3.004 0 01-2.25-2.25l3.276-3.276a4.5 4.5 0 00-6.336 4.486c.091 1.076-.071 2.264-.904 2.95l-.102.085m-1.745 1.437L5.909 7.5H4.5L2.25 3.75l1.5-1.5L7.5 4.5v1.409l4.26 4.26m-1.745 1.437l1.745-1.437m6.615 8.206L15.75 15.75M4.867 19.125h.008v.008h-.008v-.008z' }),
    ]);
  },
};

const cards = computed(() => {
  const s = summary.value;
  if (!Object.keys(s).length) return [];

  const total = Number(s.total_vehiculos ?? 0);
  const avail = Number(s.unidades_disponibles ?? 0);
  const availPct = total > 0 ? Math.round((avail / total) * 100) : 0;
  const openInc = Number(s.incidencias_abiertas ?? 0);
  const maint = Number(s.unidades_mantenimiento ?? 0);

  return [
    {
      key: 'active',
      label: 'Viajes activos',
      value: s.viajes_activos ?? 0,
      hint: `Flota: ${formatUnits(total)}`,
      icon: IconRoute,
      accentBar: 'bg-gradient-to-r from-brand-500/80 to-brand-400/20',
      dotClass: 'bg-brand-500',
      iconWrap: 'bg-brand-50 text-brand-600 ring-brand-500/15 dark:bg-brand-500/15 dark:text-brand-300 dark:ring-brand-400/20',
    },
    {
      key: 'available',
      label: 'Unidades disponibles',
      value: avail,
      hint: total > 0 ? `${availPct}% lista para operar` : 'Sin unidades',
      icon: IconCheckTruck,
      accentBar: 'bg-gradient-to-r from-emerald-500/80 to-emerald-400/20',
      dotClass: 'bg-emerald-500',
      iconWrap: 'bg-emerald-500/10 text-emerald-600 ring-emerald-500/20 dark:bg-emerald-500/15 dark:text-emerald-300 dark:ring-emerald-400/20',
    },
    {
      key: 'drivers',
      label: 'Conductores en ruta',
      value: s.conductores_en_ruta ?? 0,
      hint: 'En salidas activas',
      icon: IconDriver,
      accentBar: 'bg-gradient-to-r from-sky-500/80 to-sky-400/20',
      dotClass: 'bg-sky-500',
      iconWrap: 'bg-sky-500/10 text-sky-600 ring-sky-500/20 dark:bg-sky-500/15 dark:text-sky-300 dark:ring-sky-400/20',
    },
    {
      key: 'incidents',
      label: 'Incidencias abiertas',
      value: openInc,
      hint: `Reportadas hoy: ${s.incidencias_hoy ?? 0}`,
      icon: IconAlert,
      accentBar: openInc > 0 ? 'bg-gradient-to-r from-rose-500/90 to-rose-400/20' : 'bg-gradient-to-r from-gray-300 to-gray-200 dark:from-gray-700 dark:to-gray-800',
      dotClass: openInc > 0 ? 'bg-rose-500' : 'bg-gray-400',
      iconWrap: 'bg-rose-500/10 text-rose-600 ring-rose-500/20 dark:bg-rose-500/15 dark:text-rose-300 dark:ring-rose-400/20',
    },
    {
      key: 'maintenance',
      label: 'En mantenimiento',
      value: maint,
      hint: maint > 0 ? 'Bloqueadas para salida' : 'Sin unidades en taller',
      icon: IconWrench,
      accentBar: maint > 0 ? 'bg-gradient-to-r from-amber-500/90 to-amber-400/20' : 'bg-gradient-to-r from-gray-300 to-gray-200 dark:from-gray-700 dark:to-gray-800',
      dotClass: maint > 0 ? 'bg-amber-500' : 'bg-gray-400',
      iconWrap: 'bg-amber-500/10 text-amber-600 ring-amber-500/20 dark:bg-amber-500/15 dark:text-amber-300 dark:ring-amber-400/20',
    },
  ];
});

const fleetBreakdown = computed(() => {
  const total = Number(summary.value.total_vehiculos ?? 0);
  if (total <= 0) {
    return { availablePct: 0, inRoutePct: 0, maintenancePct: 0 };
  }
  return {
    availablePct: (Number(summary.value.unidades_disponibles ?? 0) / total) * 100,
    inRoutePct: (Number(summary.value.viajes_activos ?? 0) / total) * 100,
    maintenancePct: (Number(summary.value.unidades_mantenimiento ?? 0) / total) * 100,
  };
});

const periodTotals = computed(() => {
  const salidas = (seriesRaw.value.salidas || []).reduce((acc, v) => acc + Number(v || 0), 0);
  const regresos = (seriesRaw.value.regresos || []).reduce((acc, v) => acc + Number(v || 0), 0);
  return { salidas, regresos };
});

const isChartEmpty = computed(
  () => !loading.value && periodTotals.value.salidas === 0 && periodTotals.value.regresos === 0,
);

const formatShortTime = (iso) => {
  if (!iso) return '';
  return new Date(iso).toLocaleString('es-HN', { dateStyle: 'short', timeStyle: 'short' });
};

const buildChartOptions = (seriesData) => {
  const dark = isDark.value;
  const textColor = dark ? '#94a3b8' : '#64748b';
  const gridColor = dark ? 'rgba(255, 255, 255, 0.07)' : '#f1f5f9';
  const categories = seriesData.categories || [];
  const salidas = seriesData.salidas || seriesData.values || [];
  const regresos = seriesData.regresos || [];

  return {
    chart: {
      type: 'bar',
      height: 270,
      fontFamily: 'Outfit, system-ui, sans-serif',
      toolbar: { show: false },
      background: 'transparent',
    },
    theme: { mode: dark ? 'dark' : 'light' },
    series: [
      { name: 'Salidas', data: salidas },
      { name: 'Regresos', data: regresos },
    ],
    colors: ['#465fff', '#12b76a'],
    plotOptions: {
      bar: {
        borderRadius: 6,
        borderRadiusApplication: 'end',
        columnWidth: daysFilter.value === 30 ? '68%' : '46%',
      },
    },
    dataLabels: { enabled: false },
    stroke: {
      show: true,
      width: 2,
      colors: ['transparent'],
    },
    grid: {
      borderColor: gridColor,
      strokeDashArray: 4,
      xaxis: { lines: { show: false } },
      yaxis: { lines: { show: true } },
    },
    xaxis: {
      categories,
      tickAmount: daysFilter.value === 30 ? 10 : undefined,
      axisBorder: { show: false },
      axisTicks: { show: false },
      labels: {
        style: { colors: textColor, fontSize: '12px' },
      },
    },
    yaxis: {
      min: 0,
      forceNiceScale: true,
      decimalsInFloat: 0,
      title: {
        text: 'Movimientos',
        style: { color: textColor, fontSize: '12px', fontWeight: 500 },
      },
      labels: {
        style: { colors: textColor, fontSize: '12px' },
        formatter: (val) => `${Math.round(val)}`,
      },
    },
    legend: {
      show: false,
    },
    tooltip: {
      shared: true,
      intersect: false,
      theme: dark ? 'dark' : 'light',
      y: {
        formatter: (val) => `${val} ${val === 1 ? 'registro' : 'registros'}`,
      },
    },
  };
};

const renderChart = (seriesData, animate = true) => {
  if (!chartEl.value || isMotorista.value) return;
  const options = buildChartOptions(seriesData);

  if (chartInstance) {
    chartInstance.updateOptions(options, false, animate);
  } else {
    chartInstance = new ApexCharts(chartEl.value, options);
    chartInstance.render();
  }
};

const loadData = async () => {
  loading.value = true;
  loadError.value = '';
  try {
    const { data } = await window.axios.get('/dashboard', { params: { days: daysFilter.value } });
    summary.value = data.summary || {};
    seriesRaw.value = {
      categories: data.series?.categories || [],
      salidas: data.series?.salidas || data.series?.values || [],
      regresos: data.series?.regresos || [],
    };
    activeTrips.value = data.active_trips || [];
    recentIncidents.value = data.recent_incidents || [];
    maintenanceAlerts.value = data.maintenance_alerts || [];
    myAssignments.value = data.my_assignments || [];
    myActiveTrip.value = data.my_active_trip || null;

    if (data.user) {
      setCurrentUser(data.user);
    }

    await nextTick();
    renderChart(seriesRaw.value);
  } catch (error) {
    loadError.value = error.response?.data?.message || 'No se pudo cargar la información del dashboard.';
  } finally {
    loading.value = false;
  }
};

const setDaysFilter = async (days) => {
  if (daysFilter.value === days) return;
  daysFilter.value = days;
  await loadData();
};

watch(isDark, () => {
  if (chartInstance && !loading.value && !isMotorista.value) {
    renderChart(seriesRaw.value, false);
  }
});

onMounted(async () => {
  await loadData();
});

onBeforeUnmount(() => {
  chartInstance?.destroy();
});
</script>
