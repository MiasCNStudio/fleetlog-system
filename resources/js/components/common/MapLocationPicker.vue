<template>
  <div class="space-y-3">
    <div>
      <label :for="searchInputId" class="fleet-field-label">
        {{ label }} <span v-if="required" class="text-rose-500">*</span>
      </label>

      <div class="relative flex gap-2">
        <div class="relative flex-1">
          <svg
            class="pointer-events-none absolute left-3.5 top-1/2 size-4 -translate-y-1/2 text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="1.8"
            aria-hidden="true"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" />
            <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z" />
          </svg>
          <input
            :id="searchInputId"
            ref="searchInputEl"
            v-model="searchText"
            type="text"
            class="fleet-input pl-10 pr-8"
            placeholder="Buscar lugar (ej. Centro Histórico de El Salvador)…"
            @keydown.enter.prevent="searchPlaces"
          />
          <button
            v-if="searchText"
            type="button"
            class="absolute right-2.5 top-1/2 -translate-y-1/2 rounded p-1 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"
            aria-label="Limpiar lugar"
            @click="clearSearch"
          >
            <svg class="size-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <button
          type="button"
          class="fleet-btn-secondary h-10 shrink-0 px-3.5 text-theme-xs"
          :disabled="searching"
          @click="searchPlaces"
        >
          {{ searching ? 'Buscando…' : 'Buscar' }}
        </button>
      </div>

      <div
        v-if="results.length > 0"
        class="mt-1.5 max-h-52 overflow-y-auto rounded-xl border border-gray-200 bg-white shadow-lg dark:border-white/10 dark:bg-[#0b1220]"
      >
        <button
          v-for="(item, idx) in results"
          :key="`${item.latitude}-${item.longitude}-${idx}`"
          type="button"
          class="flex w-full items-start gap-2.5 border-b border-gray-100 px-3.5 py-2.5 text-left transition-colors last:border-b-0 hover:bg-brand-50/60 dark:border-white/[0.06] dark:hover:bg-white/[0.05]"
          @click="selectPlace(item)"
        >
          <svg class="mt-0.5 size-4 shrink-0 text-brand-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" />
            <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z" />
          </svg>
          <div class="min-w-0">
            <p class="truncate text-theme-sm font-medium text-gray-900 dark:text-white">{{ item.name }}</p>
            <p class="truncate text-theme-xs text-gray-500 dark:text-gray-400">{{ item.address }}</p>
          </div>
        </button>
      </div>
      <p v-else-if="searchDone && results.length === 0" class="mt-1 text-theme-xs text-amber-600 dark:text-amber-400">
        No se encontraron coincidencias exactas. Puedes hacer clic directamente en el mapa para fijar el punto.
      </p>
    </div>

    <div>
      <label :for="destInputId" class="fleet-label">Nombre visible del destino</label>
      <input
        :id="destInputId"
        :value="destination"
        type="text"
        class="fleet-input"
        placeholder="Ej. Centro Histórico de El Salvador"
        :required="required"
        @input="$emit('update:destination', $event.target.value)"
      />
    </div>

    <div class="overflow-hidden rounded-xl border border-gray-200 dark:border-white/10">
      <div class="flex items-center justify-between border-b border-gray-100 bg-gray-50/80 px-3 py-2 text-[11px] text-gray-500 dark:border-white/[0.06] dark:bg-white/[0.02] dark:text-gray-400">
        <span>Haz clic en el mapa o arrastra el pin para elegir el punto exacto</span>
        <span class="font-semibold uppercase tracking-wide text-brand-600 dark:text-brand-400">
          {{ usingGoogle ? 'Google Maps' : 'Mapa interactivo' }}
        </span>
      </div>
      <div ref="mapContainerEl" class="h-56 w-full bg-slate-100 dark:bg-slate-900" />
    </div>

    <div
      v-if="hasCoords || destinationAddress"
      class="flex flex-col gap-2 rounded-xl border border-gray-200/80 bg-gray-50/80 p-3 text-theme-xs dark:border-white/[0.07] dark:bg-white/[0.02] sm:flex-row sm:items-center sm:justify-between"
    >
      <div class="min-w-0 space-y-0.5">
        <p v-if="destinationAddress" class="truncate font-medium text-gray-800 dark:text-gray-200" :title="destinationAddress">
          {{ destinationAddress }}
        </p>
        <p v-if="hasCoords" class="font-mono text-[11px] text-gray-500 dark:text-gray-400">
          Pin exacto: {{ formattedCoords }}
        </p>
      </div>

      <div class="flex shrink-0 items-center gap-2">
        <a
          v-if="gmapsHref"
          :href="gmapsHref"
          target="_blank"
          rel="noopener noreferrer"
          class="fleet-btn-secondary h-8 px-2.5 py-1 text-[11px]"
        >
          Google Maps ↗
        </a>
        <a
          v-if="wazeHref"
          :href="wazeHref"
          target="_blank"
          rel="noopener noreferrer"
          class="fleet-btn-secondary h-8 px-2.5 py-1 text-[11px]"
        >
          Waze ↗
        </a>
      </div>
    </div>
  </div>
