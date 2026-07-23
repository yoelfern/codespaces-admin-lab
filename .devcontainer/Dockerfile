# Usa Ubuntu 24.04 LTS como sistema operativo base del dev container.
FROM ubuntu:24.04

# Define el nombre del usuario con el que VS Code abrirá el Codespace.
ARG USERNAME=vscode

# Define el GID preferido para el grupo del usuario.
# El Dockerfile lo usará solo si ese GID está disponible.
ARG USER_GID=1000

# Actualiza los índices, instala las herramientas básicas y prepara el
# repositorios oficiales de Cloudflare y Tailscale para instalar sus clientes.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        iputils-ping \
        python3 \
        python3-pip \
        sudo \
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
    && apt-get install -y --no-install-recommends cloudflared tailscale \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Crea el grupo vscode con GID 1000 cuando está disponible.
# Si Ubuntu ya usa ese GID, crea el grupo con el siguiente GID libre.
RUN if ! getent group "${USERNAME}" >/dev/null 2>&1; then \
        groupadd --gid "${USER_GID}" "${USERNAME}" 2>/dev/null \
        || groupadd "${USERNAME}"; \
    fi \
    && if ! id -u "${USERNAME}" >/dev/null 2>&1; then \
        useradd --gid "${USERNAME}" --create-home --shell /bin/bash "${USERNAME}"; \
    fi \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
    && chmod 0440 "/etc/sudoers.d/${USERNAME}"

# Cambia al usuario no-root para que la terminal y las extensiones de VS Code
# no trabajen permanentemente con privilegios de administrador.
USER ${USERNAME}

# Define el directorio de trabajo habitual de GitHub Codespaces.
WORKDIR /workspaces
