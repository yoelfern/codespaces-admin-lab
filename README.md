# Práctica guiada completa: Administración de GitHub Codespaces

## Propósito

Esta práctica convierte un repositorio vacío en un entorno reproducible de administración de GitHub Codespaces. Aprenderás a distinguir y administrar:

1. La infraestructura de GitHub.
2. La máquina virtual Linux anfitriona, que GitHub administra.
3. El dev container exterior, que constituye tu Codespace.
4. El daemon Docker interno instalado mediante una Dev Container Feature.
5. Las imágenes, contenedores, redes y volúmenes creados dentro de ese daemon.
6. Los túneles de puertos de GitHub Codespaces.
7. La persistencia, los secretos, la automatización, la seguridad y la recuperación.

> Alcance realista: la práctica cubre todos los temas del documento proporcionado y las competencias esenciales de un administrador de Codespaces. No convierte al usuario en administrador del hipervisor o de la VM exterior, porque GitHub no expone ese nivel de control.

## Arquitectura del laboratorio

```text
Infraestructura administrada por GitHub
└── Máquina virtual Linux
    └── Dev container: tu Codespace
        ├── /workspaces/codespaces-admin-lab
        ├── Docker CLI y daemon Docker-in-Docker
        ├── Scripts de ciclo de vida
        ├── Puerto 8000 y 8080
        └── Contenedores internos de Docker Compose
            ├── app      Flask/Gunicorn
            ├── db       PostgreSQL
            ├── redis    Redis
            └── adminer  Administrador web de PostgreSQL
```

## Resultado esperado

Al finalizar podrás:

- Crear, detener, iniciar, reconstruir y eliminar codespaces.
- Identificar la imagen predeterminada y la configuración activa.
- Construir una imagen personalizada para el dev container.
- Explicar por qué `docker ps` no administra el contenedor exterior.
- Crear y administrar imágenes y contenedores internos.
- Usar Docker Compose, DNS interno, redes, volúmenes y health checks.
- Configurar puertos privados, de organización o públicos.
- Probar la persistencia y realizar copias de seguridad.
- Gestionar secretos sin incorporarlos al repositorio.
- Automatizar tareas con `postCreateCommand` y `postStartCommand`.
- Diagnosticar errores de creación, Docker, red, puertos y almacenamiento.
- Recuperar un Codespace con una configuración defectuosa.
- Integrar Tailscale de forma opcional y segura.
- Entender qué controlas y qué permanece bajo administración de GitHub.

---

# Módulo 0. Requisitos y reglas del laboratorio

Necesitas:

- Una cuenta de GitHub con acceso a Codespaces.
- Permiso para crear un repositorio.
- Un navegador moderno.
- Recomendado: GitHub CLI instalado localmente para practicar administración remota.

Reglas:

- No publiques contraseñas, tokens ni claves.
- Mantén los puertos privados salvo cuando una prueba requiera otra visibilidad.
- No ejecutes comandos de limpieza destructivos sin revisar su efecto.
- Confirma que tus cambios importantes estén en Git antes de eliminar un Codespace.
- Detén el Codespace cuando termines para evitar consumo de cómputo.

---

# Módulo 1. Crear el repositorio y el primer Codespace

## 1.1 Crear un repositorio vacío

En GitHub:

1. Selecciona **New repository**.
2. Nombre: `codespaces-admin-lab`.
3. Puede ser privado o público.
4. Inicialízalo con un archivo `README`.
5. Crea el repositorio.

## 1.2 Crear el Codespace con la imagen predeterminada

1. Abre el repositorio.
2. Selecciona **Code**.
3. Abre la pestaña **Codespaces**.
4. Selecciona **Create codespace on main**.
5. Para elegir región o máquina, usa **New with options**.

En esta primera creación todavía no agregues `.devcontainer`. El objetivo es observar el comportamiento predeterminado.

## 1.3 Inspeccionar la arquitectura

Ejecuta:

```bash
pwd
id
hostname
uname -a
cat /etc/os-release
echo "$CODESPACE_NAME"
echo "$GITHUB_REPOSITORY"
devcontainer-info
devcontainer-info content-url
```

Registra:

