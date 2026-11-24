<template>
  <div class="relative flex min-h-screen flex-col justify-center overflow-hidden bg-[#f4f6fb] px-4 py-10 font-outfit text-gray-900 dark:bg-[#090e1a] dark:text-gray-100 sm:px-6">
    <div
      class="pointer-events-none absolute inset-x-0 top-0 h-80 bg-[radial-gradient(ellipse_at_top,_rgba(70,95,255,0.14),_transparent_70%)] dark:bg-[radial-gradient(ellipse_at_top,_rgba(70,95,255,0.22),_transparent_70%)]"
      aria-hidden="true"
    />

    <div class="absolute right-4 top-4 z-10 sm:right-6 sm:top-6">
      <button
        type="button"
        class="inline-flex size-10 items-center justify-center rounded-xl border border-gray-200 bg-white text-gray-600 shadow-theme-xs transition-colors hover:bg-gray-50 hover:text-gray-900 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/40 dark:border-white/10 dark:bg-[#111827] dark:text-gray-300 dark:hover:bg-white/[0.08] dark:hover:text-white"
        :aria-label="isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro'"
        :title="isDark ? 'Modo claro' : 'Modo oscuro'"
        @click="toggleDark()"
      >
        <svg v-if="isDark" class="size-4 text-amber-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 3v2.25m6.364.386l-1.591 1.591M21 12h-2.25m-.386 6.364l-1.591-1.591M12 18.75V21m-4.773-4.227l-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0z" />
        </svg>
        <svg v-else class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" d="M21.752 15.002A9.718 9.718 0 0118 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 003 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 009.002-5.998z" />
        </svg>
      </button>
    </div>

    <div class="relative z-10 mx-auto w-full max-w-md">
      <div class="mb-6 flex flex-col items-center text-center">
        <div class="mb-3 flex size-12 items-center justify-center rounded-2xl bg-gradient-to-br from-brand-400 to-brand-600 text-lg font-bold text-white shadow-[0_4px_16px_rgba(70,95,255,0.4)] ring-4 ring-brand-500/15">
          F
        </div>
        <h1 class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
          Fleetlog
        </h1>
        <p class="mt-1 text-theme-sm text-gray-500 dark:text-gray-400">
          Control operativo de flotilla vehicular
        </p>
      </div>

      <div class="fleet-card p-6 sm:p-8">
        <div class="mb-5">
          <h2 class="text-lg font-semibold text-gray-900 dark:text-white">Iniciar sesión</h2>
          <p class="mt-1 text-theme-sm text-gray-500 dark:text-gray-400">
            Ingresa tus credenciales para acceder al panel.
          </p>
        </div>

        <form class="space-y-4" @submit.prevent="submitLogin">
          <div>
            <label for="login-email" class="fleet-field-label">Correo electrónico</label>
            <input
              id="login-email"
              v-model="form.email"
              type="email"
              autocomplete="email"
              placeholder="correo@empresa.com"
              class="fleet-input"
              required
            />
          </div>

          <div>
            <label for="login-password" class="fleet-field-label">Contraseña</label>
            <div class="relative">
              <input
                id="login-password"
                v-model="form.password"
                :type="showPassword ? 'text' : 'password'"
                autocomplete="current-password"
                placeholder="••••••••"
                class="fleet-input pr-11"
                required
              />
              <button
                type="button"
                class="absolute inset-y-0 right-0 flex items-center px-3 text-gray-400 transition-colors hover:text-gray-700 focus-visible:outline-none focus-visible:text-brand-500 dark:hover:text-gray-200"
                :aria-label="showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'"
                @click="showPassword = !showPassword"
              >
                <svg v-if="showPassword" class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M3.98 8.223A10.477 10.477 0 001.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.45 10.45 0 0112 4.5c4.756 0 8.773 3.162 10.065 7.498a10.523 10.523 0 01-4.293 5.774M6.228 6.228L3 3m3.228 3.228l3.65 3.65m7.894 7.894L21 21m-3.228-3.228l-3.65-3.65m0 0a3 3 0 10-4.243-4.243m4.242 4.242L9.88 9.88" />
                </svg>
                <svg v-else class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" />
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </button>
            </div>
          </div>

          <button type="submit" :disabled="loading" class="fleet-btn-primary w-full">
            <svg
              v-if="loading"
              class="size-4 animate-spin"
              fill="none"
              viewBox="0 0 24 24"
              aria-hidden="true"
            >
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
            </svg>
            <span>{{ loading ? 'Ingresando...' : 'Entrar al sistema' }}</span>
          </button>
        </form>

        <div class="mt-5 rounded-xl border border-gray-200/80 bg-gray-50 px-3.5 py-2.5 text-theme-xs text-gray-600 dark:border-white/[0.07] dark:bg-white/[0.03] dark:text-gray-400">
          <span class="font-medium text-gray-800 dark:text-gray-200">Demo:</span>
          admin@fleetlog.test / password
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useDark, useToggle } from '@vueuse/core';
import { setAuthToken } from '../bootstrap';
import { setCurrentUser } from '../composables/useAuth';
import { showErrorAlert } from '../utils/alerts';

const router = useRouter();
const isDark = useDark();
const toggleDark = useToggle(isDark);

const loading = ref(false);
const showPassword = ref(false);
const form = reactive({ email: 'admin@fleetlog.test', password: 'password' });

const submitLogin = async () => {
  loading.value = true;
  try {
    const { data } = await window.axios.post('/login', form);
    setAuthToken(data.token);
    setCurrentUser(data.user);
    await router.push({ name: 'dashboard' });
  } catch (error) {
    showErrorAlert(
      'No se pudo iniciar sesión',
      error.response?.data?.message ?? 'Valida tus credenciales.',
    );
  } finally {
    loading.value = false;
  }
};
</script>
