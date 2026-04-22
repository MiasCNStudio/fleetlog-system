import axios from 'axios';

const token = localStorage.getItem('auth_token');

window.axios = axios;
window.axios.defaults.baseURL = '/api';
window.axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';

if (token) {
  window.axios.defaults.headers.common.Authorization = `Bearer ${token}`;
}

export const setAuthToken = (token) => {
  if (!token) {
    localStorage.removeItem('auth_token');
    delete window.axios.defaults.headers.common.Authorization;
    return;
  }

  localStorage.setItem('auth_token', token);
  window.axios.defaults.headers.common.Authorization = `Bearer ${token}`;
};