- Distribución Linux.
- Usuario activo.
- Nombre del Codespace.
- `Definition ID`.
- URL de la definición de la imagen.
- Herramientas disponibles.

Inspecciona almacenamiento y montajes:

```bash
df -h
findmnt /workspaces
mount | grep /workspaces
ls -la /workspaces
```

Inspecciona red y procesos:

```bash
ip -brief address
ip route
ps -ef | head -n 30
```

Comprueba Docker sin asumir que está disponible:

```bash
command -v docker || true
docker version || true
docker info || true
```

Comprueba virtualización:

```bash
ls -l /dev/kvm
```

Si `/dev/kvm` no existe, no tienes aceleración KVM expuesta. Aunque QEMU pueda emular CPU por software, un Codespace no debe tratarse como una VM Windows general. Un contenedor Linux tampoco se transforma en Windows cambiando la instrucción `FROM`.

## 1.4 Primer modelo mental

Completa estas afirmaciones:

- El Codespace usa un contenedor de desarrollo ejecutado sobre una __________.
- La VM es administrada por __________.
- El repositorio está montado en __________.
- Un Dockerfile define una __________.
- Un contenedor es una instancia en ejecución de una __________.

Respuestas: máquina virtual Linux, GitHub, `/workspaces`, imagen, imagen.

---

# Módulo 2. Instalar el proyecto del laboratorio

Descarga el paquete proporcionado y copia su contenido al repositorio, o crea los archivos siguiendo la estructura:

```text
codespaces-admin-lab/
├── .devcontainer/
│   ├── devcontainer.json
│   ├── Dockerfile
│   ├── post-create.sh
│   ├── post-start.sh
│   └── diagnose.sh
├── app/
│   ├── app.py
│   ├── Dockerfile
│   └── requirements.txt
├── images/
│   └── hello/
│       ├── Dockerfile
│       └── index.html
├── scripts/
│   ├── backup-db.sh
│   ├── restore-db.sh
│   └── stack-status.sh
├── .env.example
├── .gitignore
└── compose.yaml
```

Verifica:

```bash
tree -a -L 3
python3 -m json.tool .devcontainer/devcontainer.json >/dev/null
docker compose config
```

`docker compose config` puede fallar antes de que Docker-in-Docker sea instalado, pero el archivo seguirá pudiendo revisarse después de reconstruir.

Guarda la configuración:

```bash
git add .
git commit -m "Configurar laboratorio de administración de Codespaces"
git push
```

---

# Módulo 3. Comprender y personalizar el dev container

## 3.1 Qué hace cada archivo

### `.devcontainer/devcontainer.json`

Define cómo Codespaces utilizará el entorno:

- Construye el `Dockerfile`.
- Añade Docker-in-Docker como Feature.
- Reenvía puertos.
- Instala extensiones de VS Code.
- Define variables no secretas.
- Ejecuta scripts del ciclo de vida.
- Abre la sesión como `vscode`.

### `.devcontainer/Dockerfile`

Define la nueva imagen del dev container. Parte de una imagen base de Dev Containers e instala utilidades Linux, clientes de PostgreSQL y Redis, herramientas de red y diagnóstico.

### `post-create.sh`

Se ejecuta después de crear o reconstruir el contenedor. Prepara archivos, permisos y registra su ejecución.

### `post-start.sh`

Se ejecuta cada vez que arranca el Codespace. Espera al daemon Docker interno y, si `AUTO_START_STACK=true`, inicia Compose.

## 3.2 Reconstruir el contenedor

Abre la paleta:

```text
Ctrl + Shift + P
Codespaces: Rebuild Container
```

Selecciona **Rebuild**. Utiliza **Full Rebuild** cuando necesites descartar la caché de construcción.

También puede hacerse desde una máquina local:

```bash
gh codespace rebuild
gh codespace rebuild --full
```

## 3.3 Verificar la nueva imagen efectiva

Después de reconstruir:

```bash
bash .devcontainer/diagnose.sh
```

Comprueba herramientas:

```bash
curl --version
jq --version
psql --version
redis-cli --version
shellcheck --version
docker version
docker compose version
```

Inspecciona el registro del ciclo de vida:

```bash
cat .lab-state/lifecycle.log
```

