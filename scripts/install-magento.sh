#!/usr/bin/env bash
# Installs the application code + runs Magento setup:install inside the php container.
# Uses Mage-OS (open Magento distribution) so NO Marketplace auth keys are needed.
set -euo pipefail

cd "$(dirname "$0")/.."
set -a; source .env; set +a

echo ">>> [1/3] Fetching application code into ./src (Mage-OS, no auth keys)..."
docker compose exec -T php bash -lc '
  if [ ! -f /var/www/html/composer.json ]; then
    composer create-project --no-interaction --stability=stable \
      mage-os/project-community-edition /var/www/html
  else
    echo "composer.json already present — skipping create-project"
  fi
'

echo ">>> [2/3] Running setup:install (DB + Redis + OpenSearch + RabbitMQ)..."
docker compose exec -T php bash -lc "
  cd /var/www/html && bin/magento setup:install \
    --base-url=http://${MAGENTO_DOMAIN}/ \
    --db-host=${MYSQL_HOST} --db-name=${MYSQL_DATABASE} \
    --db-user=${MYSQL_USER} --db-password=${MYSQL_PASSWORD} \
    --admin-firstname=Admin --admin-lastname=User \
    --admin-email=admin@example.com \
    --admin-user=admin --admin-password=Admin123! \
    --language=en_US --currency=USD --timezone=UTC --use-rewrites=1 \
    --search-engine=opensearch --opensearch-host=${ES_HOST} --opensearch-port=9200 \
    --session-save=redis --session-save-redis-host=${REDIS_HOST} \
    --cache-backend=redis --cache-backend-redis-server=${REDIS_HOST} --cache-backend-redis-db=1 \
    --page-cache=redis --page-cache-redis-server=${REDIS_HOST} --page-cache-redis-db=2 \
    --amqp-host=rabbitmq --amqp-port=5672 \
    --amqp-user=${RABBITMQ_DEFAULT_USER} --amqp-password=${RABBITMQ_DEFAULT_PASS}
"

echo ">>> [3/3] Fixing permissions + deploying static content..."
docker compose exec -T php bash -lc '
  cd /var/www/html
  find var pub/static pub/media app/etc generated -type f -exec chmod 664 {} \; 2>/dev/null || true
  find var pub/static pub/media app/etc generated -type d -exec chmod 775 {} \; 2>/dev/null || true
  chown -R www-data:www-data /var/www/html || true
  bin/magento setup:upgrade
  bin/magento setup:di:compile
  bin/magento setup:static-content:deploy -f
  bin/magento cache:flush
'

echo ""
echo ">>> DONE."
echo ">>> Add this line to your hosts file:   127.0.0.1  ${MAGENTO_DOMAIN}"
echo ">>> Storefront:  http://${MAGENTO_DOMAIN}/"
echo ">>> Admin:       http://${MAGENTO_DOMAIN}/admin   (admin / Admin123!)"
echo ""
echo ">>> To put Varnish in front as full-page cache (Tier 1), run afterwards:"
echo "    docker compose exec php bin/magento setup:config:set --http-cache-hosts=varnish:80"
echo "    docker compose exec php bin/magento config:set system/full_page_cache/caching_application 2"
echo "    docker compose exec php bin/magento cache:flush"
