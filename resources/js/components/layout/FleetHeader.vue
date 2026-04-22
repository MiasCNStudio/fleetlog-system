<template>
  <header
    class="sticky top-0 z-[9999] flex w-full items-center justify-between border-b border-gray-200 bg-white px-4 py-3 dark:border-gray-800 dark:bg-gray-900 lg:px-6"
  >
    <div class="flex items-center gap-3">
      <button
        type="button"
        class="flex h-10 w-10 items-center justify-center rounded-lg border border-gray-200 text-gray-600 dark:border-gray-800 dark:text-gray-300 lg:hidden"
        aria-label="Abrir menú"
        @click="toggleMobile"
      >
        <svg width="20" height="14" viewBox="0 0 20 14" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path
            fill-rule="evenodd"
            clip-rule="evenodd"
            d="M0 1C0 0.447715 0.447715 0 1 0H19C19.5523 0 20 0.447715 20 1C20 1.55228 19.5523 2 19 2H1C0.447715 2 0 1.55228 0 1ZM0 7C0 6.44772 0.447715 6 1 6H13C13.5523 6 14 6.44772 14 7C14 7.55228 13.5523 8 13 8H1C0.447715 8 0 7.55228 0 7ZM1 12C0.447715 12 0 12.4477 0 13C0 13.5523 0.447715 14 1 14H19C19.5523 14 20 13.5523 20 13C20 12.4477 19.5523 12 19 12H1Z"
            fill="currentColor"
          />
        </svg>
      </button>
      <div>
        <p class="text-theme-xs uppercase tracking-wide text-gray-400">Panel</p>
        <p class="text-theme-sm font-medium text-gray-800 dark:text-white/90">{{ title }}</p>
      </div>
    </div>
    <div class="flex items-center gap-3">
      <span class="hidden text-theme-sm text-gray-600 dark:text-gray-300 sm:inline">{{ userLabel }}</span>
      <button
        type="button"
        class="rounded-lg bg-brand-500 px-3 py-2 text-theme-sm font-medium text-white hover:bg-brand-600"
        @click="$emit('logout')"
      >
        Salir
      </button>
    </div>
  </header>
</template>

<script setup>
import { computed } from 'vue';
import { useFleetLayout } from '@/composables/useFleetLayout.js';

const props = defineProps({
  title: { type: String, default: '' },
  userName: { type: String, default: '' },
});

defineEmits(['logout']);

const { toggleMobile } = useFleetLayout();

const userLabel = computed(() => props.userName || 'Usuario');
</script>