## 3.4 Distinción crítica

Ejecuta:

```bash
docker ps -a
docker images
```

El dev container exterior del Codespace no aparece como un contenedor administrable en esa lista. La lista pertenece al daemon Docker interno. Por eso:

```bash
docker stop <codespace>
```

no es una forma válida de detener el Codespace exterior. El Codespace se administra mediante GitHub, la paleta de VS Code, GitHub CLI o la API.

---

# Módulo 4. Administrar un contenedor manualmente

## 4.1 Descargar y ejecutar una imagen

```bash
docker pull nginx:alpine
docker image ls
docker run -d \
  --name web-manual \
  -p 8081:80 \
  nginx:alpine
```

Comprueba:

```bash
docker ps
curl http://127.0.0.1:8081
```

Abre la pestaña **Ports** y visita el puerto `8081`.

## 4.2 Inspección

```bash
docker inspect web-manual
docker inspect \
  --format '{{.Name}} {{.State.Status}} {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
  web-manual
docker logs web-manual
docker stats --no-stream web-manual
docker top web-manual
```

## 4.3 Ejecutar comandos dentro del contenedor

```bash
docker exec web-manual nginx -v
docker exec web-manual ls -la /usr/share/nginx/html
docker exec -it web-manual sh
```

Dentro:

```sh
cat /etc/os-release
ps
exit
```

## 4.4 Ciclo de vida

```bash
docker stop web-manual
docker ps -a
docker start web-manual
docker restart web-manual
docker rename web-manual web-manual-renombrado
docker rm -f web-manual-renombrado
```

Diferencia:

- `stop`: conserva el contenedor.
- `start`: vuelve a iniciar el mismo contenedor.
- `restart`: detiene e inicia.
- `rm`: elimina el contenedor.
- La imagen permanece hasta usar `docker image rm`.

---

# Módulo 5. Construir y redefinir una imagen correctamente

## 5.1 Construir la versión 1

```bash
docker build \
  -t codespaces-lab/hello:v1 \
  images/hello
```

Inspecciona:

```bash
docker image ls
docker image inspect codespaces-lab/hello:v1
docker history codespaces-lab/hello:v1
```

Ejecuta:

```bash
docker run -d \
  --name hello-v1 \
  -p 8081:80 \
  codespaces-lab/hello:v1
curl http://127.0.0.1:8081
```

## 5.2 Crear la versión 2

Edita `images/hello/index.html` y cambia:

```html
<p>Versión 1</p>
```

por:

```html
<p>Versión 2: imagen reconstruida</p>
```

Construye:

```bash
docker build \
  --no-cache \
  -t codespaces-lab/hello:v2 \
  images/hello
```

Reemplaza el contenedor:

```bash
docker rm -f hello-v1
docker run -d \
  --name hello-v2 \
  -p 8081:80 \
  codespaces-lab/hello:v2
curl http://127.0.0.1:8081
```

Compara:

```bash
docker image ls codespaces-lab/hello
docker history codespaces-lab/hello:v1
docker history codespaces-lab/hello:v2
```

## 5.3 Etiquetado

```bash
docker tag \
  codespaces-lab/hello:v2 \
  codespaces-lab/hello:latest
```

## 5.4 Antipatrón didáctico: `docker commit`

Puedes modificar un contenedor y crear una imagen con `docker commit`, pero el resultado no es reproducible:

```bash
docker exec hello-v2 sh -c \
  'echo "<h2>Cambio manual</h2>" >> /usr/share/nginx/html/index.html'
docker commit hello-v2 codespaces-lab/hello:manual
```

Úsalo solamente para comprender el mecanismo. La práctica correcta es conservar el cambio en el Dockerfile y los archivos fuente, después reconstruir.

---

# Módulo 6. Levantar una aplicación multicontenedor con Compose

## 6.1 Preparar variables

```bash
cp -n .env.example .env
nano .env
```

Usa una contraseña de laboratorio. No confirmes `.env` en Git:

```bash
git status --ignored
```

## 6.2 Validar la configuración

```bash
docker compose config
docker compose config --services
docker compose config --volumes
```

## 6.3 Construir e iniciar

```bash
docker compose build --pull
docker compose up -d
docker compose ps
```

