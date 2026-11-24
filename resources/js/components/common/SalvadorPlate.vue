<template>
  <span
    v-if="parsed.isSalvador"
    :class="[
      'inline-flex items-center gap-1 rounded-md border px-2 py-0.5 font-mono shadow-xs select-none',
      toneClasses,
      compact ? 'text-[11px]' : 'text-xs',
    ]"
    :title="`Placa El Salvador (${parsed.raw})`"
  >
    <span
      :class="[
        'rounded px-1 py-0.5 text-[10px] font-extrabold leading-none tracking-tight',
        prefixBadgeClasses,
      ]"
    >
      {{ parsed.type }}
    </span>
    <span v-if="parsed.left" class="font-bold tracking-wider">{{ parsed.left }}</span>
    <svg
      class="size-3.5 shrink-0"
      viewBox="0 0 24 24"
      fill="none"
      aria-label="Escudo de El Salvador"
    >
      <circle cx="12" cy="12" r="9.5" fill="#0F47AF" stroke="#D4AF37" stroke-width="1.4" />
      <polygon points="12,5.5 17.5,15.5 6.5,15.5" fill="#FACC15" stroke="#FFFFFF" stroke-width="0.9" />
      <circle cx="12" cy="12.5" r="2" fill="#0F47AF" />
    </svg>
    <span class="font-bold tracking-wider">{{ parsed.right }}</span>
  </span>

  <span
    v-else
    class="inline-flex items-center rounded-md border border-gray-200 bg-gray-100 px-2.5 py-0.5 font-mono text-theme-xs font-semibold text-gray-900 dark:border-white/10 dark:bg-gray-800 dark:text-white"
  >
    {{ parsed.raw }}
  </span>
</template>

<script setup>
import { computed } from 'vue';
import { parseSalvadorPlate } from '@/utils/plates.js';

const props = defineProps({
  licensePlate: { type: String, default: '' },
  plateType: { type: String, default: '' },
  plateNumber: { type: String, default: '' },
  compact: { type: Boolean, default: false },
});

const parsed = computed(() =>
  parseSalvadorPlate(props.licensePlate, props.plateType, props.plateNumber),
);

const toneClasses = computed(() => {
  if (parsed.value.tone === 'diplomatic') {
    return 'border-sky-400/70 bg-sky-50 text-sky-950 dark:border-sky-500/40 dark:bg-sky-950/70 dark:text-sky-100';
  }
  if (parsed.value.tone === 'mission') {
    return 'border-indigo-400/70 bg-indigo-50 text-indigo-950 dark:border-indigo-500/40 dark:bg-indigo-950/70 dark:text-indigo-100';
  }
  if (parsed.value.tone === 'national') {
    return 'border-blue-700/40 bg-slate-100 text-blue-950 dark:border-blue-500/40 dark:bg-slate-800 dark:text-blue-100';
  }
  return 'border-blue-600/35 bg-white text-slate-900 dark:border-blue-400/30 dark:bg-[#0f172a] dark:text-white';
});

const prefixBadgeClasses = computed(() => {
  if (parsed.value.tone === 'diplomatic') return 'bg-sky-600 text-white';
  if (parsed.value.tone === 'mission') return 'bg-indigo-600 text-white';
  if (parsed.value.tone === 'national') return 'bg-blue-800 text-amber-300';
  return 'bg-[#0F47AF] text-white';
});
</script>
