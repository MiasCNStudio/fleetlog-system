<template>
  <BaseModal
    :open="open"
    :title="modalTitle"
    :subtitle="modalSubtitle"
    max-width="2xl"
    @close="$emit('close')"
  >
    <div v-if="loading && !session" class="space-y-4">
      <div class="h-64 w-full animate-pulse rounded-xl bg-gray-100 dark:bg-gray-800" />
      <div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <div v-for="n in 4" :key="n" class="h-16 animate-pulse rounded-xl bg-gray-100 dark:bg-gray-800" />
      </div>
    </div>

    <div v-else-if="errorMsg" class="rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-theme-sm text-rose-700 dark:border-rose-500/30 dark:bg-rose-500/10 dark:text-rose-300">
      {{ errorMsg }}
    </div>

    <div v-else-if="session" class="space-y-5">
      <div
        v-if="session.has_sos_alert"
        class="flex flex-col gap-2 rounded-xl border border-rose-300 bg-rose-50 p-3.5 text-rose-800 dark:border-rose-500/40 dark:bg-rose-500/15 dark:text-rose-200 sm:flex-row sm:items-center sm:justify-between"
      >
        <div class="space-y-0.5">
          <p class="text-theme-sm font-bold">Alerta SOS registrada en esta misión</p>
          <p class="text-theme-xs">
            Se recibió una señal de emergencia desde {{ session.device_name }} ({{ session.device_uuid }}).
          </p>
        </div>
        <a
          v-if="summary?.google_maps_last_url"
          :href="summary.google_maps_last_url"
          target="_blank"
          rel="noopener noreferrer"
          class="inline-flex h-9 shrink-0 items-center justify-center rounded-lg bg-rose-600 px-3.5 text-theme-xs font-semibold text-white hover:bg-rose-700"
        >
          Ver punto SOS en Maps ↗
        </a>
      </div>

      <!-- Mapa del recorrido -->
      <div class="overflow-hidden rounded-xl border border-gray-200 dark:border-white/10">
        <div class="flex flex-wrap items-center justify-between gap-2 border-b border-gray-100 bg-gray-50/80 px-3.5 py-2 text-[11px] text-gray-600 dark:border-white/[0.06] dark:bg-white/[0.02] dark:text-gray-300">
          <div class="flex flex-wrap items-center gap-3">
            <span class="inline-flex items-center gap-1"><span class="size-2.5 rounded-full bg-emerald-500" /> Inicio</span>
            <span class="inline-flex items-center gap-1"><span class="size-2.5 rounded-full bg-brand-500" /> Última / Fin</span>
            <span class="inline-flex items-center gap-1"><span class="size-2.5 rounded-full bg-amber-500" /> Paradas</span>
            <span v-if="session.has_sos_alert" class="inline-flex items-center gap-1"><span class="size-2.5 rounded-full bg-rose-600" /> SOS</span>
          </div>
          <span class="font-semibold uppercase tracking-wide text-brand-600 dark:text-brand-400">
            {{ usingGoogle ? 'Google Maps' : 'Mapa interactivo' }}
          </span>
        </div>

        <div v-if="points.length > 0" ref="mapEl" class="h-72 w-full bg-slate-100 dark:bg-slate-900 sm:h-80" />
        <div
          v-else
          class="flex h-48 flex-col items-center justify-center gap-1.5 bg-gray-50 px-4 text-center text-theme-xs text-gray-500 dark:bg-white/[0.02] dark:text-gray-400"
        >
          <p class="font-medium text-gray-700 dark:text-gray-200">Sin coordenadas GPS registradas todavía</p>
          <p>En cuanto el celular asignado envíe su primera ubicación, el recorrido aparecerá aquí.</p>
        </div>
      </div>

      <!-- Botones directos a Google Maps -->
      <div v-if="summary?.google_maps_route_url || summary?.google_maps_last_url" class="flex flex-wrap items-center gap-2">
        <a
          v-if="summary?.google_maps_route_url"
          :href="summary.google_maps_route_url"
          target="_blank"
          rel="noopener noreferrer"
          class="fleet-btn-primary h-9 px-3.5 py-1.5 text-theme-xs"
        >
          Abrir recorrido en Google Maps ↗
        </a>
        <a
          v-if="summary?.google_maps_last_url"
          :href="summary.google_maps_last_url"
          target="_blank"
          rel="noopener noreferrer"
          class="fleet-btn-secondary h-9 px-3.5 py-1.5 text-theme-xs"
        >
          Última ubicación en Maps ↗
        </a>
        <button
          v-if="session.status === 'activa'"
          type="button"
          class="fleet-btn-secondary h-9 px-3.5 py-1.5 text-theme-xs"
          :disabled="loading"
          @click="loadSession"
        >
          Actualizar ahora
        </button>
      </div>

      <!-- Tarjeta de identificación de celular y cuenta -->
      <div class="grid grid-cols-1 gap-3 rounded-xl border border-gray-200 bg-gray-50/70 p-4 dark:border-white/[0.08] dark:bg-white/[0.02] sm:grid-cols-2 lg:grid-cols-3">
        <div>
          <p class="text-[11px] font-semibold uppercase tracking-wide text-gray-400">Conductor y cuenta</p>
          <p class="mt-0.5 text-theme-sm font-semibold text-gray-900 dark:text-white">{{ session.driver?.name || '—' }}</p>
          <p class="text-theme-xs text-gray-500 dark:text-gray-400">Inició: {{ session.started_by_user?.name || '—' }}</p>
        </div>
        <div>
          <p class="text-[11px] font-semibold uppercase tracking-wide text-gray-400">Celular exclusivo rastreado</p>
          <p class="mt-0.5 text-theme-sm font-semibold text-gray-900 dark:text-white">{{ session.device_name }}</p>
          <p class="truncate font-mono text-[11px] text-gray-500 dark:text-gray-400" :title="session.device_uuid">
            ID: {{ session.device_uuid }}
          </p>
        </div>
        <div>
          <p class="text-[11px] font-semibold uppercase tracking-wide text-gray-400">Estado y último reporte</p>
          <div class="mt-1 flex flex-wrap items-center gap-2">
            <StatusBadge kind="trackingStatus" :value="session.status" />
            <span v-if="session.last_battery_level !== null && session.last_battery_level !== undefined" class="text-theme-xs font-medium text-gray-600 dark:text-gray-300">
              Batería {{ session.last_battery_level }}%
            </span>
          </div>
          <p class="mt-0.5 text-theme-xs text-gray-500 dark:text-gray-400">
            {{ session.last_ping_at ? formatDateTime(session.last_ping_at) : 'Sin pings aún' }}
          </p>
        </div>
      </div>

      <!-- KPIs de recorrido -->
      <div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <div class="rounded-xl border border-gray-200 bg-white p-3 dark:border-white/[0.08] dark:bg-white/[0.02]">
          <p class="text-[11px] uppercase tracking-wide text-gray-400">Distancia GPS</p>
          <p class="mt-1 text-lg font-bold tabular-nums text-gray-900 dark:text-white">{{ formatNum(summary?.gps_distance_km ?? session.gps_distance_km) }} km</p>
          <p v-if="summary?.declared_distance_km !== null && summary?.declared_distance_km !== undefined" class="text-[11px] text-gray-500">
            Odómetro: {{ summary.declared_distance_km }} km
          </p>
        </div>
        <div class="rounded-xl border border-gray-200 bg-white p-3 dark:border-white/[0.08] dark:bg-white/[0.02]">
          <p class="text-[11px] uppercase tracking-wide text-gray-400">Duración</p>
          <p class="mt-1 text-lg font-bold tabular-nums text-gray-900 dark:text-white">{{ formatDuration(summary?.duration_minutes ?? 0) }}</p>
          <p class="text-[11px] text-gray-500">{{ summary?.points_count ?? session.points_count }} puntos</p>
        </div>
        <div class="rounded-xl border border-gray-200 bg-white p-3 dark:border-white/[0.08] dark:bg-white/[0.02]">
          <p class="text-[11px] uppercase tracking-wide text-gray-400">Velocidad</p>
          <p class="mt-1 text-lg font-bold tabular-nums text-gray-900 dark:text-white">{{ formatNum(summary?.max_speed_kmh ?? session.max_speed_kmh) }} km/h</p>
          <p class="text-[11px] text-gray-500">Prom: {{ formatNum(summary?.avg_speed_kmh ?? 0) }} km/h</p>
        </div>
        <div class="rounded-xl border border-gray-200 bg-white p-3 dark:border-white/[0.08] dark:bg-white/[0.02]">
          <p class="text-[11px] uppercase tracking-wide text-gray-400">Paradas (≥3 min)</p>
          <p class="mt-1 text-lg font-bold tabular-nums text-gray-900 dark:text-white">{{ summary?.stops?.length ?? session.stops_count ?? 0 }}</p>
          <p class="text-[11px] text-gray-500">Detenciones en ruta</p>
        </div>
      </div>

      <!-- Cronología detallada -->
      <div class="rounded-xl border border-gray-200 bg-white p-4 dark:border-white/[0.08] dark:bg-white/[0.02]">
        <h3 class="text-theme-sm font-semibold text-gray-900 dark:text-white">Resumen cronológico de la misión</h3>
        <div v-if="!summary?.timeline?.length" class="mt-2 text-theme-xs text-gray-500 dark:text-gray-400">
          Sin eventos registrados.
        </div>
        <ol v-else class="mt-3 space-y-3 border-l-2 border-gray-200 pl-4 dark:border-gray-700">
          <li v-for="(ev, idx) in summary.timeline" :key="idx" class="relative">
            <span
              class="absolute -left-[21px] top-1.5 size-2.5 rounded-full ring-4 ring-white dark:ring-gray-900"
              :class="timelineDotClass(ev.type)"
            />
            <div class="flex flex-wrap items-baseline justify-between gap-2">
              <p class="text-theme-xs font-semibold text-gray-900 dark:text-white">{{ ev.title }}</p>
              <span class="font-mono text-[11px] text-gray-400">{{ formatDateTime(ev.at) }}</span>
            </div>
            <p v-if="ev.detail" class="mt-0.5 text-theme-xs text-gray-600 dark:text-gray-300">{{ ev.detail }}</p>
          </li>
        </ol>
      </div>
    </div>

    <template #footer>
      <button type="button" class="fleet-btn-secondary" @click="$emit('close')">Cerrar</button>
    </template>
  </BaseModal>
