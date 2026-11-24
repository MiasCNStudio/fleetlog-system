<template>
  <div :class="['fleet-card', className]">
    <div class="flex flex-wrap items-center justify-between gap-3 px-5 py-4 sm:px-6">
      <div class="min-w-0">
        <h3 class="text-base font-semibold text-gray-900 dark:text-white">
          {{ title }}
        </h3>
        <p v-if="desc" class="mt-0.5 text-theme-sm text-gray-500 dark:text-gray-400">
          {{ desc }}
        </p>
      </div>
      <div v-if="$slots['header-extra']" class="flex shrink-0 items-center gap-2">
        <slot name="header-extra" />
      </div>
    </div>
    <div class="border-t border-gray-100 p-4 dark:border-gray-800 sm:p-6">
      <div class="space-y-4">
        <slot />
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  title: { type: String, required: true },
  desc: { type: String, default: '' },
  className: { type: String, default: '' },
});
</script>
