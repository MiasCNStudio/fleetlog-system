<template>
  <div class="min-h-screen bg-gray-50 font-outfit dark:bg-gray-900">
    <div
      v-if="isMobileOpen"
      class="fixed inset-0 z-[99998] bg-black/40 lg:hidden"
      @click="closeMobile"
    />
    <FleetSidebar />
    <div class="lg:pl-[72px] lg:[@media(hover:none)]:pl-[280px]">
      <FleetHeader :title="headerTitle" :user-name="userName" @logout="$emit('logout')" />
      <main class="mx-auto max-w-[1536px] p-4 md:p-6">
        <slot />
      </main>
    </div>
  </div>
</template>

<script setup>
import FleetHeader from './FleetHeader.vue';
import FleetSidebar from './FleetSidebar.vue';
import { provideFleetLayout } from '@/composables/useFleetLayout.js';

defineProps({
  headerTitle: { type: String, default: '' },
  userName: { type: String, default: '' },
});

defineEmits(['logout']);

const { isMobileOpen, closeMobile } = provideFleetLayout();
</script>
