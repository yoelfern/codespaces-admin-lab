#!/usr/bin/env bash

# No detiene la creación del Codespace si Tailscale no puede iniciar.
set -u

# Define la ubicación persistente del estado de Tailscale.
state_dir="/var/lib/tailscale"

# Define el socket local mediante el que tailscale habla con tailscaled.
socket_path="/var/run/tailscale/tailscaled.sock"

# Si el daemon ya está ejecutándose, no crea una segunda instancia.
if sudo pgrep -x tailscaled >/dev/null 2>&1; then
  echo "tailscaled ya está ejecutándose."
  exit 0
fi

# Crea las carpetas necesarias con permisos de administrador.
sudo mkdir -p "${state_dir}" "$(dirname "${socket_path}")"

# Inicia Tailscale en modo userspace, adecuado para contenedores que no tienen
# systemd o que no exponen el dispositivo /dev/net/tun.
sudo tailscaled \
  --state="${state_dir}/tailscaled.state" \
  --socket="${socket_path}" \
  --tun=userspace-networking \
  >/tmp/tailscaled.log 2>&1 &

# Espera brevemente a que el socket local quede disponible.
for attempt in $(seq 1 15); do
  if sudo tailscale --socket="${socket_path}" version >/dev/null 2>&1; then
    echo "tailscaled está disponible."
    exit 0
  fi
  sleep 1
done

# Informa dónde revisar el diagnóstico, pero no rompe el arranque del Codespace.
echo "tailscaled no respondió; revisa /tmp/tailscaled.log." >&2
exit 0
