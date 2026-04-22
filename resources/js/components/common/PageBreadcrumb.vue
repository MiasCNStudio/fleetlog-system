<template>
  <div class="mb-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
    <div>
      <h1 class="text-title-sm font-semibold text-gray-800 dark:text-white/90">
        {{ pageTitle }}
      </h1>
      <p v-if="subtitle" class="mt-1 text-theme-sm text-gray-500 dark:text-gray-400">
        {{ subtitle }}
      </p>
    </div>
    <slot name="actions" />
  </div>
</template>

<script setup>
defineProps({
  pageTitle: { type: String, required: true },
  subtitle: { type: String, default: '' },
});
</script>
