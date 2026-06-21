#!/bin/sh

set -e

echo "Corrigindo permissões..."

chown -R www-data:www-data /var/www/storage
chown -R www-data:www-data /var/www/bootstrap/cache

chmod -R 775 /var/www/storage
chmod -R 775 /var/www/bootstrap/cache

echo "Limpando cache..."

php artisan optimize:clear || true

echo "Gerando cache..."

php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

echo "Executando migrations..."

php artisan migrate --force || true

echo "Executando seed..."

php artisan db:seed --force || true

echo "Iniciando Supervisor..."

exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
