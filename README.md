# Codespace básico con AlmaLinux

Este repositorio contiene la configuración mínima para construir un Codespace
personalizado sobre AlmaLinux. No incluye aplicaciones, bases de datos,
Docker-in-Docker ni Docker Compose.

## Archivos importantes

### `.devcontainer/devcontainer.json`

Es el archivo que GitHub Codespaces y VS Code leen para saber cómo crear el
entorno. En este proyecto indica que debe:

- construir la imagen usando `.devcontainer/Dockerfile`;
- instalar la extensión `vscode-icons`;
- usar el usuario `vscode` dentro del contenedor.

No necesita variables de entorno, puertos, Features ni comandos de ciclo de
vida para este ejemplo.

### `.devcontainer/Dockerfile`

Define la imagen del contenedor. Parte de `almalinux:9` e instala solamente:

- `git`, para trabajar con repositorios;
- `ca-certificates`, para conexiones HTTPS confiables;
- `sudo`, para que el usuario de desarrollo pueda instalar algo manualmente
  durante las pruebas.

También instala las herramientas necesarias para crear el usuario no-root
`vscode`, que es el usuario con el que se abre la terminal del Codespace. El
Dockerfile no presupone que el GID 1000 esté disponible: si ya existe, lo
reutiliza.

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
    ├── imagen base: AlmaLinux 9
    ├── herramientas: Git, certificados y sudo
    ├── usuario: vscode
    └── extensión de VS Code: vscode-icons
```

El Dockerfile define la imagen y `devcontainer.json` le indica a Codespaces
cómo usar esa imagen. Ninguno de los dos archivos crea una máquina virtual ni
administra la infraestructura de GitHub; esa parte la controla Codespaces.