</template>

<script setup>
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { computed, onBeforeUnmount, onMounted, ref, useId, watch } from 'vue';
import { formatCoordinates, googleMapsUrl, hasCoordinates, wazeUrl } from '@/utils/maps.js';

const props = defineProps({
  label: { type: String, default: 'Buscar y seleccionar destino en el mapa' },
  required: { type: Boolean, default: false },
  destination: { type: String, default: '' },
  destinationAddress: { type: String, default: '' },
  latitude: { type: [Number, String, null], default: null },
  longitude: { type: [Number, String, null], default: null },
  placeId: { type: String, default: '' },
});

const emit = defineEmits([
  'update:destination',
  'update:destinationAddress',
  'update:latitude',
  'update:longitude',
  'update:placeId',
]);

const searchInputId = useId();
const destInputId = useId();
const searchInputEl = ref(null);
const mapContainerEl = ref(null);
const searchText = ref(props.destination || '');
const searching = ref(false);
const searchDone = ref(false);
const results = ref([]);
const usingGoogle = ref(false);

const DEFAULT_LAT = 13.6978;
const DEFAULT_LNG = -89.1914;

let leafletMap = null;
let leafletMarker = null;
let googleMap = null;
let googleMarker = null;

const hasCoords = computed(() => hasCoordinates(props.latitude, props.longitude));
const formattedCoords = computed(() => formatCoordinates(props.latitude, props.longitude));

const gmapsHref = computed(() =>
  googleMapsUrl({
    destination: props.destination,
    destinationAddress: props.destinationAddress,
    latitude: props.latitude,
    longitude: props.longitude,
  }),
);

const wazeHref = computed(() =>
  wazeUrl({
    destination: props.destination,
    destinationAddress: props.destinationAddress,
    latitude: props.latitude,
    longitude: props.longitude,
  }),
);

const createLeafletPinIcon = () =>
  L.divIcon({
    className: 'fleetlog-map-pin',
    html: `<div style="width:28px;height:28px;border-radius:9999px;background:#465fff;border:3px solid #ffffff;box-shadow:0 4px 12px rgba(16,24,40,0.35);display:flex;align-items:center;justify-content:center;"><div style="width:8px;height:8px;border-radius:9999px;background:#ffffff;"></div></div>`,
    iconSize: [28, 28],
    iconAnchor: [14, 14],
  });

const setPinOnMap = (lat, lng, zoom = 16) => {
  const numLat = Number(lat);
  const numLng = Number(lng);
  if (Number.isNaN(numLat) || Number.isNaN(numLng)) return;

  if (usingGoogle.value && googleMap && googleMarker) {
    const pos = { lat: numLat, lng: numLng };
    googleMarker.setPosition(pos);
    googleMap.panTo(pos);
    googleMap.setZoom(zoom);
    return;
  }

  if (leafletMap) {
    if (!leafletMarker) {
      leafletMarker = L.marker([numLat, numLng], {
        draggable: true,
        icon: createLeafletPinIcon(),
      }).addTo(leafletMap);
      leafletMarker.on('dragend', async (ev) => {
        const ll = ev.target.getLatLng();
        await handleMapPick(ll.lat, ll.lng);
      });
    } else {
      leafletMarker.setLatLng([numLat, numLng]);
    }
    leafletMap.setView([numLat, numLng], zoom);
  }
};

const handleMapPick = async (lat, lng) => {
  const roundedLat = Number(lat.toFixed(7));
  const roundedLng = Number(lng.toFixed(7));
  emit('update:latitude', roundedLat);
  emit('update:longitude', roundedLng);
  setPinOnMap(roundedLat, roundedLng, leafletMap ? Math.max(leafletMap.getZoom(), 15) : 16);

  try {
    const { data } = await window.axios.get('/places/reverse', {
      params: { lat: roundedLat, lng: roundedLng },
    });
    if (data?.data) {
      emit('update:destinationAddress', data.data.address || '');
      if (data.data.place_id) emit('update:placeId', data.data.place_id);
      if (!String(props.destination || '').trim() && data.data.name) {
        emit('update:destination', data.data.name);
        searchText.value = data.data.name;
      }
    }
  } catch (_) {
    /* coordenadas ya actualizadas */
  }
};

