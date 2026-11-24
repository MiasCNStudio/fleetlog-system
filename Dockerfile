FROM node:22-alpine AS frontend
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY resources ./resources
COPY vite.config.js tailwind.config.js postcss.config.js ./
RUN npm run build

FROM php:8.3-fpm-alpine AS app

RUN apk add --no-cache \
    bash \
    curl \
    freetype-dev \
    icu-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libzip-dev \
    nginx \
    oniguruma-dev \
    sqlite \
    sqlite-dev \
    supervisor \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        bcmath \
        exif \
        gd \
        intl \
        mbstring \
        pcntl \
        pdo_mysql \
        pdo_sqlite \
        zip

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN { \
        echo "upload_max_filesize=16M"; \
        echo "post_max_size=20M"; \
        echo "memory_limit=256M"; \
    } > /usr/local/etc/php/conf.d/uploads.ini \
    && echo "clear_env = no" >> /usr/local/etc/php-fpm.d/www.conf

WORKDIR /var/www/html

COPY composer.json composer.lock ./
RUN composer install --no-interaction --prefer-dist --optimize-autoloader --no-scripts

COPY . .
COPY --from=frontend /app/public/build ./public/build

RUN composer dump-autoload --optimize \
    && mkdir -p storage/framework/sessions storage/framework/views storage/framework/cache storage/app/public storage/logs bootstrap/cache /run/nginx \
    && chown -R www-data:www-data storage bootstrap/cache

COPY docker/nginx/default.conf /etc/nginx/http.d/default.conf
COPY docker/supervisor/supervisord.conf /etc/supervisord.conf
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
