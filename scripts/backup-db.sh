#!/usr/bin/env bash
set -Eeuo pipefail

mkdir -p backups
timestamp="$(date +%Y%m%d-%H%M%S)"
output="backups/labdb-${timestamp}.sql"

docker compose exec -T db \
  pg_dump -U "${POSTGRES_USER:-lab}" "${POSTGRES_DB:-labdb}" > "$output"

echo "Copia creada: $output"
