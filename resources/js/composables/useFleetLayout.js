import { inject, provide, ref } from 'vue';

const FleetLayoutKey = Symbol('fleetLayout');
const SIDEBAR_STORAGE_KEY = 'fleetlog_sidebar_collapsed';

export function provideFleetLayout() {
  const isMobileOpen = ref(false);
  const isDesktopCollapsed = ref(localStorage.getItem(SIDEBAR_STORAGE_KEY) === '1');

  const toggleMobile = () => {
    isMobileOpen.value = !isMobileOpen.value;
  };

  const closeMobile = () => {
    isMobileOpen.value = false;
  };

  const toggleDesktopCollapsed = () => {
    isDesktopCollapsed.value = !isDesktopCollapsed.value;
    try {
      localStorage.setItem(SIDEBAR_STORAGE_KEY, isDesktopCollapsed.value ? '1' : '0');
    } catch (_) {
      /* sin acceso a almacenamiento */
    }
  };

  const ctx = {
    isMobileOpen,
    isDesktopCollapsed,
    toggleMobile,
    closeMobile,
    toggleDesktopCollapsed,
  };
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