</template>

<script setup>
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue';
import BaseModal from './BaseModal.vue';
import StatusBadge from './StatusBadge.vue';

const props = defineProps({
  open: { type: Boolean, default: false },
  sessionId: { type: [Number, String, null], default: null },
});

defineEmits(['close']);

const loading = ref(false);
const errorMsg = ref('');
const session = ref(null);
const points = ref([]);
const summary = ref(null);
const usingGoogle = ref(false);
const mapEl = ref(null);

let leafletMap = null;
let googleMap = null;
let googleOverlays = [];
let refreshTimer = null;

const modalTitle = computed(() => {
  if (!session.value) return 'Resumen de misión y rastreo GPS';
  const plate = session.value.vehicle?.license_plate || 'Unidad';
  const dest = session.value.salida_bitacora?.destination || 'Misión';
  return `Ruta ${plate} · ${dest}`;
});

const modalSubtitle = computed(() => {
  if (!session.value) return 'Recorrido exacto, dispositivo vinculado y cronología de eventos.';
  return `Iniciada ${formatDateTime(session.value.started_at)}${session.value.ended_at ? ` · Finalizada ${formatDateTime(session.value.ended_at)}` : ' · Misión en curso'}`;
});

const formatDateTime = (val) => {
  if (!val) return '—';
  const d = new Date(val);
  return Number.isNaN(d.getTime())
    ? String(val)
    : d.toLocaleString('es-SV', { dateStyle: 'short', timeStyle: 'short' });
};

