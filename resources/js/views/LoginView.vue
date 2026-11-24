<template>
  <div class="relative flex min-h-screen items-center justify-center overflow-hidden bg-gradient-to-br from-[#193978] via-[#163168] to-[#0f234d] px-4 pb-6 pt-16 font-outfit text-gray-900 dark:from-[#080d1a] dark:via-[#0d1730] dark:to-[#070b15] sm:p-6">
    <!-- Ambient corner glows -->
    <div
      class="pointer-events-none absolute -left-24 -top-24 size-96 rounded-full bg-sky-400/15 blur-3xl"
      aria-hidden="true"
    />
    <div
      class="pointer-events-none absolute -bottom-24 -right-24 size-96 rounded-full bg-emerald-400/15 blur-3xl"
      aria-hidden="true"
    />

    <!-- Theme toggle -->
    <div class="absolute right-4 top-4 z-20 sm:right-6 sm:top-6">
      <button
        type="button"
        class="inline-flex size-10 items-center justify-center rounded-xl border border-white/15 bg-white/10 text-white backdrop-blur-md transition-colors hover:bg-white/20 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/40"
        :aria-label="isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro'"
        :title="isDark ? 'Modo claro' : 'Modo oscuro'"
        @click="toggleDark()"
      >
        <svg v-if="isDark" class="size-4 text-amber-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 3v2.25m6.364.386l-1.591 1.591M21 12h-2.25m-.386 6.364l-1.591-1.591M12 18.75V21m-4.773-4.227l-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0z" />
        </svg>
        <svg v-else class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" d="M21.752 15.002A9.718 9.718 0 0118 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 003 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 009.002-5.998z" />
        </svg>
      </button>
    </div>

    <!-- Split Card -->
    <div class="relative z-10 grid w-full max-w-[880px] overflow-hidden rounded-[24px] border border-white/10 bg-[#f8fafc] shadow-[0_28px_70px_-15px_rgba(4,12,32,0.65)] dark:bg-[#111827] md:grid-cols-2">
      <!-- Left Showcase Panel -->
      <div class="relative flex flex-col items-center justify-center overflow-hidden bg-gradient-to-br from-[#1d3e7e] to-[#152d60] px-6 py-8 text-white dark:from-[#0f1d3d] dark:to-[#0a1329] md:px-8 md:py-12">
        <!-- Decorative floating dots -->
        <span class="pointer-events-none absolute left-7 top-16 size-3.5 rounded-full bg-amber-300/20" aria-hidden="true" />
        <span class="pointer-events-none absolute bottom-16 left-12 size-2 rounded-full bg-sky-300/30" aria-hidden="true" />
        <span class="pointer-events-none absolute bottom-12 right-6 size-4 rounded-full bg-emerald-400/25" aria-hidden="true" />

        <div class="relative flex w-full max-w-[290px] flex-col items-center rounded-2xl border border-white/[0.07] bg-[#122650]/95 px-6 py-8 text-center shadow-[0_20px_45px_rgba(5,12,32,0.5)] dark:bg-[#0b152c]/95 md:py-10">
          <img
            :src="miascnLogo"
            alt="Logo de MiasCN Studio"
            class="size-24 object-contain drop-shadow-[0_6px_18px_rgba(14,165,233,0.35)] md:size-28"
          />

          <h2 class="mt-4 text-xl font-bold tracking-tight text-white">
            MiasCN Studio
          </h2>
          <p class="mt-1 text-theme-xs font-medium tracking-wide text-sky-300/90">
            FLEETLOG SYSTEM
          </p>

          <div class="mt-4 inline-flex items-center gap-1.5 rounded-full border border-white/10 bg-white/[0.05] px-3 py-1 text-[11px] font-medium text-slate-300">
            <span class="size-1.5 rounded-full bg-emerald-400" aria-hidden="true" />
            Control operativo de flotilla
          </div>
        </div>
      </div>

      <!-- Right Form Panel -->
      <div class="flex flex-col justify-center bg-[#f8fafc] px-6 py-8 dark:bg-[#111827] sm:px-10 md:py-12">
        <div class="mb-6">
          <h1 class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
            Iniciar sesión
          </h1>
          <p class="mt-1 text-theme-xs text-gray-500 dark:text-gray-400">
            Usa tu correo y contraseña para continuar.
          </p>
        </div>

        <form class="space-y-4" @submit.prevent="submitLogin">
          <div>
            <label for="login-email" class="mb-1.5 block text-theme-xs font-medium text-gray-700 dark:text-gray-300">
              Correo electrónico
            </label>
            <div class="relative">
              <span class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-4 text-sky-500" aria-hidden="true">
                <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
                </svg>
              </span>
              <input
                id="login-email"
                v-model="form.email"
                type="email"
                autocomplete="email"
                placeholder="correo@empresa.com"
                class="h-11 w-full rounded-full border border-gray-200 bg-white pl-11 pr-4 text-theme-sm text-gray-900 shadow-theme-xs transition-colors placeholder:text-gray-400 focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20 dark:border-white/10 dark:bg-[#0b1220] dark:text-gray-100 dark:placeholder:text-gray-500"
                required
              />
            </div>
          </div>

          <div>
            <label for="login-password" class="mb-1.5 block text-theme-xs font-medium text-gray-700 dark:text-gray-300">
              Contraseña
            </label>
            <div class="relative">
              <span class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-4 text-amber-500" aria-hidden="true">
                <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z" />
                </svg>
              </span>
              <input
                id="login-password"
                v-model="form.password"
                :type="showPassword ? 'text' : 'password'"
                autocomplete="current-password"
                placeholder="••••••••"
                class="h-11 w-full rounded-full border border-gray-200 bg-white pl-11 pr-11 text-theme-sm text-gray-900 shadow-theme-xs transition-colors placeholder:text-gray-400 focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20 dark:border-white/10 dark:bg-[#0b1220] dark:text-gray-100 dark:placeholder:text-gray-500"
                required
              />
              <button
                type="button"
                class="absolute inset-y-0 right-0 flex items-center pr-4 text-gray-400 transition-colors hover:text-gray-700 focus-visible:outline-none focus-visible:text-brand-500 dark:hover:text-gray-200"
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

          <div class="flex items-center justify-between pt-0.5">
            <label class="inline-flex cursor-pointer items-center gap-2 text-theme-xs text-gray-600 dark:text-gray-300">
              <input
                v-model="rememberMe"
                type="checkbox"
                class="size-4 rounded border-gray-300 text-emerald-500 focus:ring-emerald-500 dark:border-gray-600 dark:bg-[#0b1220]"
              />
              Recordarme
            </label>
          </div>

          <button
            type="submit"
            :disabled="loading"
            class="inline-flex h-11 w-full items-center justify-center gap-2 rounded-full bg-[#22c55e] px-6 text-theme-xs font-bold uppercase tracking-wider text-white shadow-[0_8px_20px_-4px_rgba(34,197,94,0.55)] transition-all hover:bg-[#16a34a] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-400 focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-60 dark:focus-visible:ring-offset-[#111827]"
          >
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
            <span>{{ loading ? 'Ingresando...' : 'Ingresar al sistema' }}</span>
          </button>
        </form>

        <div class="mt-6 flex flex-col gap-2 border-t border-gray-200/80 pt-4 text-[11px] text-gray-500 dark:border-white/[0.07] dark:text-gray-400">
          <p>
            <span class="font-semibold text-gray-700 dark:text-gray-300">Demo:</span>
            admin@fleetlog.test / password
          </p>
          <p class="text-gray-400 dark:text-gray-500">
            Desarrollado por <span class="font-semibold text-gray-600 dark:text-gray-300">MiasCN Studio</span>
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useDark, useToggle } from '@vueuse/core';
import miascnLogo from '../assets/miascn-studio-logo.png';
import { setAuthToken } from '../bootstrap';
import { setCurrentUser } from '../composables/useAuth';
import { showErrorAlert } from '../utils/alerts';

const REMEMBER_EMAIL_KEY = 'fleetlog_remember_email';

const router = useRouter();
const isDark = useDark();
const toggleDark = useToggle(isDark);

const savedEmail = localStorage.getItem(REMEMBER_EMAIL_KEY);
const loading = ref(false);
const showPassword = ref(false);
const rememberMe = ref(Boolean(savedEmail));
const form = reactive({
  email: savedEmail || 'admin@fleetlog.test',
  password: 'password',
});

const submitLogin = async () => {
  loading.value = true;
  try {
    if (rememberMe.value && form.email) {
      localStorage.setItem(REMEMBER_EMAIL_KEY, form.email);
    } else {
      localStorage.removeItem(REMEMBER_EMAIL_KEY);
    }

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
