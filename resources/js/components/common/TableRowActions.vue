<template>
  <div
    class="inline-flex items-center justify-end gap-1"
    role="group"
    :aria-label="groupLabel || 'Acciones de fila'"
  >
    <button
      v-if="showView"
      type="button"
      class="inline-flex size-8 items-center justify-center rounded-lg text-sky-600 transition-colors hover:bg-sky-500/15 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/40 dark:text-sky-400 dark:hover:bg-sky-400/15"
      :title="viewTitle"
      :aria-label="viewTitle"
      @click="$emit('view')"
    >
      <svg class="size-[1.125rem] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.75" aria-hidden="true">
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z"
        />
        <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
      </svg>
    </button>
    <button
      v-if="showEdit"
      type="button"
      class="inline-flex size-8 items-center justify-center rounded-lg text-amber-600 transition-colors hover:bg-amber-500/15 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/40 dark:text-amber-400 dark:hover:bg-amber-400/15"
      :title="editTitle"
      :aria-label="editTitle"
      @click="$emit('edit')"
    >
      <svg class="size-[1.125rem] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.75" aria-hidden="true">
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0115.75 21H5.25A2.25 2.25 0 013 18.75V8.25A2.25 2.25 0 015.25 6H10"
        />
      </svg>
    </button>
    <button
      v-if="showDelete"
      type="button"
      class="inline-flex size-8 items-center justify-center rounded-lg text-rose-600 transition-colors hover:bg-rose-500/15 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/40 dark:text-rose-400 dark:hover:bg-rose-400/15"
      :title="deleteTitle"
      :aria-label="deleteTitle"
      @click="$emit('delete')"
    >
      <svg class="size-[1.125rem] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.75" aria-hidden="true">
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .556c2.266.052 4.508.387 6.748.387m9.054-2.085c-.954.204-1.917.38-2.89.511m-7.448-.59c.554.054 1.09.17 1.589.348m9.054 2.085V7.5a2.25 2.25 0 00-2.25-2.25h-4.5A2.25 2.25 0 009.75 7.5v.09"
        />
      </svg>
    </button>
  </div>
</template>

<script setup>
defineProps({
  groupLabel: { type: String, default: '' },
  showView: { type: Boolean, default: true },
  showEdit: { type: Boolean, default: true },
  showDelete: { type: Boolean, default: true },
  viewTitle: { type: String, default: 'Ver detalle' },
  editTitle: { type: String, default: 'Editar' },
  deleteTitle: { type: String, default: 'Eliminar' },
});

defineEmits(['view', 'edit', 'delete']);
</script>