Sigue el arranque:

```bash
docker compose logs -f
```

Sal de los registros con `Ctrl+C`; los contenedores siguen ejecutándose.

## 6.4 Probar la aplicación

```bash
curl -s http://127.0.0.1:8000/health | jq
curl -s http://127.0.0.1:8000/ | jq
curl -s http://127.0.0.1:8000/ | jq
curl -s http://127.0.0.1:8000/environment | jq
```

La respuesta principal debe mostrar:

- Contador de Redis.
- Filas almacenadas en PostgreSQL.
- Estado de carga del secreto.
- Fecha y hora.

Abre:

- Puerto `8000`: aplicación.
- Puerto `8080`: Adminer.

Para Adminer:

- Sistema: PostgreSQL.
- Servidor: `db`.
- Usuario: el valor de `POSTGRES_USER`.
- Contraseña: el valor de `POSTGRES_PASSWORD`.
- Base de datos: el valor de `POSTGRES_DB`.

Nunca uses `localhost` como servidor desde Adminer, porque Adminer está en otro contenedor. Debe usar el nombre DNS del servicio: `db`.

---

# Módulo 7. Redes y DNS de Docker Compose

## 7.1 Enumerar redes

```bash
docker network ls
docker compose ps
```

Busca las redes del proyecto:

```bash
docker network ls --filter name=codespaces-admin-lab
```

Inspecciona:

```bash
docker network inspect codespaces-admin-lab_frontend
docker network inspect codespaces-admin-lab_backend
```

## 7.2 Resolver servicios por nombre

```bash
docker compose exec app getent hosts db
docker compose exec app getent hosts redis
docker compose exec adminer getent hosts db
```

Prueba PostgreSQL desde el contenedor `db`:

```bash
docker compose exec db \
  psql -U lab -d labdb -c 'SELECT COUNT(*) FROM page_views;'
```

Prueba Redis:

```bash
docker compose exec redis redis-cli ping
docker compose exec redis redis-cli get visits
```

## 7.3 Comprender los dos niveles de puertos

En `compose.yaml`:

```yaml
ports:
  - "8000:8000"
```

significa:

```text
Puerto 8000 del dev container
└── Puerto 8000 del contenedor app
```

Codespaces agrega otro nivel:

```text
URL HTTPS de GitHub
└── Túnel al puerto 8000 del dev container
    └── Mapeo Docker al puerto 8000 de app
```

Docker Compose y el túnel de Codespaces no son el mismo mecanismo.

## 7.4 Escucha correcta

Dentro de un contenedor, una aplicación que deba recibir tráfico externo debe escuchar normalmente en `0.0.0.0`, no solamente en `127.0.0.1`.

Comprueba:

```bash
docker compose exec app \
  python -c 'import socket; print(socket.gethostname())'
docker port codespaces-admin-lab-app-1
ss -lntp | grep 8000 || true
```

---

# Módulo 8. Administración de Compose

Practica:

```bash
docker compose ps
docker compose logs --tail=100 app
docker compose logs -f db
docker compose exec app sh
docker compose exec db bash
docker compose restart app
docker compose stop redis
docker compose ps
docker compose start redis
docker compose up -d --build app
docker compose down
docker compose up -d
```

Ejecuta una orden temporal:

```bash
docker compose run --rm app \
  python -c 'print("Contenedor de tarea única")'
```

Escala un servicio sin publicar puertos duplicados:

```bash
docker compose up -d --scale app=2
```

En este laboratorio el mapeo fijo `8000:8000` puede causar conflicto al escalar. El error es una lección: para escalar réplicas se necesita un proxy/balanceador y no asignar el mismo puerto anfitrión a cada réplica.

Vuelve a una réplica:

```bash
docker compose up -d --scale app=1
```

---

# Módulo 9. Volúmenes y persistencia de datos

## 9.1 Observar volúmenes

```bash
docker volume ls
docker compose volumes
docker volume inspect codespaces-admin-lab_postgres-data
docker volume inspect codespaces-admin-lab_redis-data
```

## 9.2 Probar persistencia frente a `down`

Genera datos:

```bash
for i in 1 2 3 4 5; do
  curl -s http://127.0.0.1:8000/ | jq
done
```