const formatNum = (val) => Number(val || 0).toFixed(1);

const formatDuration = (mins) => {
  const m = Number(mins || 0);
  if (m < 60) return `${m} min`;
  const h = Math.floor(m / 60);
  const rem = m % 60;
  return `${h} h ${rem} min`;
};

const timelineDotClass = (type) => {
  if (type === 'salida') return 'bg-emerald-500';
  if (type === 'regreso') return 'bg-brand-500';
  if (type === 'stop') return 'bg-amber-500';
  if (type === 'sos' || type === 'incident' || type === 'emergency') return 'bg-rose-500';
  return 'bg-gray-400';
};

const destroyMaps = () => {
  if (leafletMap) {
    leafletMap.remove();
    leafletMap = null;
  }
  if (googleOverlays.length > 0) {
    googleOverlays.forEach((o) => o?.setMap?.(null));
    googleOverlays = [];
  }
  googleMap = null;
};

const loadGoogleMapsScript = (apiKey) =>
  new Promise((resolve, reject) => {
    if (window.google?.maps) {
      resolve(window.google);
      return;
    }
    const existing = document.getElementById('fleetlog-gmaps-script');
    if (existing) {
      existing.addEventListener('load', () => resolve(window.google));
      existing.addEventListener('error', reject);
      return;
    }
    const script = document.createElement('script');
    script.id = 'fleetlog-gmaps-script';
    script.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(apiKey)}&libraries=places&language=es`;
    script.async = true;
    script.defer = true;
    script.onload = () => resolve(window.google);
    script.onerror = reject;
    document.head.appendChild(script);
  });

const makeDotIcon = (color, label = '') =>
  L.divIcon({
    className: 'fleetlog-route-pin',
    html: `<div style="min-width:24px;height:24px;padding:0 5px;border-radius:9999px;background:${color};border:2.5px solid #ffffff;box-shadow:0 3px 10px rgba(15,23,42,0.35);color:#fff;font-size:11px;font-weight:700;display:flex;align-items:center;justify-content:center;">${label}</div>`,
    iconSize: [24, 24],
    iconAnchor: [12, 12],
  });

const renderMap = async () => {
  await nextTick();
  if (!mapEl.value || points.value.length === 0) return;

  destroyMaps();

  const latLngs = points.value.map((p) => [Number(p.latitude), Number(p.longitude)]);
  const first = points.value[0];
  const last = points.value[points.value.length - 1];
  const stops = summary.value?.stops || [];
  const sosPoints = points.value.filter((p) => p.source === 'sos');

  const envGoogleKey = String(import.meta.env.VITE_GOOGLE_MAPS_API_KEY || '').trim();
  if (envGoogleKey) {
    try {
      const g = await loadGoogleMapsScript(envGoogleKey);
      if (!mapEl.value) return;
      usingGoogle.value = true;
      const gPath = points.value.map((p) => ({ lat: Number(p.latitude), lng: Number(p.longitude) }));
      googleMap = new g.maps.Map(mapEl.value, {
        center: gPath[0],
        zoom: 14,
        mapTypeControl: true,
        streetViewControl: false,
      });

      const line = new g.maps.Polyline({
        path: gPath,
        geodesic: true,
        strokeColor: '#465fff',
        strokeOpacity: 0.9,
        strokeWeight: 4,
        map: googleMap,
      });
      googleOverlays.push(line);

      const bounds = new g.maps.LatLngBounds();
      gPath.forEach((pt) => bounds.extend(pt));

      googleOverlays.push(
        new g.maps.Marker({
          position: gPath[0],
          map: googleMap,
          label: 'I',
          title: `Inicio: ${formatDateTime(first.recorded_at)}`,
        }),
      );
      googleOverlays.push(
        new g.maps.Marker({
          position: gPath[gPath.length - 1],
          map: googleMap,
          label: session.value?.status === 'activa' ? 'A' : 'F',
          title: `${session.value?.status === 'activa' ? 'Última posición' : 'Fin'}: ${formatDateTime(last.recorded_at)}`,
        }),
      );

      stops.forEach((st, idx) => {
        const pos = { lat: Number(st.latitude), lng: Number(st.longitude) };
        bounds.extend(pos);
        googleOverlays.push(
          new g.maps.Marker({
            position: pos,
            map: googleMap,
            label: `${idx + 1}`,
            title: `Parada #${idx + 1} (${st.duration_minutes} min)`,
          }),
        );
      });

      sosPoints.forEach((sp) => {
        const pos = { lat: Number(sp.latitude), lng: Number(sp.longitude) };
        bounds.extend(pos);
        googleOverlays.push(
          new g.maps.Marker({
            position: pos,
            map: googleMap,
            label: '!',
            title: `SOS: ${formatDateTime(sp.recorded_at)}`,
          }),
        );
      });

      if (gPath.length > 1) {
        googleMap.fitBounds(bounds, 40);
      }
      return;
    } catch (_) {
      usingGoogle.value = false;
    }
  }

  leafletMap = L.map(mapEl.value, {
    center: latLngs[0],
    zoom: 14,
  });

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap',
    maxZoom: 19,
  }).addTo(leafletMap);

  const polyline = L.polyline(latLngs, { color: '#465fff', weight: 4, opacity: 0.9 }).addTo(leafletMap);

  L.marker([first.latitude, first.longitude], { icon: makeDotIcon('#10b981', 'I') })
    .bindPopup(`<strong>Inicio</strong><br>${formatDateTime(first.recorded_at)}`)
    .addTo(leafletMap);

  L.marker([last.latitude, last.longitude], {
    icon: makeDotIcon(session.value?.status === 'activa' ? '#465fff' : '#0f172a', session.value?.status === 'activa' ? '•' : 'F'),
  })
    .bindPopup(`<strong>${session.value?.status === 'activa' ? 'Última posición' : 'Fin'}</strong><br>${formatDateTime(last.recorded_at)}`)
    .addTo(leafletMap);

  stops.forEach((st, idx) => {
    L.marker([st.latitude, st.longitude], { icon: makeDotIcon('#f59e0b', `${idx + 1}`) })
      .bindPopup(`<strong>Parada #${idx + 1} (${st.duration_minutes} min)</strong><br>${formatDateTime(st.started_at)}`)
      .addTo(leafletMap);
  });

  sosPoints.forEach((sp) => {
    L.marker([sp.latitude, sp.longitude], { icon: makeDotIcon('#e11d48', 'SOS') })
      .bindPopup(`<strong>Alerta SOS</strong><br>${formatDateTime(sp.recorded_at)}`)
      .addTo(leafletMap);
  });

  if (latLngs.length > 1) {
    leafletMap.fitBounds(polyline.getBounds(), { padding: [28, 28] });
  }

  setTimeout(() => leafletMap?.invalidateSize(), 180);
};

const loadSession = async () => {
  if (!props.sessionId) return;
  loading.value = true;
  errorMsg.value = '';
  try {
    const { data } = await window.axios.get(`/tracking/sessions/${props.sessionId}`);
    session.value = data.session;
    points.value = data.points || [];
    summary.value = data.summary || null;
    await renderMap();
  } catch (err) {
    errorMsg.value = err.response?.data?.message || 'No se pudo cargar el recorrido de la misión.';
  } finally {
    loading.value = false;
  }
};

const stopAutoRefresh = () => {
  if (refreshTimer) {
    clearInterval(refreshTimer);
    refreshTimer = null;
  }
};

watch(
  () => [props.open, props.sessionId],
  async ([isOpen, id]) => {
    stopAutoRefresh();
    if (isOpen && id) {
      await loadSession();
      refreshTimer = setInterval(() => {
        if (props.open && session.value?.status === 'activa') {
          loadSession();
        }
      }, 12000);
    } else if (!isOpen) {
      destroyMaps();
      session.value = null;
      points.value = [];
      summary.value = null;
      errorMsg.value = '';
    }
  },
  { immediate: true },
);

onBeforeUnmount(() => {
  stopAutoRefresh();
  destroyMaps();
});
</script>
