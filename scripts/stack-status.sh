#!/usr/bin/env bash
set -u

echo "=== Docker Compose ==="
docker compose ps
echo
echo "=== Salud HTTP ==="
curl -fsS http://127.0.0.1:8000/health || true
echo
echo "=== Uso de recursos ==="
docker stats --no-stream || true
echo
echo "=== Espacio Docker ==="
docker system df || true