Detén y elimina contenedores, pero conserva volúmenes:

```bash
docker compose down
docker compose up -d
curl -s http://127.0.0.1:8000/ | jq
```

Los datos deben continuar.

## 9.3 Probar eliminación de volúmenes

Primero crea copia:

```bash
bash scripts/backup-db.sh
ls -lh backups
```

Después, de forma consciente:

```bash
docker compose down -v
docker compose up -d
curl -s http://127.0.0.1:8000/ | jq
```

Los contadores deben reiniciarse porque los volúmenes fueron eliminados.

Restaura PostgreSQL:

```bash
latest_backup="$(ls -1t backups/*.sql | head -n 1)"
bash scripts/restore-db.sh "$latest_backup"
```

Comprueba:

```bash
docker compose exec db \
  psql -U lab -d labdb -c 'SELECT COUNT(*) FROM page_views;'
```

Redis no se restaura con el volcado de PostgreSQL; cada tecnología requiere su propia estrategia de copia.

## 9.4 Persistencia del Codespace frente a persistencia de Docker

Crea:

```bash
echo "workspace" > /workspaces/prueba-workspace.txt
echo "home" > "$HOME/prueba-home.txt"
echo "tmp" > /tmp/prueba-tmp.txt
```

Detén e inicia el Codespace. Comprueba qué archivos siguen disponibles.

Después haz copia de la base de datos en `backups/` y reconstruye el dev container. Comprueba:

```bash
ls -l /workspaces/prueba-workspace.txt
ls -l "$HOME/prueba-home.txt" || true
ls -l /tmp/prueba-tmp.txt || true
docker volume ls
ls -lh backups
```

Puntos esperados:

- `/workspaces` se conserva durante la reconstrucción.
- Los cambios fuera de `/workspaces` se eliminan durante la reconstrucción.
- El almacenamiento del daemon Docker-in-Docker vive fuera de `/workspaces`; sus imágenes y volúmenes no deben considerarse respaldo permanente frente a una reconstrucción.
- Guarda código, configuraciones y copias necesarias en `/workspaces`, y confirma en Git lo que deba ser reproducible.

---

# Módulo 10. Puertos de GitHub Codespaces

## 10.1 Port forwarding automático

Los puertos `8000`, `8080` y `8081` están declarados en `devcontainer.json`. Revisa la pestaña **Ports**.

## 10.2 Visibilidad

Practica con el puerto `8081`:

1. Déjalo **Private**.
2. Copia la URL y comprueba que GitHub solicita autenticación.
3. Si tu política lo permite, cámbialo temporalmente a **Public**.
4. Comprueba desde una ventana privada.
5. Devuélvelo inmediatamente a **Private**.

No publiques:

- PostgreSQL.
- Redis.
- Paneles administrativos con credenciales reales.
- Aplicaciones con secretos o datos sensibles.

## 10.3 Diagnóstico de puertos

```bash
ss -lntp
docker compose ps
docker compose logs app
curl -v http://127.0.0.1:8000/health
```

Si el puerto no abre:

1. Confirma que el proceso sigue activo.
2. Confirma que escucha en `0.0.0.0`.
3. Confirma el mapeo de Docker.
4. Confirma que el puerto aparece en **Ports**.
5. Confirma que la visibilidad es correcta.
6. Evita escribir `localhost:8000` en tu computadora si estás usando Codespaces desde el navegador; abre la URL reenviada.

---

# Módulo 11. Secretos de Codespaces

## 11.1 Crear el secreto

En GitHub:

```text
Repository
Settings
Secrets and variables
Codespaces
New repository secret
```

Nombre:

```text
LAB_SECRET
```

Valor: una cadena de prueba que no uses en producción.

Después detén e inicia el Codespace para que el nuevo secreto esté disponible.

## 11.2 Verificar sin revelar

No ejecutes `echo "$LAB_SECRET"` en una sesión grabada o compartida. Comprueba solamente su presencia:

```bash
if [[ -n "${LAB_SECRET:-}" ]]; then
  echo "LAB_SECRET está cargado"
else
  echo "LAB_SECRET no está cargado"
fi
```

Recrea la aplicación:

