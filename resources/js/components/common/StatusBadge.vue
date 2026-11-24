<template>
  <span
    class="inline-flex items-center gap-1.5 whitespace-nowrap rounded-full px-2.5 py-0.5 text-theme-xs font-medium"
    :class="badgeClass"
  >
    <span v-if="dotClass" class="size-1.5 shrink-0 rounded-full" :class="dotClass" aria-hidden="true" />
    {{ label }}
  </span>
</template>

<script setup>
import { computed } from 'vue';
import {
  ASSIGNMENT_STATUS_META,
  BITACORA_TYPE_META,
  INCIDENT_SEVERITY_META,
  INCIDENT_STATUS_META,
  USER_ROLE_META,
  USER_TYPE_META,
  VEHICLE_STATUS_META,
} from '@/utils/badges.js';

const props = defineProps({
  kind: { type: String, required: true },
  value: { type: String, default: '' },
});

const maps = {
  vehicleStatus: VEHICLE_STATUS_META,
  bitacoraType: BITACORA_TYPE_META,
  assignmentStatus: ASSIGNMENT_STATUS_META,
  incidentStatus: INCIDENT_STATUS_META,
  incidentSeverity: INCIDENT_SEVERITY_META,
  userRole: USER_ROLE_META,
  userType: USER_TYPE_META,
};

const resolved = computed(() => {
  const table = maps[props.kind] || {};
  return table[props.value] || {
    label: props.value || '—',
    badge: 'bg-gray-100 text-gray-700 ring-1 ring-inset ring-gray-300/70 dark:bg-gray-800 dark:text-gray-300 dark:ring-gray-700',
    dot: '',
  };
});

const label = computed(() => resolved.value.label);
const badgeClass = computed(() => resolved.value.badge);
const dotClass = computed(() => resolved.value.dot || '');
</script>
