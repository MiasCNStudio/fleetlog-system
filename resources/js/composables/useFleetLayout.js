import { inject, provide, ref } from 'vue';

const FleetLayoutKey = Symbol('fleetLayout');

export function provideFleetLayout() {
  const isMobileOpen = ref(false);

  const toggleMobile = () => {
    isMobileOpen.value = !isMobileOpen.value;
  };

  const closeMobile = () => {
    isMobileOpen.value = false;
  };

  const ctx = { isMobileOpen, toggleMobile, closeMobile };
  provide(FleetLayoutKey, ctx);

  return ctx;
}

export function useFleetLayout() {
  const ctx = inject(FleetLayoutKey);
  if (!ctx) {
    throw new Error('useFleetLayout debe usarse dentro de AdminLayout');
  }
  return ctx;
}