```bash
docker compose up -d --force-recreate app
curl -s http://127.0.0.1:8000/environment | jq
```

Debe mostrar:

```json
"secret_loaded": true
```

## 11.3 Regla de administración

- `containerEnv`: datos no sensibles.
- `.env`: configuración local que no debe confirmarse.
- Codespaces secrets: tokens, claves y contraseñas.
- Nunca escribas secretos en Dockerfiles: pueden quedar en capas de la imagen.
- Nunca confirmes `.env`.
- Evita imprimir secretos en logs.

---

# Módulo 12. Automatización del ciclo de vida

## 12.1 Observar comandos

```bash
cat .lab-state/lifecycle.log
```

- `postCreateCommand`: se ejecuta tras creación o reconstrucción.
- `postStartCommand`: se ejecuta en cada arranque.

## 12.2 Activar arranque automático

Edita `.devcontainer/devcontainer.json`:

```json
"containerEnv": {
  "LAB_ENVIRONMENT": "codespaces",
  "AUTO_START_STACK": "true"
}
```

Confirma el cambio y reconstruye. Después:

```bash
docker compose ps
cat .lab-state/lifecycle.log
```

Detén e inicia el Codespace. El stack debe iniciarse automáticamente.

## 12.3 Diseñar scripts idempotentes

Un script es idempotente cuando ejecutarlo varias veces no destruye el entorno ni duplica datos de forma incorrecta.

Buenas prácticas:

```bash
mkdir -p directorio
cp -n origen destino
docker compose up -d
command -v herramienta >/dev/null || instalar
```

Evita en scripts de arranque:

```bash
rm -rf datos
docker compose down -v
apt install sin Dockerfile
```

---

# Módulo 13. Administración remota con GitHub CLI

Desde tu computadora local:

```bash
gh auth login
gh codespace list
gh codespace create
gh codespace ssh -c NOMBRE
gh codespace ports -c NOMBRE
gh codespace stop -c NOMBRE
gh codespace rebuild -c NOMBRE
gh codespace rebuild --full -c NOMBRE
gh codespace delete -c NOMBRE
```

No elimines el Codespace hasta que:

```bash
git status
git push
```

no muestren trabajo pendiente importante.

Comprueba el principio:

- Cerrar la pestaña del navegador no equivale a detener el Codespace.
- Detenerlo para el cómputo, pero conserva almacenamiento.
- Eliminarlo termina su ciclo de vida; el trabajo no confirmado puede perderse.

---

# Módulo 14. Diagnóstico integral

Ejecuta:

```bash
bash .devcontainer/diagnose.sh
bash scripts/stack-status.sh
```

## 14.1 Docker no responde

```bash
docker info
ls -l /var/run/docker.sock
ps -ef | grep '[d]ockerd'
```

Reinicia el Codespace. Si persiste, revisa el Creation Log y prueba una reconstrucción completa.

## 14.2 Un contenedor termina inmediatamente

```bash
docker compose ps -a
docker compose logs --tail=200 SERVICIO
docker inspect CONTENEDOR \
  --format '{{.State.Status}} {{.State.ExitCode}} {{.State.Error}}'
```

## 14.3 DNS interno falla

```bash
docker compose exec app getent hosts db
docker network inspect codespaces-admin-lab_backend
docker compose config
```

Comprueba que ambos servicios compartan una red.

## 14.4 Poco espacio

```bash
df -h
docker system df
docker image ls
docker ps -a
docker volume ls
```

Limpieza gradual:

```bash
docker container prune
docker image prune
docker builder prune
```

Revisa cada confirmación. Este comando es mucho más destructivo:

```bash
docker system prune -a --volumes
```

Puede eliminar contenedores detenidos, imágenes, caché y volúmenes con bases de datos. No lo uses como primera respuesta.

## 14.5 La configuración del dev container falla

Revisa:

```text
Ctrl + Shift + P
Codespaces: View Creation Log
```

Busca:

```text
ERROR
Dockerfile
devcontainer.json
Feature
postCreateCommand
postStartCommand
```

---

# Módulo 15. Ejercicio deliberado de recuperación

## 15.1 Provocar un error controlado

En una rama de práctica:

```bash
git switch -c practica/error-devcontainer
```

