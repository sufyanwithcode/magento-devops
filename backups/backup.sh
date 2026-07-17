#!/usr/bin/env bash
# Dumps the Magento MySQL database + media into backups/dumps/
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; source .env; set +a

STAMP=$(date +%F_%H-%M-%S)
OUT="backups/dumps"
mkdir -p "$OUT"

echo ">>> Dumping database '${MYSQL_DATABASE}'..."
docker compose exec -T mysql \
  mysqldump -u root -p"${MYSQL_ROOT_PASSWORD}" \
  --single-transaction --quick --no-tablespaces "${MYSQL_DATABASE}" \
  | gzip > "${OUT}/db_${STAMP}.sql.gz"

echo ">>> Archiving media..."
docker compose exec -T php tar -czf - -C /var/www/html/pub media \
  > "${OUT}/media_${STAMP}.tar.gz" 2>/dev/null || echo "   (no media yet — skipped)"

echo ">>> Backup written to ${OUT}/db_${STAMP}.sql.gz"
