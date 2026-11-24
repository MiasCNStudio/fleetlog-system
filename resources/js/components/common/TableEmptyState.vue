<template>
  <div class="flex flex-col items-center justify-center px-6 py-12 text-center">
    <div
      class="mb-3 flex size-12 items-center justify-center rounded-2xl bg-gray-100 text-gray-400 dark:bg-gray-800 dark:text-gray-500"
    >
      <svg
        v-if="icon === 'truck'"
        class="size-6"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        stroke-width="1.6"
        aria-hidden="true"
      >
        <path stroke-linecap="round" stroke-linejoin="round" d="M9 17a2 2 0 11-4 0 2 2 0 014 0zM19 17a2 2 0 11-4 0 2 2 0 014 0z" />
        <path stroke-linecap="round" stroke-linejoin="round" d="M13 16V6a1 1 0 00-1-1H4a1 1 0 00-1 1v10a1 1 0 001 1h1m8-1a1 1 0 01-1 1H9m4-1V8a1 1 0 011-1h2.586a1 1 0 01.707.293l3.414 3.414a1 1 0 01.293.707V16a1 1 0 01-1 1h-1m-6-1a1 1 0 001 1h1" />
      </svg>
      <svg
        v-else-if="icon === 'alert'"
        class="size-6"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        stroke-width="1.6"
        aria-hidden="true"
      >
        <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9.303 3.376c-.866 1.5.217 3.374 1.948 3.374H2.697c-1.73 0-2.813-1.874-1.948-3.374L10.051 3.378c.866-1.5 3.032-1.5 3.898 0l7.354 12.748zM12 15.75h.007v.008H12v-.008z" />
      </svg>
      <svg
        v-else-if="icon === 'users'"
        class="size-6"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        stroke-width="1.6"
        aria-hidden="true"
      >
        <path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
      </svg>
      <svg
        v-else
        class="size-6"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        stroke-width="1.6"
        aria-hidden="true"
      >
        <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
      </svg>
    </div>

    <h4 class="text-theme-sm font-semibold text-gray-800 dark:text-white">
      {{ title }}
    </h4>
    <p v-if="description" class="mt-1 max-w-sm text-theme-xs text-gray-500 dark:text-gray-400">
      {{ description }}
    </p>

    <div v-if="hasFilters || $slots.action" class="mt-4 flex flex-wrap items-center justify-center gap-2">
      <button
        v-if="hasFilters"
        type="button"
        class="fleet-btn-secondary h-9 px-3.5 py-1.5 text-theme-xs"
        @click="$emit('reset')"
      >
        Limpiar filtros
      </button>
      <slot name="action" />
    </div>
  </div>
</template>

<script setup>
defineProps({
  title: { type: String, required: true },
  description: { type: String, default: '' },
  icon: { type: String, default: 'clipboard' },
  hasFilters: { type: Boolean, default: false },
});

defineEmits(['reset']);
</script>
