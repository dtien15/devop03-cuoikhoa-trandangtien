#!/usr/bin/env bash
# Sinh nhanh cac chuoi bi mat manh cho .env / vault.yml
set -euo pipefail
gen() { openssl rand -base64 36 | tr -d '\n/+=' | cut -c1-40; }
cat <<OUT
JWT_SECRET=$(gen)
MONGO_ROOT_PASSWORD=$(gen)
GRAFANA_ADMIN_PASSWORD=$(gen)
OUT
