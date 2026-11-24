export const VEHICLE_STATUS_META = {
  disponible: {
    label: 'Disponible',
    badge: 'bg-emerald-500/15 text-emerald-700 ring-1 ring-inset ring-emerald-500/20 dark:bg-emerald-500/15 dark:text-emerald-300 dark:ring-emerald-400/20',
    dot: 'bg-emerald-500',
  },
  en_ruta: {
    label: 'En ruta',
    badge: 'bg-amber-500/15 text-amber-800 ring-1 ring-inset ring-amber-500/25 dark:bg-amber-500/15 dark:text-amber-300 dark:ring-amber-400/25',
    dot: 'bg-amber-500',
  },
  mantenimiento: {
    label: 'Mantenimiento',
    badge: 'bg-rose-500/15 text-rose-700 ring-1 ring-inset ring-rose-500/20 dark:bg-rose-500/15 dark:text-rose-300 dark:ring-rose-400/25',
    dot: 'bg-rose-500',
  },
};

export const BITACORA_TYPE_META = {
  salida: {
    label: 'Salida',
    badge: 'bg-amber-500/15 text-amber-800 ring-1 ring-inset ring-amber-500/25 dark:bg-amber-500/15 dark:text-amber-300 dark:ring-amber-400/25',
    dot: 'bg-amber-500',
  },
  regreso: {
    label: 'Regreso',
    badge: 'bg-emerald-500/15 text-emerald-700 ring-1 ring-inset ring-emerald-500/20 dark:bg-emerald-500/15 dark:text-emerald-300 dark:ring-emerald-400/20',
    dot: 'bg-emerald-500',
  },
};

export const INCIDENT_STATUS_META = {
  abierta: {
    label: 'Abierta',
    badge: 'bg-rose-500/15 text-rose-700 ring-1 ring-inset ring-rose-500/20 dark:bg-rose-500/15 dark:text-rose-300 dark:ring-rose-400/25',
    dot: 'bg-rose-500',
  },
  en_revision: {
    label: 'En revisión',
    badge: 'bg-amber-500/15 text-amber-800 ring-1 ring-inset ring-amber-500/25 dark:bg-amber-500/15 dark:text-amber-300 dark:ring-amber-400/25',
    dot: 'bg-amber-500',
  },
  resuelta: {
    label: 'Resuelta',
    badge: 'bg-emerald-500/15 text-emerald-700 ring-1 ring-inset ring-emerald-500/20 dark:bg-emerald-500/15 dark:text-emerald-300 dark:ring-emerald-400/20',
    dot: 'bg-emerald-500',
  },
};

export const INCIDENT_SEVERITY_META = {
  baja: {
    label: 'Baja',
    badge: 'bg-gray-100 text-gray-700 ring-1 ring-inset ring-gray-300/70 dark:bg-gray-800 dark:text-gray-300 dark:ring-gray-700',
    dot: 'bg-gray-400',
  },
  media: {
    label: 'Media',
    badge: 'bg-sky-500/15 text-sky-700 ring-1 ring-inset ring-sky-500/20 dark:bg-sky-500/15 dark:text-sky-300 dark:ring-sky-400/25',
    dot: 'bg-sky-500',
  },
  alta: {
    label: 'Alta',
    badge: 'bg-amber-500/15 text-amber-800 ring-1 ring-inset ring-amber-500/25 dark:bg-amber-500/15 dark:text-amber-300 dark:ring-amber-400/25',
    dot: 'bg-amber-500',
  },
  critica: {
    label: 'Crítica',
    badge: 'bg-rose-600/20 text-rose-800 ring-1 ring-inset ring-rose-600/25 dark:bg-rose-500/20 dark:text-rose-300 dark:ring-rose-400/30',
    dot: 'bg-rose-600',
  },
};

export const USER_ROLE_META = {
  admin: {
    label: 'Administrador',
    badge: 'bg-purple-500/15 text-purple-700 ring-1 ring-inset ring-purple-500/20 dark:bg-purple-500/15 dark:text-purple-300 dark:ring-purple-400/25',
  },
  despachador: {
    label: 'Despachador',
    badge: 'bg-sky-500/15 text-sky-700 ring-1 ring-inset ring-sky-500/20 dark:bg-sky-500/15 dark:text-sky-300 dark:ring-sky-400/25',
  },
  motorista: {
    label: 'Motorista',
    badge: 'bg-gray-100 text-gray-700 ring-1 ring-inset ring-gray-300/70 dark:bg-gray-800 dark:text-gray-300 dark:ring-gray-700',
  },
};

export const USER_TYPE_META = {
  motorista: {
    label: 'Motorista',
    badge: 'bg-brand-50 text-brand-700 ring-1 ring-inset ring-brand-500/20 dark:bg-brand-500/15 dark:text-brand-300 dark:ring-brand-400/25',
  },
  funcionario: {
    label: 'Funcionario',
    badge: 'bg-emerald-500/15 text-emerald-700 ring-1 ring-inset ring-emerald-500/20 dark:bg-emerald-500/15 dark:text-emerald-300 dark:ring-emerald-400/20',
  },
};
