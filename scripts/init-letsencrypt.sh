#!/usr/bin/env bash
# ============================================================
#  Xin chung chi HTTPS lan dau (chay TREN VPS, trong /opt/todo-app)
#  Dung khi khong muon chay qua Ansible role ssl.
#  DIEU KIEN: 3 ban ghi A da tro ve IP cua VPS.
# ============================================================
set -euo pipefail

cd "$(dirname "$0")/.."
source .env

EMAIL="${LETSENCRYPT_EMAIL:-support@dgmasia.vn}"
COMPOSE="docker compose -f docker-compose.prod.yml"

echo "==> Domain: $DOMAIN, $GRAFANA_DOMAIN, $JENKINS_DOMAIN"

echo "==> Tao chung chi tam de nginx khoi dong duoc"
$COMPOSE run --rm --entrypoint "sh -c '
  mkdir -p /etc/letsencrypt/live/$DOMAIN &&
  openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
    -keyout /etc/letsencrypt/live/$DOMAIN/privkey.pem \
    -out  /etc/letsencrypt/live/$DOMAIN/fullchain.pem \
    -subj /CN=localhost'" certbot

echo "==> Khoi dong nginx"
$COMPOSE up -d --force-recreate proxy
sleep 5

echo "==> Xoa chung chi tam"
$COMPOSE run --rm --entrypoint "rm -rf \
  /etc/letsencrypt/live/$DOMAIN \
  /etc/letsencrypt/archive/$DOMAIN \
  /etc/letsencrypt/renewal/$DOMAIN.conf" certbot

echo "==> Xin chung chi that tu Let's Encrypt"
$COMPOSE run --rm --entrypoint "certbot certonly --webroot -w /var/www/certbot \
  --email $EMAIL --agree-tos --no-eff-email --non-interactive \
  --cert-name $DOMAIN \
  -d $DOMAIN -d $GRAFANA_DOMAIN -d $JENKINS_DOMAIN" certbot

echo "==> Nap lai nginx"
$COMPOSE exec proxy nginx -s reload

echo "==> Xong. Kiem tra: https://$DOMAIN"
