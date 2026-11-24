<template>
  <header
    class="sticky top-0 z-30 flex h-16 w-full items-center justify-between gap-3 border-b border-gray-200/80 bg-white/90 px-4 backdrop-blur-md dark:border-white/[0.07] dark:bg-[#0f172a]/90 lg:px-6"
  >
    <div class="flex min-w-0 items-center gap-3">
      <button
        type="button"
        class="inline-flex size-10 shrink-0 items-center justify-center rounded-xl border border-gray-200 text-gray-600 transition-colors hover:bg-gray-50 hover:text-gray-900 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/40 dark:border-white/10 dark:text-gray-300 dark:hover:bg-white/[0.06] dark:hover:text-white lg:hidden"
        aria-label="Abrir menú"
        :aria-expanded="isMobileOpen"
        @click="toggleMobile"
      >
        <svg class="size-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h12" />
        </svg>
      </button>

      <button
        type="button"
        class="hidden size-9 shrink-0 items-center justify-center rounded-xl border border-gray-200 text-gray-600 transition-colors hover:bg-gray-50 hover:text-gray-900 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/40 dark:border-white/10 dark:text-gray-300 dark:hover:bg-white/[0.06] dark:hover:text-white lg:inline-flex"
        :aria-label="isDesktopCollapsed ? 'Expandir menú lateral' : 'Contraer menú lateral'"
        :aria-expanded="!isDesktopCollapsed"
        :title="isDesktopCollapsed ? 'Expandir menú' : 'Contraer menú'"
        @click="toggleDesktopCollapsed"
      >
        <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 5.25h16.5m-16.5 4.5h10.5m-10.5 4.5h16.5m-16.5 4.5h10.5" />
        </svg>
      </button>

      <div class="min-w-0">
        <p class="text-[11px] font-semibold uppercase tracking-wider text-gray-400 dark:text-gray-500">
          Panel operativo
        </p>
        <p class="truncate text-theme-sm font-semibold text-gray-900 dark:text-white">
          {{ title }}
        </p>
      </div>
    </div>

    <div class="flex shrink-0 items-center gap-2 sm:gap-2.5">
      <button
        type="button"
        class="inline-flex size-9 items-center justify-center rounded-xl border border-gray-200 bg-white text-gray-600 shadow-theme-xs transition-colors hover:bg-gray-50 hover:text-gray-900 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/40 dark:border-white/10 dark:bg-[#161f32] dark:text-gray-300 dark:hover:bg-white/[0.08] dark:hover:text-white"
        :aria-label="isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro'"
        :title="isDark ? 'Modo claro' : 'Modo oscuro'"
        @click="toggleDark()"
      >
        <svg v-if="isDark" class="size-4 text-amber-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 3v2.25m6.364.386l-1.591 1.591M21 12h-2.25m-.386 6.364l-1.591-1.591M12 18.75V21m-4.773-4.227l-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0z" />
        </svg>
        <svg v-else class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" d="M21.752 15.002A9.718 9.718 0 0118 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 003 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 009.002-5.998z" />
        </svg>
      </button>

      <div class="hidden items-center gap-2.5 rounded-xl border border-gray-200/80 bg-gray-50/90 py-1 pl-1.5 pr-3 dark:border-white/10 dark:bg-white/[0.04] sm:flex">
        <span class="flex size-7 items-center justify-center rounded-lg bg-brand-500/15 text-theme-xs font-semibold text-brand-600 dark:bg-brand-500/20 dark:text-brand-300">
          {{ initials }}
        </span>
        <div class="leading-tight">
          <p class="max-w-[140px] truncate text-theme-xs font-semibold text-gray-800 dark:text-gray-100">
            {{ userLabel }}
          </p>
          <p v-if="roleLabel" class="text-[11px] capitalize text-gray-500 dark:text-gray-400">
            {{ roleLabel }}
          </p>
        </div>
      </div>

      <button
        type="button"
        class="fleet-btn-secondary h-9 px-3 py-1.5 text-theme-xs"
        @click="$emit('logout')"
      >
        <svg class="size-4 text-gray-500 dark:text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15m3 0l3-3m0 0l-3-3m3 3H9" />
        </svg>
        <span>Salir</span>
      </button>
    </div>
  </header>
</template>

<script setup>
import { computed } from 'vue';
import { useDark, useToggle } from '@vueuse/core';
import { useFleetLayout } from '@/composables/useFleetLayout.js';
import { useAuth } from '@/composables/useAuth.js';

const props = defineProps({
  title: { type: String, default: '' },
  userName: { type: String, default: '' },
});

defineEmits(['logout']);

const { isMobileOpen, isDesktopCollapsed, toggleMobile, toggleDesktopCollapsed } = useFleetLayout();
const { currentUser } = useAuth();
const isDark = useDark();
const toggleDark = useToggle(isDark);

const userLabel = computed(() => props.userName || currentUser.value?.name || 'Usuario');
const roleLabel = computed(() => currentUser.value?.role || '');

const initials = computed(() => {
  const parts = String(userLabel.value).trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return 'U';
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
});
</script>
