#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 backups/archivo.sql" >&2
  exit 64
fi

input="$1"
if [[ ! -f "$input" ]]; then
  echo "No existe: $input" >&2
  exit 66
fi

docker compose exec -T db \
  psql -U "${POSTGRES_USER:-lab}" "${POSTGRES_DB:-labdb}" < "$input"

echo "Restauración terminada desde: $input"
