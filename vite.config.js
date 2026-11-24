import { defineConfig, loadEnv } from 'vite';
import laravel from 'laravel-vite-plugin';
import vue from '@vitejs/plugin-vue';
import { fileURLToPath, URL } from 'node:url';

function remoteSpaPlugin() {
  return {
    name: 'fleetlog-remote-spa',
    configureServer(server) {
      server.middlewares.use(async (req, res, next) => {
        const url = req.url || '/';
        const isInternal =
          url.startsWith('/api') ||
          url.startsWith('/storage') ||
          url.startsWith('/@') ||
          url.startsWith('/resources') ||
          url.startsWith('/node_modules') ||
          url.includes('.');

        if (req.method !== 'GET' || isInternal) {
          return next();
        }

        const rawHtml = `<!doctype html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Fleetlog (Modo Híbrido)</title>
  <script type="module" src="/resources/js/app.js"></script>
  <link rel="stylesheet" href="/resources/css/app.css">
</head>
<body class="bg-slate-50 text-gray-900 antialiased dark:bg-gray-950 dark:text-gray-100">
  <div id="app"></div>
</body>
</html>`;

        const html = await server.transformIndexHtml(url, rawHtml);
        res.statusCode = 200;
        res.setHeader('Content-Type', 'text/html');
        res.end(html);
      });
    },
  };
}

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const isRemote = mode === 'remote';
  const backendUrl = env.VITE_API_TARGET || env.APP_URL || 'http://127.0.0.1:8080';
  const httpsTarget = backendUrl.startsWith('https://');
  const proxyVerifyTls = env.VITE_DEV_PROXY_TLS_STRICT === '1';

  const proxyConfig = {
    target: backendUrl,
    changeOrigin: true,
    secure: httpsTarget ? proxyVerifyTls : true,
  };

  return {
    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./resources/js', import.meta.url)),
      },
    },
    plugins: [
      ...(isRemote
        ? [remoteSpaPlugin()]
        : [
            laravel({
              input: ['resources/css/app.css', 'resources/js/app.js'],
              refresh: true,
            }),
          ]),
      vue(),
    ],
    server: {
      proxy: {
        '/api': proxyConfig,
        '/storage': proxyConfig,
      },
    },
  };
});
