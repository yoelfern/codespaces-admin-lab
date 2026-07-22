#!/usr/bin/env bash
set -u

section() {
  printf '\n===== %s =====\n' "$1"
}

section "Identidad"
id
hostname
pwd

section "Sistema"
uname -a
cat /etc/os-release

section "Codespaces"
printf 'CODESPACE_NAME=%s\n' "${CODESPACE_NAME:-no-definido}"
printf 'GITHUB_REPOSITORY=%s\n' "${GITHUB_REPOSITORY:-no-definido}"
command -v devcontainer-info >/dev/null && devcontainer-info || true

section "Montajes y almacenamiento"
findmnt /workspaces 2>/dev/null || true
df -h
mount | grep -E '/workspaces|docker' || true

section "Red"
ip -brief address
ip route
getent hosts github.com || true

section "Docker"
docker version || true
docker info || true
docker ps -a || true
docker images || true
docker system df || true

section "KVM"
ls -l /dev/kvm 2>/dev/null || echo "/dev/kvm no está disponible"

section "Procesos principales"
ps -ef | head -n 30
