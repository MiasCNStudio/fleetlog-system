<template>
  <div class="min-h-screen bg-[#f4f6fb] font-outfit text-gray-900 dark:bg-[#090e1a] dark:text-gray-100">
    <div
      v-if="isMobileOpen"
      class="fixed inset-0 z-40 bg-gray-950/65 backdrop-blur-[2px] transition-opacity lg:hidden"
      aria-hidden="true"
      @click="closeMobile"
    />

    <FleetSidebar />

    <div
      :class="[
        'flex min-h-screen min-w-0 flex-col transition-[padding] duration-300 ease-out',
        isDesktopCollapsed ? 'lg:pl-[76px]' : 'lg:pl-64',
      ]"
    >
      <FleetHeader :title="headerTitle" :user-name="userName" @logout="$emit('logout')" />
      <main class="mx-auto w-full max-w-[1536px] flex-1 p-4 sm:p-6">
        <slot />
      </main>
    </div>
  </div>
</template>

<script setup>
import { onBeforeUnmount, onMounted } from 'vue';
import FleetHeader from './FleetHeader.vue';
import FleetSidebar from './FleetSidebar.vue';
import { provideFleetLayout } from '@/composables/useFleetLayout.js';

defineProps({
  headerTitle: { type: String, default: '' },
  userName: { type: String, default: '' },
});

defineEmits(['logout']);

const { isMobileOpen, isDesktopCollapsed, closeMobile } = provideFleetLayout();

const onKeydown = (e) => {
  if (e.key === 'Escape' && isMobileOpen.value) {
    closeMobile();
  }
};

onMounted(() => {
  document.addEventListener('keydown', onKeydown);
});

onBeforeUnmount(() => {
  document.removeEventListener('keydown', onKeydown);
});
</script>
