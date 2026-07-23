# Codespace Ubuntu 24.04 con Docker

Este repositorio contiene una configuración educativa para construir un
Codespace sobre Ubuntu 24.04 LTS. Incluye Docker mediante una Feature,
Tailscale, `cloudflared`, Python, Git, curl y ping.

## Archivos importantes

### `.devcontainer/devcontainer.json`

Es el archivo que GitHub Codespaces y VS Code leen para saber cómo crear el
entorno. En este proyecto indica que debe:

- construir la imagen usando `.devcontainer/Dockerfile`;
- agregar Docker mediante una Dev Container Feature;
- instalar Tailscale y `cloudflared` desde sus repositorios oficiales;
- usar el usuario `vscode` dentro del contenedor;
- instalar la extensión `vscode-icons`;
- ejecutar Docker-in-Docker con privilegios adicionales.

### `.devcontainer/Dockerfile`

Define la imagen del contenedor. Parte de la imagen oficial
`mcr.microsoft.com/devcontainers/base:ubuntu-24.04` e instala:

- `git`, para trabajar con repositorios;
- `ca-certificates`, para conexiones HTTPS confiables;
- `curl`, para descargar recursos por HTTP/HTTPS;
- `iputils-ping`, para pruebas básicas de conectividad;
- `python3` y `python3-pip`, para ejecutar Python e instalar paquetes;
- `sudo`, para que el usuario de desarrollo pueda instalar algo manualmente;
- `cloudflared`, desde el repositorio oficial de Cloudflare.

La imagen base ya incluye el usuario no-root `vscode`, por lo que el Dockerfile
no intenta crearlo ni asignarle manualmente el GID 1000. Esto evita el error que
ocurría con la imagen mínima `ubuntu:24.04`.

### Docker y redes

`docker-in-docker:4` instala Docker como una Feature y permite utilizar un
daemon Docker dentro del Codespace. La Feature oficial configura los permisos
necesarios para este modo.

Tailscale y `cloudflared` quedan instalados como clientes. No se conectan
automáticamente a ninguna red o cuenta: Tailscale requiere ejecutar `sudo
tailscale up` y completar la autenticación de tu tailnet.

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
    ├── cliente: Tailscale
    ├── usuario: vscode
    └── extensión de VS Code: vscode-icons
```

El Dockerfile define la imagen y `devcontainer.json` le indica a Codespaces
cómo usar esa imagen. Ninguno de los dos archivos crea una máquina virtual ni
administra la infraestructura de GitHub; esa parte la controla Codespaces.
