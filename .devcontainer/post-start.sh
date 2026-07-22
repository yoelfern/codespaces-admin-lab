#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
mkdir -p .lab-state

echo "postStartCommand=$(date --iso-8601=seconds)" >> .lab-state/lifecycle.log

echo "Esperando al daemon Docker interno..."
for attempt in $(seq 1 60); do
  if docker info >/dev/null 2>&1; then
    echo "Docker está disponible."
    break
  fi
  if [[ "$attempt" -eq 60 ]]; then
    echo "Docker no respondió. Ejecuta bash .devcontainer/diagnose.sh" >&2
    exit 1
  fi
  sleep 1
done

if [[ "${AUTO_START_STACK:-false}" == "true" ]]; then
  echo "AUTO_START_STACK=true: iniciando Docker Compose."
  docker compose up -d
else
  echo "AUTO_START_STACK=false: el stack no se inicia automáticamente."
fi
