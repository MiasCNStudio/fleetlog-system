#!/usr/bin/env bash
set -e

cd /var/www/html

if [ ! -f .env ] && [ -f .env.example ]; then
    cp .env.example .env
fi

mkdir -p storage/app/public storage/framework/sessions storage/framework/views storage/framework/cache storage/logs bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

if [ "${DB_CONNECTION:-mysql}" = "mysql" ]; then
    echo "Esperando a MySQL en ${DB_HOST:-db}:${DB_PORT:-3306}..."
    for i in $(seq 1 30); do
        if php -r "new PDO('mysql:host=' . (getenv('DB_HOST') ?: 'db') . ';port=' . (getenv('DB_PORT') ?: '3306') . ';dbname=' . (getenv('DB_DATABASE') ?: 'fleetlog_system'), getenv('DB_USERNAME') ?: 'fleetlog', getenv('DB_PASSWORD') ?: '');" 2>/dev/null; then
            echo "MySQL listo."
            break
        fi
        sleep 2
    done
fi

if [ -z "${APP_KEY:-}" ] && grep -q '^APP_KEY=$' .env 2>/dev/null; then
    php artisan key:generate --force
fi

if [ ! -L public/storage ]; then
    php artisan storage:link || true
fi

php artisan migrate --force

if [ "${AUTO_SEED:-false}" = "true" ]; then
    php artisan db:seed --force
fi

if [ "${APP_ENV:-production}" = "production" ]; then
    php artisan optimize
fi

exec /usr/bin/supervisord -c /etc/supervisord.conf
