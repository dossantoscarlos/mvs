# ============================================================
# Imagem Base
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
    nodejs \
    npm \
    curl \
    unzip \
    git \
    zlib1g-dev \
    libzip-dev \
    libpng-dev \
    libpq-dev \
    libxml2-dev \
    libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Supervisor
# ============================================================
COPY ./docker/supervisord/supervisord.conf /etc/supervisor/
COPY ./docker/supervisord/conf /etc/supervisor/conf.d/

# ============================================================
# Extensões PHP
# ============================================================
RUN docker-php-ext-install \
    mysqli \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    pgsql \
    session \
    xml \
    intl \
    bcmath \
    zip \
    iconv \
    simplexml \
    pcntl \
    gd \
    fileinfo

# Redis
RUN pecl install redis-${REDIS_LIB_VERSION} \
    && docker-php-ext-enable redis

# ============================================================
# Composer
# ============================================================
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# ============================================================
# PHP
# ============================================================
RUN cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# ============================================================
# Diretório da aplicação
# ============================================================
WORKDIR ${APP_DIR}

COPY . .

# ============================================================
# Instala dependências Laravel
# ============================================================
RUN composer install \
    --no-dev \
    --prefer-dist \
    --no-interaction \
    --optimize-autoloader

# ============================================================
# Permissões
# ============================================================
RUN mkdir -p storage/framework/cache/data \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache

RUN touch database/database.sqlite

RUN chown -R www-data:www-data ${APP_DIR}

RUN chmod -R 775 \
    storage \
    bootstrap/cache \
    database

# ============================================================
# Nginx
# ============================================================
COPY ./docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./docker/nginx/sites /etc/nginx/sites-available

# ============================================================
# Entrypoint
# ============================================================
COPY ./docker/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 10000

ENTRYPOINT ["/entrypoint.sh"]
