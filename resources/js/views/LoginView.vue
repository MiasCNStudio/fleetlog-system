<template>
  <div class="min-h-screen flex items-center justify-center p-6">
    <div class="w-full max-w-md bg-white rounded-xl shadow p-6 space-y-4">
      <h1 class="text-2xl font-bold">Iniciar sesión</h1>
      <p class="text-sm text-slate-500">Usa tu cuenta para entrar al Dashboard.</p>

      <form class="space-y-3" @submit.prevent="submitLogin">
        <input v-model="form.email" type="email" placeholder="Correo" class="w-full rounded border p-2" required>
        <input v-model="form.password" type="password" placeholder="Contraseña" class="w-full rounded border p-2" required>
        <button :disabled="loading" class="w-full rounded bg-slate-900 text-white py-2 disabled:opacity-60">
          {{ loading ? 'Ingresando...' : 'Entrar' }}
        </button>
      </form>

      <p class="text-xs text-slate-500">Demo: admin@fleetlog.test / password</p>
    </div>
  </div>
</template>

<script setup>
import Swal from 'sweetalert2';
import { reactive, ref } from 'vue';
import { useRouter } from 'vue-router';
import { setAuthToken } from '../bootstrap';
import { setCurrentUser } from '../composables/useAuth';

const router = useRouter();
const loading = ref(false);
const form = reactive({ email: 'admin@fleetlog.test', password: 'password' });

const submitLogin = async () => {
  loading.value = true;
  try {
    const { data } = await window.axios.post('/login', form);
    setAuthToken(data.token);
    setCurrentUser(data.user);
    await router.push({ name: 'dashboard' });
  } catch (error) {
    Swal.fire({
      icon: 'error',
      title: 'No se pudo iniciar sesión',
      text: error.response?.data?.message ?? 'Valida tus credenciales.',
    });
  } finally {
    loading.value = false;
  }
};
</script>
