#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

ensure_env() {
  if [ ! -f .env ]; then
    cp .env.example .env
    if command -v openssl >/dev/null 2>&1; then
      local key="base64:$(openssl rand -base64 32)"
      sed -i "s|^APP_KEY=.*|APP_KEY=${key}|" .env
    fi
    echo "Archivo .env creado desde .env.example."
  fi
}

cmd="${1:-help}"

case "$cmd" in
  up)
    ensure_env
    docker compose up -d --build
    echo "Fleetlog corriendo en http://localhost:${APP_PORT:-8080}"
    ;;
  dev)
    ensure_env
    docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
    echo "Fleetlog (modo dev) corriendo en http://localhost:${APP_PORT:-8080}"
    ;;
  down)
    docker compose down
    ;;
  logs)
    docker compose logs -f --tail=100
    ;;
  seed)
    docker compose exec app php artisan db:seed --force
    ;;
  migrate)
    docker compose exec app php artisan migrate --force
    ;;
  test)
    docker compose exec -e APP_ENV=testing -e DB_CONNECTION=sqlite -e DB_DATABASE=:memory: app php artisan test
    ;;
  shell)
    docker compose exec app bash
    ;;
  remote)
    ensure_env
    if [ ! -d node_modules ]; then
      npm install
    fi
    echo "Iniciando Vite en modo híbrido remoto (revisa VITE_API_TARGET en .env)..."
    npm run dev:remote
    ;;
  *)
    echo "Uso: ./fleetlog.sh <comando>"
    echo ""
    echo "Comandos:"
    echo "  up       Levanta el sistema completo en Docker (servidor o PC)"
    echo "  dev      Levanta Docker con montaje de carpetas PHP para desarrollo"
    echo "  down     Detiene los contenedores"
    echo "  logs     Muestra logs en vivo"
    echo "  migrate  Ejecuta migraciones pendientes"
    echo "  seed     Ejecuta seeders (admin@fleetlog.test / motorista@fleetlog.test)"
    echo "  test     Ejecuta pruebas automatizadas (PHPUnit/Pest)"
    echo "  remote   Inicia el frontend Vite en esta PC conectado a tu servidor Linux"
    ;;
esac
