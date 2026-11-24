<template>
  <div
    v-if="lastPage > 1 || total > 0"
    class="flex flex-col gap-3 border-t border-gray-100 px-4 py-3.5 dark:border-gray-800 sm:flex-row sm:items-center sm:justify-between sm:px-5"
  >
    <p class="text-theme-xs text-gray-500 tabular-nums dark:text-gray-400">
      <template v-if="from && to && total">
        Mostrando <span class="font-semibold text-gray-700 dark:text-gray-200">{{ from }}–{{ to }}</span> de
        <span class="font-semibold text-gray-700 dark:text-gray-200">{{ total }}</span> registros
        <span class="mx-1.5 text-gray-300 dark:text-gray-700">·</span>
      </template>
      Página <span class="font-semibold text-gray-700 dark:text-gray-200">{{ currentPage }}</span> de
      <span class="font-semibold text-gray-700 dark:text-gray-200">{{ lastPage }}</span>
    </p>

    <div v-if="lastPage > 1" class="flex items-center gap-2">
      <button
        type="button"
        class="fleet-btn-secondary h-9 px-3 py-1.5 text-theme-xs"
        :disabled="currentPage <= 1"
        @click="$emit('change', currentPage - 1)"
      >
        <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
        </svg>
        Anterior
      </button>
      <button
        type="button"
        class="fleet-btn-secondary h-9 px-3 py-1.5 text-theme-xs"
        :disabled="currentPage >= lastPage"
        @click="$emit('change', currentPage + 1)"
      >
        Siguiente
        <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
        </svg>
      </button>
    </div>
  </div>
</template>

<script setup>
defineProps({
  currentPage: { type: Number, required: true },
  lastPage: { type: Number, required: true },
  total: { type: Number, default: 0 },
  from: { type: Number, default: 0 },
  to: { type: Number, default: 0 },
});

defineEmits(['change']);
</script>
