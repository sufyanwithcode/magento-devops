#!/usr/bin/env bash
# Restores a gzipped SQL dump:  ./backups/restore.sh backups/dumps/db_XXXX.sql.gz
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; source .env; set +a

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <path-to-db_dump.sql.gz>"
  exit 1
fi

echo ">>> Restoring '$1' into database '${MYSQL_DATABASE}'..."
gunzip -c "$1" | docker compose exec -T mysql \
  mysql -u root -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}"

echo ">>> Restore complete. Flushing Magento cache..."
docker compose exec -T php bash -lc 'cd /var/www/html && bin/magento cache:flush' || true
