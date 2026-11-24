import { computed, ref } from 'vue';
import { useRouter } from 'vue-router';
import Swal from 'sweetalert2';
import { setAuthToken } from '../bootstrap';

const storedUser = (() => {
  try {
    const raw = localStorage.getItem('auth_user');
    return raw ? JSON.parse(raw) : null;
  } catch (_) {
    return null;
  }
})();

const currentUser = ref(storedUser);

export function setCurrentUser(user) {
  currentUser.value = user || null;
  if (user) {
    localStorage.setItem('auth_user', JSON.stringify(user));
  } else {
    localStorage.removeItem('auth_user');
  }
}

export function useAuth() {
  const router = useRouter();

  const isAdmin = computed(() => currentUser.value?.role === 'admin');
  const canManageFleet = computed(() =>
    ['admin', 'despachador'].includes(currentUser.value?.role),
  );

  const loadMe = async () => {
    const { data } = await window.axios.get('/user');
    setCurrentUser(data);
    return data;
  };

  const logout = async (showAlert = false) => {
    try {
      await window.axios.post('/logout');
    } catch (_) {
      /* vacío */
    } finally {
      setAuthToken(null);
      setCurrentUser(null);
      await router.push({ name: 'login' });
      if (showAlert) {
        Swal.fire({
          icon: 'success',
          title: 'Sesión cerrada',
          timer: 1200,
          showConfirmButton: false,
        });
      }
    }
  };

  return {
    currentUser,
    isAdmin,
    canManageFleet,
    loadMe,
    logout,
  };
}
