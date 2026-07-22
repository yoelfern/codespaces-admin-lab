#!/usr/bin/env bash
set -u

echo "=== Usuario y ubicación ==="
id
pwd

echo
echo "=== Sistema operativo ==="
cat /etc/os-release

echo
echo "=== Herramientas instaladas ==="
git --version
code --version 2>/dev/null || echo "La CLI de VS Code no está disponible en el terminal."

echo
echo "=== Variables de Codespaces ==="
printf 'CODESPACES=%s\n' "${CODESPACES:-no definido}"
printf 'CODESPACE_NAME=%s\n' "${CODESPACE_NAME:-no definido}"
printf 'GITHUB_REPOSITORY=%s\n' "${GITHUB_REPOSITORY:-no definido}"
