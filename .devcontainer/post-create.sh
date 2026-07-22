#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

mkdir -p .lab-state backups

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Se creó .env a partir de .env.example."
fi

chmod +x .devcontainer/*.sh scripts/*.sh 2>/dev/null || true

{
  echo "postCreateCommand=$(date --iso-8601=seconds)"
  echo "user=$(id -un)"
  echo "host=$(hostname)"
} >> .lab-state/lifecycle.log

echo "Configuración inicial completada."
echo "Ejecuta: bash .devcontainer/diagnose.sh"
