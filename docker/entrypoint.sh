#!/bin/sh

set -e

echo "Iniciando aplicação..."

# Aguarda banco caso exista configuração
if [ ! -z "$DB_HOST" ]; then
    echo "Aguardando banco..."

    until php -r "
    try {
        new PDO(
            'mysql:host=' . getenv('DB_HOST') .
            ';port=' . getenv('DB_PORT'),
            getenv('DB_USERNAME'),
            getenv('DB_PASSWORD')
        );
        exit(0);
    } catch (Exception \$e) {
        exit(1);
    }"
    do
        sleep 2
    done
fi

echo "Limpando caches..."

php artisan optimize:clear || true

echo "Gerando caches..."

php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

echo "Executando migrations..."

php artisan migrate --force || true

echo "Executando seed..."

php artisan db:seed --force || true

echo "Iniciando Supervisor..."

exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
