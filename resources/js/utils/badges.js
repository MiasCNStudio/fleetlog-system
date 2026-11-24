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

export const BITACORA_CATEGORY_META = {
  asignacion: {
    label: 'Asignación',
    badge: 'bg-brand-50 text-brand-700 ring-1 ring-inset ring-brand-500/20 dark:bg-brand-500/15 dark:text-brand-300 dark:ring-brand-400/25',
  },
  personal: {
    label: 'Personal',
    badge: 'bg-purple-500/15 text-purple-700 ring-1 ring-inset ring-purple-500/20 dark:bg-purple-500/15 dark:text-purple-300 dark:ring-purple-400/25',
  },
  imprevisto: {
    label: 'Imprevisto',
    badge: 'bg-rose-500/15 text-rose-700 ring-1 ring-inset ring-rose-500/20 dark:bg-rose-500/15 dark:text-rose-300 dark:ring-rose-400/25',
  },
  combustible: {
    label: 'Combustible',
    badge: 'bg-amber-500/15 text-amber-800 ring-1 ring-inset ring-amber-500/25 dark:bg-amber-500/15 dark:text-amber-300 dark:ring-amber-400/25',
  },
};

export const ASSIGNMENT_STATUS_META = {
  pendiente: {
    label: 'Pendiente',
    badge: 'bg-amber-500/15 text-amber-800 ring-1 ring-inset ring-amber-500/25 dark:bg-amber-500/15 dark:text-amber-300 dark:ring-amber-400/25',
    dot: 'bg-amber-500',
  },
  en_curso: {
    label: 'En curso',
    badge: 'bg-brand-50 text-brand-700 ring-1 ring-inset ring-brand-500/20 dark:bg-brand-500/15 dark:text-brand-300 dark:ring-brand-400/25',
    dot: 'bg-brand-500',
  },
  completada: {
    label: 'Completada',
    badge: 'bg-emerald-500/15 text-emerald-700 ring-1 ring-inset ring-emerald-500/20 dark:bg-emerald-500/15 dark:text-emerald-300 dark:ring-emerald-400/20',
    dot: 'bg-emerald-500',
  },
  cancelada: {
    label: 'Cancelada',
    badge: 'bg-gray-100 text-gray-600 ring-1 ring-inset ring-gray-300/70 dark:bg-gray-800 dark:text-gray-400 dark:ring-gray-700',
    dot: 'bg-gray-400',
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
    label: 'Jefe de motoristas',
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

export const LOG_MODULE_META = {
  auth: {
    label: 'Acceso',
    badge: 'bg-gray-100 text-gray-700 ring-1 ring-inset ring-gray-300/70 dark:bg-gray-800 dark:text-gray-300 dark:ring-gray-700',
  },
  assignments: {
    label: 'Asignaciones',
    badge: 'bg-brand-50 text-brand-700 ring-1 ring-inset ring-brand-500/20 dark:bg-brand-500/15 dark:text-brand-300 dark:ring-brand-400/25',
  },
  bitacoras: {
    label: 'Bitácora',
    badge: 'bg-amber-500/15 text-amber-800 ring-1 ring-inset ring-amber-500/25 dark:bg-amber-500/15 dark:text-amber-300 dark:ring-amber-400/25',
  },
  vehicles: {
    label: 'Vehículos',
    badge: 'bg-sky-500/15 text-sky-700 ring-1 ring-inset ring-sky-500/20 dark:bg-sky-500/15 dark:text-sky-300 dark:ring-sky-400/25',
  },
  incidents: {
    label: 'Incidencias',
    badge: 'bg-rose-500/15 text-rose-700 ring-1 ring-inset ring-rose-500/20 dark:bg-rose-500/15 dark:text-rose-300 dark:ring-rose-400/25',
  },
  users: {
    label: 'Usuarios',
    badge: 'bg-purple-500/15 text-purple-700 ring-1 ring-inset ring-purple-500/20 dark:bg-purple-500/15 dark:text-purple-300 dark:ring-purple-400/25',
  },
  tracking: {
    label: 'Rastreo GPS',
    badge: 'bg-teal-500/15 text-teal-700 ring-1 ring-inset ring-teal-500/20 dark:bg-teal-500/15 dark:text-teal-300 dark:ring-teal-400/25',
  },
  maintenance: {
    label: 'Mantenimiento',
    badge: 'bg-orange-500/15 text-orange-700 ring-1 ring-inset ring-orange-500/25 dark:bg-orange-500/15 dark:text-orange-300 dark:ring-orange-400/25',
  },
  fuel: {
    label: 'Combustible',
    badge: 'bg-emerald-500/15 text-emerald-700 ring-1 ring-inset ring-emerald-500/20 dark:bg-emerald-500/15 dark:text-emerald-300 dark:ring-emerald-400/20',
  },
};

export const MAINTENANCE_ALERT_META = {
  al_dia: {
    label: 'Al día',
    badge: 'bg-emerald-500/15 text-emerald-700 ring-1 ring-inset ring-emerald-500/20 dark:bg-emerald-500/15 dark:text-emerald-300 dark:ring-emerald-400/20',
    dot: 'bg-emerald-500',
  },
  pronto: {
    label: 'Mant. pronto',
    badge: 'bg-amber-500/20 text-amber-900 ring-1 ring-inset ring-amber-500/35 dark:bg-amber-500/20 dark:text-amber-200 dark:ring-amber-400/35',
    dot: 'bg-amber-500',
  },
  vencido: {
    label: '¡MANT. VENCIDO!',
    badge: 'bg-rose-600 text-white ring-1 ring-inset ring-rose-700 shadow-xs',
    dot: 'bg-white',
  },
  sin_programar: {
    label: 'Sin meta km',
    badge: 'bg-gray-100 text-gray-600 ring-1 ring-inset ring-gray-300/70 dark:bg-gray-800 dark:text-gray-400 dark:ring-gray-700',
    dot: 'bg-gray-400',
  },
};

export const MAINTENANCE_JOB_META = {
  programado: {
    label: 'Programado',
    badge: 'bg-amber-500/15 text-amber-800 ring-1 ring-inset ring-amber-500/25 dark:bg-amber-500/15 dark:text-amber-300 dark:ring-amber-400/25',
    dot: 'bg-amber-500',
  },
  completado: {
    label: 'Completado',
    badge: 'bg-emerald-500/15 text-emerald-700 ring-1 ring-inset ring-emerald-500/20 dark:bg-emerald-500/15 dark:text-emerald-300 dark:ring-emerald-400/20',
    dot: 'bg-emerald-500',
  },
  cancelado: {
    label: 'Cancelado',
    badge: 'bg-gray-100 text-gray-600 ring-1 ring-inset ring-gray-300/70 dark:bg-gray-800 dark:text-gray-400 dark:ring-gray-700',
    dot: 'bg-gray-400',
  },
};

export const TRACKING_STATUS_META = {
  activa: {
    label: 'En misión',
    badge: 'bg-emerald-500/15 text-emerald-700 ring-1 ring-inset ring-emerald-500/20 dark:bg-emerald-500/15 dark:text-emerald-300 dark:ring-emerald-400/20',
    dot: 'bg-emerald-500',
  },
  finalizada: {
    label: 'Finalizada',
    badge: 'bg-brand-50 text-brand-700 ring-1 ring-inset ring-brand-500/20 dark:bg-brand-500/15 dark:text-brand-300 dark:ring-brand-400/25',
    dot: 'bg-brand-500',
  },
  interrumpida: {
    label: 'Interrumpida',
    badge: 'bg-rose-500/15 text-rose-700 ring-1 ring-inset ring-rose-500/20 dark:bg-rose-500/15 dark:text-rose-300 dark:ring-rose-400/25',
    dot: 'bg-rose-500',
  },
};

export const LOG_ACTION_META = {
  created: {
    label: 'Creación',
    badge: 'bg-emerald-500/15 text-emerald-700 ring-1 ring-inset ring-emerald-500/20 dark:bg-emerald-500/15 dark:text-emerald-300 dark:ring-emerald-400/20',
  },
  updated: {
    label: 'Edición',
    badge: 'bg-sky-500/15 text-sky-700 ring-1 ring-inset ring-sky-500/20 dark:bg-sky-500/15 dark:text-sky-300 dark:ring-sky-400/25',
  },
  deleted: {
    label: 'Eliminación',
    badge: 'bg-rose-500/15 text-rose-700 ring-1 ring-inset ring-rose-500/20 dark:bg-rose-500/15 dark:text-rose-300 dark:ring-rose-400/25',
  },
  emergency_reassigned: {
    label: 'Emergencia',
    badge: 'bg-rose-600/20 text-rose-800 ring-1 ring-inset ring-rose-600/25 dark:bg-rose-500/20 dark:text-rose-300 dark:ring-rose-400/30',
  },
  personal_trip: {
    label: 'Viaje personal',
    badge: 'bg-purple-500/15 text-purple-700 ring-1 ring-inset ring-purple-500/20 dark:bg-purple-500/15 dark:text-purple-300 dark:ring-purple-400/25',
  },
  unplanned_trip: {
    label: 'Imprevisto',
    badge: 'bg-amber-500/15 text-amber-800 ring-1 ring-inset ring-amber-500/25 dark:bg-amber-500/15 dark:text-amber-300 dark:ring-amber-400/25',
  },
  fuel_trip: {
    label: 'Echar gasolina',
    badge: 'bg-amber-500/15 text-amber-800 ring-1 ring-inset ring-amber-500/25 dark:bg-amber-500/15 dark:text-amber-300 dark:ring-amber-400/25',
  },
  fuel_to_assignment: {
    label: 'Gasolinera → Misión',
    badge: 'bg-teal-500/15 text-teal-700 ring-1 ring-inset ring-teal-500/20 dark:bg-teal-500/15 dark:text-teal-300 dark:ring-teal-400/25',
  },
  receipt_attached: {
    label: 'Factura adjunta',
    badge: 'bg-sky-500/15 text-sky-700 ring-1 ring-inset ring-sky-500/20 dark:bg-sky-500/15 dark:text-sky-300 dark:ring-sky-400/25',
  },
  login: {
    label: 'Ingreso',
    badge: 'bg-gray-100 text-gray-700 ring-1 ring-inset ring-gray-300/70 dark:bg-gray-800 dark:text-gray-300 dark:ring-gray-700',
  },
  logout: {
    label: 'Salida',
    badge: 'bg-gray-100 text-gray-600 ring-1 ring-inset ring-gray-300/70 dark:bg-gray-800 dark:text-gray-400 dark:ring-gray-700',
  },
  session_started: {
    label: 'Inicio rastreo',
    badge: 'bg-teal-500/15 text-teal-700 ring-1 ring-inset ring-teal-500/20 dark:bg-teal-500/15 dark:text-teal-300 dark:ring-teal-400/25',
  },
  session_finished: {
    label: 'Fin rastreo',
    badge: 'bg-brand-50 text-brand-700 ring-1 ring-inset ring-brand-500/20 dark:bg-brand-500/15 dark:text-brand-300 dark:ring-brand-400/25',
  },
  device_bound: {
    label: 'Celular vinculado',
    badge: 'bg-sky-500/15 text-sky-700 ring-1 ring-inset ring-sky-500/20 dark:bg-sky-500/15 dark:text-sky-300 dark:ring-sky-400/25',
  },
  device_mismatch: {
    label: 'Dispositivo distinto',
    badge: 'bg-rose-600/20 text-rose-800 ring-1 ring-inset ring-rose-600/25 dark:bg-rose-500/20 dark:text-rose-300 dark:ring-rose-400/30',
  },
  sos_alert: {
    label: 'Alerta SOS',
    badge: 'bg-rose-600/20 text-rose-800 ring-1 ring-inset ring-rose-600/25 dark:bg-rose-500/20 dark:text-rose-300 dark:ring-rose-400/30',
  },
};
