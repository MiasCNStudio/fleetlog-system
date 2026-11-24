import axios from 'axios';
import router from './router';

const token = localStorage.getItem('auth_token');

window.axios = axios;
window.axios.defaults.baseURL = import.meta.env.VITE_API_BASE_URL || '/api';
window.axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';

if (token) {
  window.axios.defaults.headers.common.Authorization = `Bearer ${token}`;
}

export const setAuthToken = (newToken) => {
  if (!newToken) {
    localStorage.removeItem('auth_token');
    delete window.axios.defaults.headers.common.Authorization;
    return;
  }

  localStorage.setItem('auth_token', newToken);
  window.axios.defaults.headers.common.Authorization = `Bearer ${newToken}`;
};

window.axios.interceptors.response.use(
  (response) => response,
  async (error) => {
    const status = error.response?.status;
    const isLoginRequest = String(error.config?.url || '').includes('/login');

    if (status === 401 && !isLoginRequest) {
      setAuthToken(null);
      localStorage.removeItem('auth_user');
      if (router.currentRoute.value.name !== 'login') {
        await router.push({ name: 'login' });
      }
    }

    return Promise.reject(error);
  },
);
