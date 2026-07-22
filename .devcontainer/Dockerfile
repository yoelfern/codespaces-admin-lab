FROM mcr.microsoft.com/devcontainers/base:ubuntu

USER root

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bash-completion \
        ca-certificates \
        curl \
        dnsutils \
        git \
        iproute2 \
        iputils-ping \
        jq \
        less \
        lsof \
        nano \
        net-tools \
        netcat-openbsd \
        postgresql-client \
        procps \
        python3 \
        python3-pip \
        python3-venv \
        redis-tools \
        shellcheck \
        tree \
    && rm -rf /var/lib/apt/lists/*

LABEL org.opencontainers.image.title="Codespaces Admin Lab"
LABEL org.opencontainers.image.description="Dev container para aprender administración de GitHub Codespaces"

USER vscode
