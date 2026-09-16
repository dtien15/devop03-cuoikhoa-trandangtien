#!/usr/bin/env bash
# Kiem tra nhanh he thong sau khi chay `docker compose up -d`
# Dung cho moi truong dev (localhost).
set -uo pipefail

FE=${FE:-http://localhost:3000}
BE=${BE:-http://localhost:8000}
GRAFANA=${GRAFANA:-http://localhost:3001}
PROM=${PROM:-http://localhost:9090}

pass=0; fail=0
check() {
  local name="$1" url="$2" want="${3:-200}"
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" || echo 000)
  if [ "$code" = "$want" ]; then
    echo "  [OK]   $name -> $code"; pass=$((pass+1))
  else
    echo "  [FAIL] $name -> $code (mong doi $want)"; fail=$((fail+1))
  fi
}

echo "== Ung dung =="
check "Frontend"          "$FE/"
check "Frontend healthz"  "$FE/healthz"
check "Backend health"    "$BE/health"
check "Backend metrics"   "$BE/metrics"
check "API qua nginx"     "$FE/api/task/getTask" 401   # chua login -> 401 la dung

echo "== Giam sat (neu da bat) =="
check "Prometheus ready"  "$PROM/-/ready"
check "Grafana health"    "$GRAFANA/api/health"

echo
echo "Ket qua: $pass dat / $fail loi"
[ "$fail" -eq 0 ]
