import { defineConfig, loadEnv } from 'vite';
import laravel from 'laravel-vite-plugin';
import vue from '@vitejs/plugin-vue';
import { fileURLToPath, URL } from 'node:url';

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const backendUrl = env.APP_URL || 'http://127.0.0.1';
  /** Con APP_URL https y certificado autofirmado (Laragon), el proxy acepta el cert por defecto. Use VITE_DEV_PROXY_TLS_STRICT=1 para validar SSL. */
  const httpsTarget = backendUrl.startsWith('https://');
  const proxyVerifyTls = env.VITE_DEV_PROXY_TLS_STRICT === '1';

  return {
    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./resources/js', import.meta.url)),
      },
    },
    plugins: [
      laravel({
        input: ['resources/css/app.css', 'resources/js/app.js'],
        refresh: true,
      }),
      vue(),
    ],
    server: {
      proxy: {
        '/api': {
          target: backendUrl,
          changeOrigin: true,
          secure: httpsTarget ? proxyVerifyTls : true,
        },
      },
    },
  };
});
