import Swal from 'sweetalert2';

const baseCustomClass = {
  popup: 'fleet-swal-popup',
  title: 'fleet-swal-title',
  htmlContainer: 'fleet-swal-html',
  confirmButton: 'fleet-btn-primary mx-1',
  cancelButton: 'fleet-btn-secondary mx-1',
};

export function showSuccessAlert(title, text = '') {
  return Swal.fire({
    icon: 'success',
    title,
    ...(text ? { text } : {}),
    timer: 1400,
    showConfirmButton: false,
    buttonsStyling: false,
    customClass: baseCustomClass,
  });
}

export function showWarningAlert(title, text = '') {
  return Swal.fire({
    icon: 'warning',
    title,
    ...(text ? { text } : {}),
    confirmButtonText: 'Entendido',
    buttonsStyling: false,
    customClass: baseCustomClass,
  });
}

export function showErrorAlert(title, text = '') {
  return Swal.fire({
    icon: 'error',
    title,
    ...(text ? { text } : {}),
    confirmButtonText: 'Cerrar',
    buttonsStyling: false,
    customClass: baseCustomClass,
  });
}

export function confirmDeleteDialog({ title, text = '', confirmText = 'Sí, eliminar' }) {
  return Swal.fire({
    icon: 'warning',
    title,
    ...(text ? { text } : {}),
    showCancelButton: true,
    confirmButtonText: confirmText,
    cancelButtonText: 'Cancelar',
    reverseButtons: true,
    buttonsStyling: false,
    customClass: {
      ...baseCustomClass,
      confirmButton: 'fleet-btn-danger mx-1',
    },
  });
}
