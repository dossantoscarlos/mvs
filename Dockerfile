# ============================================================
# PHP
# ============================================================
ARG PHP_VERSION=8.4-fpm
FROM php:${PHP_VERSION}

ARG APP_DIR=/var/www
ENV REDIS_LIB_VERSION=6.2.0

# ============================================================
# Dependências do Sistema
# ============================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    supervisor \
    nginx \
    curl \
    git \
    unzip \
    zip \
    nodejs \
    npm \
    zlib1g-dev \
    libzip-dev \
    libpng-dev \
    libpq-dev \
    libxml2-dev \
    libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Extensões PHP
# ============================================================
RUN docker-php-ext-install \
    mysqli \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    pgsql \
    intl \
    xml \
    bcmath \
    zip \
    gd \
    pcntl \
    opcache

RUN pecl install redis-${REDIS_LIB_VERSION} \
    && docker-php-ext-enable redis

# ============================================================
# Composer
# ============================================================
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# ============================================================
# PHP.ini
# ============================================================
RUN cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# ============================================================
# Supervisor
# ============================================================
COPY docker/supervisord/supervisord.conf /etc/supervisor/supervisord.conf
COPY docker/supervisord/conf/ /etc/supervisor/conf.d/

# ============================================================
# Nginx
# ============================================================
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/sites/ /etc/nginx/sites-available/

# ============================================================
# Aplicação
# ============================================================
WORKDIR ${APP_DIR}

COPY . .

# ============================================================
# Composer
# ============================================================
RUN composer install \
    --no-dev \
    --prefer-dist \
    --optimize-autoloader \
    --no-interaction

# ============================================================
# Frontend (Vite)
# ============================================================
RUN npm install

RUN npm run build

# ============================================================
# Diretórios Laravel
# ============================================================
RUN mkdir -p \
    storage/logs \
    storage/framework/cache/data \
    storage/framework/sessions \
    storage/framework/testing \
    storage/framework/views \
    bootstrap/cache

RUN touch storage/logs/laravel.log

RUN touch database/database.sqlite

# ============================================================
# Permissões
# ============================================================
RUN chown -R www-data:www-data \
    storage \
    bootstrap/cache \
    database

RUN chmod -R 775 \
    storage \
    bootstrap/cache \
    database

# ============================================================
# Cache Laravel
# ============================================================
RUN php artisan optimize:clear || true

# ============================================================
# Entrypoint
# ============================================================
COPY docker/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 10000

ENTRYPOINT ["/entrypoint.sh"]
