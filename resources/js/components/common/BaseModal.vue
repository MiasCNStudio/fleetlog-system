<template>
  <Teleport to="body">
    <div
      v-if="open"
      class="fixed inset-0 z-[1100] flex items-center justify-center bg-gray-950/60 p-3 backdrop-blur-[2px] sm:p-4"
      role="dialog"
      aria-modal="true"
      :aria-labelledby="titleId"
      @click.self="$emit('close')"
    >
      <div
        :class="[
          'flex max-h-[90vh] w-full flex-col overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-xl dark:border-gray-800 dark:bg-gray-900',
          maxWidthClass,
        ]"
      >
        <div class="flex items-start justify-between gap-4 border-b border-gray-100 px-5 py-4 dark:border-gray-800 sm:px-6">
          <div class="min-w-0">
            <h2 :id="titleId" class="truncate text-lg font-semibold text-gray-900 dark:text-white">
              {{ title }}
            </h2>
            <p v-if="subtitle" class="mt-0.5 text-theme-xs text-gray-500 dark:text-gray-400">
              {{ subtitle }}
            </p>
          </div>
          <button
            type="button"
            class="inline-flex size-8 shrink-0 items-center justify-center rounded-lg text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/40 dark:hover:bg-white/10 dark:hover:text-gray-200"
            aria-label="Cerrar ventana"
            @click="$emit('close')"
          >
            <svg class="size-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div class="flex-1 overflow-y-auto px-5 py-4 sm:px-6 sm:py-5">
          <slot />
        </div>

        <div
          v-if="$slots.footer"
          class="flex flex-wrap items-center justify-end gap-2 border-t border-gray-100 bg-gray-50/70 px-5 py-3.5 dark:border-gray-800 dark:bg-white/[0.02] sm:px-6"
        >
          <slot name="footer" />
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { computed, onBeforeUnmount, useId, watch } from 'vue';

const props = defineProps({
  open: { type: Boolean, default: false },
  title: { type: String, required: true },
  subtitle: { type: String, default: '' },
  maxWidth: { type: String, default: 'lg' },
});

const emit = defineEmits(['close']);
const titleId = useId();

const maxWidthClass = computed(() => {
  if (props.maxWidth === 'md') return 'max-w-md';
  if (props.maxWidth === 'xl') return 'max-w-2xl';
  if (props.maxWidth === '2xl') return 'max-w-4xl';
  return 'max-w-lg';
});

const onKeydown = (e) => {
  if (e.key === 'Escape' && props.open) {
    emit('close');
  }
};

watch(
  () => props.open,
  (isOpen) => {
    if (isOpen) {
      document.addEventListener('keydown', onKeydown);
      document.body.style.overflow = 'hidden';
    } else {
      document.removeEventListener('keydown', onKeydown);
      document.body.style.overflow = '';
    }
  },
  { immediate: true },
);

onBeforeUnmount(() => {
  document.removeEventListener('keydown', onKeydown);
  document.body.style.overflow = '';
});
</script>
