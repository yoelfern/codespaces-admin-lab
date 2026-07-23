# Usa la imagen oficial de Dev Containers basada en Ubuntu 24.04 LTS.
# Esta imagen ya incluye la integración esperada por VS Code y Codespaces,
# además del usuario no-root vscode.
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# Cambia temporalmente a root para instalar paquetes del sistema.
USER root

# Instala herramientas básicas, agrega los repositorios oficiales de Cloudflare
# y Tailscale, e instala ambos clientes.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        iputils-ping \
        python3 \
        python3-pip \
    && install -d -m 0755 /usr/share/keyrings \
    && curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg \
        -o /usr/share/keyrings/cloudflare-main.gpg \
    && printf '%s\n' \
        'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' \
        > /etc/apt/sources.list.d/cloudflared.list \
    && curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg \
        -o /usr/share/keyrings/tailscale-archive-keyring.gpg \
    && curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list \
        -o /etc/apt/sources.list.d/tailscale.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        cloudflared \
        tailscale \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Vuelve al usuario estándar incluido en la imagen oficial.
USER vscode

# Define el directorio de trabajo utilizado por GitHub Codespaces.
WORKDIR /workspaces
