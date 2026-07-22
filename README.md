# Codespace Ubuntu 24.04 con Docker

Este repositorio contiene una configuración educativa para construir un
Codespace sobre Ubuntu 24.04 LTS. Incluye Docker mediante una Feature, Node.js,
Tailwind CSS, `cloudflared`, Python, Git, curl y ping.

## Archivos importantes

### `.devcontainer/devcontainer.json`

Es el archivo que GitHub Codespaces y VS Code leen para saber cómo crear el
entorno. En este proyecto indica que debe:

- construir la imagen usando `.devcontainer/Dockerfile`;
- agregar Docker y Node.js mediante Dev Container Features;
- instalar Tailwind CSS mediante `postCreateCommand`;
- usar el usuario `vscode` dentro del contenedor;
- instalar la extensión `vscode-icons`;
- ejecutar Docker-in-Docker con privilegios adicionales.

### `.devcontainer/Dockerfile`

Define la imagen del contenedor. Parte de `ubuntu:24.04` e instala:

- `git`, para trabajar con repositorios;
- `ca-certificates`, para conexiones HTTPS confiables;
- `curl`, para descargar recursos por HTTP/HTTPS;
- `iputils-ping`, para pruebas básicas de conectividad;
- `python3` y `python3-pip`, para ejecutar Python e instalar paquetes;
- `sudo`, para que el usuario de desarrollo pueda instalar algo manualmente;
- `cloudflared`, desde el repositorio oficial de Cloudflare.

También crea el usuario no-root `vscode`. Si el GID 1000 ya está ocupado, usa
otro GID disponible y evita el fallo que ocurría en la configuración anterior.

### Features y Tailwind

`docker-in-docker:4` instala Docker como una Feature y permite utilizar un
daemon Docker dentro del Codespace. `node:2` instala Node.js 22 y npm. Después,
`postCreateCommand` instala Tailwind CSS v4 y su CLI oficial.

### `.devcontainer/diagnose.sh`

Es un script opcional de lectura. Muestra el usuario actual, el sistema
operativo, las versiones básicas y algunas variables que Codespaces puede
proporcionar. No instala software ni modifica el sistema.

## Probar la configuración

Después de subir estos archivos a GitHub:

1. Crea o abre un Codespace del repositorio.
2. Si el Codespace ya existía, ejecuta `Codespaces: Rebuild Container` desde la
   paleta de comandos de VS Code.
3. Comprueba el entorno:

```bash
cat /etc/os-release
git --version
bash .devcontainer/diagnose.sh
```

## Modelo mental

```text
GitHub Codespaces
└── contenedor de desarrollo
    ├── imagen base: Ubuntu 24.04 LTS
    ├── herramientas: Git, Python, curl, ping y cloudflared
    ├── Feature: Docker-in-Docker
    ├── Feature: Node.js 22
    ├── paquete npm: Tailwind CSS v4
    ├── usuario: vscode
    └── extensión de VS Code: vscode-icons
```

El Dockerfile define la imagen y `devcontainer.json` le indica a Codespaces
cómo usar esa imagen. Ninguno de los dos archivos crea una máquina virtual ni
administra la infraestructura de GitHub; esa parte la controla Codespaces.
