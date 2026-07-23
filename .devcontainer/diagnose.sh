#!/usr/bin/env bash

# Hace que el script continúe aunque una herramienta opcional no esté disponible.
set -u

# Muestra el usuario y el grupo efectivos dentro del Codespace.
echo "=== Usuario ==="
id

# Muestra la carpeta actual desde la que se ejecuta el script.
echo "=== Ubicación ==="
pwd

# Muestra la distribución y la versión del sistema operativo.
echo "=== Sistema operativo ==="
cat /etc/os-release

# Muestra las versiones de las herramientas instaladas por el Dockerfile.
echo "=== Herramientas básicas ==="
git --version
python3 --version
pip3 --version
curl --version | head -n 1
ping -V 2>&1 | head -n 1
cloudflared --version
tailscale version

# Muestra las herramientas proporcionadas por la Feature de Docker.
echo "=== Features ==="
docker --version

# Comprueba si el daemon interno de Docker está respondiendo.
echo "=== Docker ==="
if docker info >/dev/null 2>&1; then
  echo "El daemon Docker está disponible."
else
  echo "El daemon Docker todavía no responde."
fi

# Muestra variables que GitHub Codespaces puede proporcionar automáticamente.
echo "=== Codespaces ==="
printf 'CODESPACES=%s\n' "${CODESPACES:-no definido}"
printf 'CODESPACE_NAME=%s\n' "${CODESPACE_NAME:-no definido}"
printf 'GITHUB_REPOSITORY=%s\n' "${GITHUB_REPOSITORY:-no definido}"