Agrega al `apt-get install` del `.devcontainer/Dockerfile` un paquete inexistente:

```text
paquete-que-no-existe-codespaces
```

Intenta reconstruir.

## 15.2 Recuperar

Codespaces puede abrir un modo de recuperación. Revisa el Creation Log, elimina el paquete ficticio y vuelve a reconstruir.

Confirma:

```bash
git diff
git add .devcontainer/Dockerfile
git commit -m "Recuperar configuración del dev container"
```

No mezcles errores deliberados con `main` sin una rama o un commit recuperable.

---

# Módulo 16. Tailscale opcional

Esta práctica requiere una cuenta y una tailnet de Tailscale.

Agrega temporalmente a `devcontainer.json`:

```json
"runArgs": ["--device=/dev/net/tun"],
"features": {
  "ghcr.io/devcontainers/features/docker-in-docker:4": {
    "version": "latest",
    "moby": true
  },
  "ghcr.io/tailscale/codespace/tailscale": {}
}
```

Reconstruye y autentica siguiendo el flujo mostrado por Tailscale:

```bash
tailscale set --accept-routes
tailscale status
tailscale ip -4
```

Prueba acceso a un recurso privado autorizado.

Reglas:

- No confirmes claves de autenticación.
- Para automatización, usa un secreto y una clave efímera cuando sea apropiado.
- Tailscale, Docker networking y los puertos reenviados de Codespaces son redes distintas.
- Una conexión Tailscale no convierte el Codespace en una VM de propósito general.

---

# Módulo 17. Imágenes, exportación y restauración

## 17.1 Guardar una imagen

```bash
mkdir -p backups/images
docker save \
  codespaces-lab/hello:v2 \
  | gzip > backups/images/hello-v2.tar.gz
```

## 17.2 Eliminar y cargar

```bash
docker rm -f hello-v2 2>/dev/null || true
docker image rm \
  codespaces-lab/hello:v2 \
  codespaces-lab/hello:latest
gunzip -c backups/images/hello-v2.tar.gz | docker load
docker image ls codespaces-lab/hello
```

La copia está en `/workspaces`, por lo que puede sobrevivir a una reconstrucción del dev container, aunque un artefacto importante debería almacenarse también en un registro o sistema de respaldos adecuado.

---

# Módulo 18. Seguridad operativa

Lista mínima:

- Trabaja como usuario no root cuando sea posible.
- Usa `sudo` solamente cuando sea necesario.
- Mantén puertos privados por defecto.
- No expongas directamente bases de datos ni cachés.
- Usa secretos de Codespaces.
- No incluyas secretos en Dockerfiles, commits, imágenes ni logs.
- Revisa imágenes y versiones antes de actualizar.
- Confirma archivos reproducibles en Git.
- Haz copias antes de eliminar volúmenes o reconstruir.
- No ejecutes contenedores privilegiados salvo necesidad entendida.
- Revisa dependencias y registros de construcción.
- Detén y elimina recursos que ya no uses.

Comprueba usuario:

```bash
id
docker compose exec app id
docker compose exec db id
```

Observa que el usuario del dev container y los usuarios de cada contenedor interno son independientes.

---

# Módulo 19. Administración del repositorio y optimización

## 19.1 Máquinas

Al crear el Codespace con opciones avanzadas puedes seleccionar región y tipo de máquina, sujetos a disponibilidad y políticas.

Usa más recursos cuando:

- La construcción de imágenes sea pesada.
- Ejecutas varias bases de datos.
- Compilas proyectos grandes.
- Docker consume mucha memoria.

No uses máquinas grandes por costumbre. Mide:

```bash
docker stats
free -h
nproc
df -h
```

## 19.2 Prebuilds

Como administrador del repositorio, considera prebuilds cuando crear el entorno tarde demasiado. Un prebuild puede preparar la imagen, extensiones, dependencias y comandos antes de que el desarrollador cree su Codespace.

En GitHub:

```text
Repository
Settings
Codespaces
Set up prebuild
```

Configura:

- Rama.
- `devcontainer.json`.
- Regiones necesarias.
- Evento de actualización.
- Versiones retenidas.
- Notificaciones de fallo.

