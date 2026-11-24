<template>
  <div class="mb-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
    <div class="min-w-0">
      <h1 class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white sm:text-title-sm">
        {{ pageTitle }}
      </h1>
      <p v-if="subtitle" class="mt-1 text-theme-sm text-gray-500 dark:text-gray-400">
        {{ subtitle }}
      </p>
    </div>
    <div v-if="$slots.actions" class="flex shrink-0 flex-wrap items-center gap-2">
      <slot name="actions" />
    </div>
  </div>
</template>

<script setup>
defineProps({
  pageTitle: { type: String, required: true },
  subtitle: { type: String, default: '' },
});
</script>
