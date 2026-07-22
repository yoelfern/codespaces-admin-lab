FROM almalinux:9

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN dnf install -y \
        ca-certificates \
        git \
        sudo \
        shadow-utils \
    && existing_group="$(getent group ${USER_GID} | cut -d: -f1 || true)" \
    && if [ -z "${existing_group}" ]; then \
         groupadd --gid ${USER_GID} ${USERNAME}; \
         existing_group=${USERNAME}; \
       fi \
    && useradd --uid ${USER_UID} --gid ${existing_group} --create-home --shell /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && dnf clean all \
    && rm -rf /var/cache/dnf

USER ${USERNAME}
WORKDIR /workspaces