Los prebuilds consumen almacenamiento y usan GitHub Actions. No los actives en regiones o ramas que nadie usa.

## 19.3 Consumo

- Un Codespace en ejecución consume cómputo.
- Un Codespace detenido conserva almacenamiento.
- Un Codespace existente puede seguir generando costo de almacenamiento.
- Elimina entornos terminados.
- Reduce el timeout cuando sea apropiado.
- Revisa presupuestos y políticas en organizaciones.

---

# Módulo 20. Qué controlas y qué no

| Elemento | Control |
|---|---|
| Dockerfile del dev container | Sí |
| `devcontainer.json` | Sí |
| Paquetes, herramientas y extensiones | Sí |
| Usuario remoto | Sí |
| Scripts de creación y arranque | Sí |
| Contenedores internos | Sí |
| Redes y volúmenes internos | Sí |
| Puertos reenviados, dentro de políticas | Sí |
| Datos en `/workspaces` | Sí |
| Selección entre máquinas disponibles | Parcial |
| Políticas de la organización | Solo administradores autorizados |
| Kernel de la VM exterior | No |
| Hipervisor de GitHub | No |
| Interfaz física de red | No |
| Contenedor exterior mediante Docker interno | No |
| Convertir Codespaces en Windows nativo | No |

---

# Módulo 21. Evaluación final

Entrega estas evidencias:

1. Salida de `devcontainer-info`.
2. Salida resumida de `.devcontainer/diagnose.sh`.
3. Commit que contiene `.devcontainer`.
4. `docker image ls` con `hello:v1` y `hello:v2`.
5. `docker compose ps` con cuatro servicios.
6. Respuesta de `/health`.
7. Resolución DNS de `db` y `redis` desde `app`.
8. Prueba de persistencia después de `docker compose down`.
9. Prueba de pérdida después de `docker compose down -v`.
10. Archivo de copia SQL en `backups/`.
11. Evidencia de restauración.
12. Evidencia de un secreto cargado sin revelar su valor.
13. Registro de `postCreateCommand` y `postStartCommand`.
14. Captura de la pestaña Ports con visibilidad privada.
15. Recuperación de una reconstrucción fallida.
16. Explicación escrita de las tres capas de red.
17. Explicación de qué sobrevive a stop/start y rebuild.
18. Lista de cinco acciones de seguridad.
19. Explicación de por qué el Codespace no es Windows.
20. Limpieza final sin pérdida de código.

## Preguntas de dominio

1. ¿Por qué la imagen del dev container no aparece necesariamente en `docker images`?
2. ¿Qué diferencia existe entre `forwardPorts` y `ports` de Compose?
3. ¿Por qué `db:5432` funciona desde `app`, pero `localhost:5432` no?
4. ¿Qué se pierde al reconstruir fuera de `/workspaces`?
5. ¿Qué riesgo tiene `docker compose down -v`?
6. ¿Cuándo corresponde `postCreateCommand` y cuándo `postStartCommand`?
7. ¿Por qué un secreto no debe escribirse con `ENV` en el Dockerfile?
8. ¿Qué harías antes de un Full Rebuild?
9. ¿Cómo diagnosticarías un contenedor con código de salida distinto de cero?
10. ¿Qué partes de Codespaces siguen perteneciendo a GitHub?

---

# Módulo 22. Limpieza final

Conserva las copias necesarias y ejecuta:

```bash
docker compose down
docker rm -f hello-v2 2>/dev/null || true
docker image prune
docker system df
git status
git push
```

Después, desde GitHub o la CLI:

```bash
gh codespace stop -c NOMBRE
```

Cuando ya no necesites el entorno:

```bash
gh codespace delete -c NOMBRE
```

---

# Orden recomendado de estudio

## Nivel básico

Módulos 1 al 5.

## Nivel operativo

Módulos 6 al 12.

## Nivel administrador

Módulos 13 al 20.

## Certificación personal

Módulos 21 y 22, con todas las evidencias.

La competencia no consiste en memorizar comandos. Consiste en poder reconstruir el entorno desde Git, distinguir cada capa, proteger datos y secretos, diagnosticar fallos y recuperar el Codespace sin depender de cambios manuales irreproducibles.
