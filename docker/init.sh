#!/bin/bash
set -e

# Generate app key kalau belum ada
if ! grep -qE "^APP_KEY=base64:" .env; then
    php artisan key:generate --force
fi

# Pastikan folder log ada
LOG="storage/logs/deploy/$(date +"%Y/%m")/$(date +"%Y-%m-%d").log"
install -d "$(dirname "$LOG")"

# Jalankan composer deploy script (jika ada)
if [ -f "./composer.json" ]; then
    COMPOSER_ALLOW_SUPERUSER=1 ./composer deploy-docker >> "$LOG" 2>&1 || true
fi

# Pastikan permission storage dan cache
chmod -R 775 storage bootstrap/cache || true

# Jalankan cron
crontab /etc/cron.d/crontab
cron

# Jalankan Laravel di port Railway ($PORT)
APP_PORT=${PORT:-8000}
echo "Starting Laravel at port ${APP_PORT}..." | tee -a "$LOG"

php artisan optimize --quiet

# Loop untuk jaga proses tetap hidup
while true; do
    LOG="storage/logs/serve/$(date +"%Y/%m")/$(date +"%Y-%m-%d").log"
    install -d "$(dirname "$LOG")"
    php artisan serve --host=0.0.0.0 --port="${APP_PORT}" --no-reload >> "$LOG" 2>&1
done