const selectPlace = (item) => {
  results.value = [];
  searchDone.value = false;
  searchText.value = item.name;
  emit('update:destination', item.name);
  emit('update:destinationAddress', item.address || item.name);
  emit('update:latitude', Number(item.latitude));
  emit('update:longitude', Number(item.longitude));
  emit('update:placeId', item.place_id || '');
  setPinOnMap(item.latitude, item.longitude, 16);
};

const searchPlaces = async () => {
  const q = String(searchText.value || '').trim();
  if (q.length < 2) return;
  searching.value = true;
  searchDone.value = false;
  try {
    const { data } = await window.axios.get('/places/search', { params: { q } });
    results.value = data.data || [];
    searchDone.value = true;
  } catch (_) {
    results.value = [];
    searchDone.value = true;
  } finally {
    searching.value = false;
  }
};

const clearSearch = () => {
  searchText.value = '';
  results.value = [];
  searchDone.value = false;
};

const loadGoogleMapsScript = (apiKey) =>
  new Promise((resolve, reject) => {
    if (window.google?.maps?.places) {
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

const initLeaflet = () => {
  if (!mapContainerEl.value) return;
  const startLat = hasCoords.value ? Number(props.latitude) : DEFAULT_LAT;
  const startLng = hasCoords.value ? Number(props.longitude) : DEFAULT_LNG;
  const startZoom = hasCoords.value ? 16 : 12;

  leafletMap = L.map(mapContainerEl.value, {
    center: [startLat, startLng],
    zoom: startZoom,
  });

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap',
    maxZoom: 19,
  }).addTo(leafletMap);

  if (hasCoords.value) {
    setPinOnMap(startLat, startLng, 16);
  }

  leafletMap.on('click', async (ev) => {
    await handleMapPick(ev.latlng.lat, ev.latlng.lng);
  });

  setTimeout(() => {
    leafletMap?.invalidateSize();
  }, 180);
};

const initGoogleMaps = async (apiKey) => {
  const g = await loadGoogleMapsScript(apiKey);
  if (!mapContainerEl.value) return;
  usingGoogle.value = true;

  const startLat = hasCoords.value ? Number(props.latitude) : DEFAULT_LAT;
  const startLng = hasCoords.value ? Number(props.longitude) : DEFAULT_LNG;

  googleMap = new g.maps.Map(mapContainerEl.value, {
    center: { lat: startLat, lng: startLng },
    zoom: hasCoords.value ? 16 : 12,
    mapTypeControl: false,
    streetViewControl: false,
  });

  googleMarker = new g.maps.Marker({
    position: { lat: startLat, lng: startLng },
    map: googleMap,
    draggable: true,
    visible: hasCoords.value,
  });

  googleMap.addListener('click', async (ev) => {
    googleMarker.setVisible(true);
    await handleMapPick(ev.latLng.lat(), ev.latLng.lng());
  });

  googleMarker.addListener('dragend', async (ev) => {
    await handleMapPick(ev.latLng.lat(), ev.latLng.lng());
  });

  if (searchInputEl.value) {
    const autocomplete = new g.maps.places.Autocomplete(searchInputEl.value, {
      fields: ['name', 'formatted_address', 'geometry', 'place_id'],
    });
    autocomplete.addListener('place_changed', () => {
      const place = autocomplete.getPlace();
      if (!place?.geometry?.location) return;
      googleMarker.setVisible(true);
      selectPlace({
        name: place.name || place.formatted_address,
        address: place.formatted_address || place.name,
        latitude: place.geometry.location.lat(),
        longitude: place.geometry.location.lng(),
        place_id: place.place_id || '',
      });
    });
  }
};

watch(
  () => [props.latitude, props.longitude],
  ([lat, lng]) => {
    if (hasCoordinates(lat, lng)) {
      setPinOnMap(lat, lng, 16);
    }
  },
);

watch(
  () => props.destination,
  (val) => {
    if (val && !searchText.value) {
      searchText.value = val;
    }
  },
);

onMounted(async () => {
  const envGoogleKey = String(import.meta.env.VITE_GOOGLE_MAPS_API_KEY || '').trim();
  if (envGoogleKey) {
    try {
      await initGoogleMaps(envGoogleKey);
      return;
    } catch (_) {
      usingGoogle.value = false;
    }
  }
  initLeaflet();
});

onBeforeUnmount(() => {
  leafletMap?.remove();
  leafletMap = null;
  leafletMarker = null;
});
</script>
