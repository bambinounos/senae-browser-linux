# SENAE Browser para Linux

Alternativa **no oficial** para Linux del [SENAE Browser](https://www.aduana.gob.ec/senae-browser-descargas/) que distribuye el Servicio Nacional de Aduana del Ecuador para Windows. Empaqueta en un contenedor Docker el stack legacy que requiere Ecuapass:

- Mozilla Firefox 41.0.2
- Oracle Java 7 JRE Update 80 (con plugin NPAPI)
- Adobe Flash Player 25 NPAPI

Igual que la versión oficial para Windows trae su propio Firefox bundleado, esta imagen mantiene el stack aislado del navegador del sistema, sin afectar tu Firefox/Chrome de uso diario.

> ⚠️ **Importante**: este proyecto no tiene relación oficial con la Aduana del Ecuador (SENAE). Es una solución comunitaria para usuarios de Linux que necesitan acceder a Ecuapass.

---

## Tabla de contenidos

- [¿Por qué existe esto?](#por-qué-existe-esto)
- [Compatibilidad](#compatibilidad)
- [Inicio rápido](#inicio-rápido)
- [Requisitos](#requisitos)
- [Instalación paso a paso](#instalación-paso-a-paso)
- [Uso](#uso)
- [Arquitectura](#arquitectura)
- [Persistencia y reset](#persistencia-y-reset)
- [Solución de problemas](#solución-de-problemas)
- [Notas de seguridad](#notas-de-seguridad)
- [Licencia](#licencia)
- [Créditos](#créditos)

---

## ¿Por qué existe esto?

Ecuapass es la plataforma electrónica de la Aduana del Ecuador. Su frontend usa:

- **Applet Java firmado** para operaciones autenticadas (firma digital, presentación de declaraciones, etc.).
- **Adobe Flex (Flash)** para parte de la interfaz gráfica.

Ambas tecnologías fueron descontinuadas hace años por los navegadores modernos:

| Tecnología | Discontinuada en |
|---|---|
| NPAPI (plugins Java/Flash) | Firefox 52 (2017), Chrome 45 (2015) |
| Adobe Flash Player | 31 dic 2020 (EOL oficial) |
| Java Web Start / Applets | Java 11 (2018) — no más browser plugin |

La SENAE distribuye un instalador para Windows que bundlea su propio Firefox + Java + Flash. Para Linux no existe alternativa oficial, lo que deja a usuarios de Ubuntu, Debian, Fedora, etc. sin acceso a Ecuapass desde su sistema operativo nativo.

Este repositorio resuelve esa brecha empaquetando el mismo stack legacy en un contenedor Docker reproducible.

---

## Compatibilidad

### Sistema host

| Distribución | Estado | Notas |
|---|---|---|
| Ubuntu 24.04 LTS | ✅ Probado | Sesión Wayland o Xorg |
| Ubuntu 22.04 LTS | ✅ Funciona | Mismo procedimiento |
| Debian 12 | ✅ Funciona | Instalar `docker.io` |
| Fedora 39+ | ✅ Funciona | Usar `podman` o `docker-ce` |
| Linux Mint 22 | ✅ Funciona | Basado en Ubuntu 24.04 |
| Arch Linux | ✅ Funciona | Instalar `docker` |
| WSL2 (Windows) | ⚠️ Parcial | Requiere WSLg para GUI |
| macOS | ❌ No probado | Necesita XQuartz; sin garantías |

### Stack del contenedor

| Componente | Versión | Arquitectura |
|---|---|---|
| Sistema base | Ubuntu 24.04 LTS | x86_64 |
| Navegador | Firefox 41.0.2 | Linux x86_64 |
| Java Runtime | JRE 1.7.0 Update 80 | Linux x64 (64-bit) |
| Flash Player | 25.0.0.171 NPAPI | Linux x86_64 |

---

## Inicio rápido

Si ya tienes Docker funcionando y los dos archivos descargados:

```bash
git clone https://github.com/bambinounos/senae-browser-linux.git
cd senae-browser-linux

# Coloca aquí los dos archivos (ver "Requisitos" más abajo):
#   jre-7u80-linux-x64.tar.gz  (o jdk-7u80-linux-x64.tar.gz)
#   libflashplayer.so

./build.sh    # construye la imagen (2-5 min)
./run.sh      # abre Firefox apuntando a Ecuapass
```

---

## Requisitos

### 1. Docker en el sistema host

```bash
# Ubuntu / Debian / Mint
sudo apt install docker.io
sudo usermod -aG docker $USER
# Cierra sesión y vuelve a entrar para que el grupo surta efecto
```

Verifica con: `docker --version && docker info`.

### 2. Servidor X11

El contenedor monta el socket X11 del host (`/tmp/.X11-unix`) para mostrar la ventana del navegador.

- **Ubuntu 24.04 con Wayland**: ya viene con XWayland, funciona sin configuración.
- **Sesión X11 pura**: funciona directamente.
- **WSL2 (Windows)**: requiere [WSLg](https://learn.microsoft.com/en-us/windows/wsl/tutorials/gui-apps).

### 3. Archivos a descargar manualmente

Estos componentes **no pueden redistribuirse** por sus licencias y deben colocarse en la raíz del repo antes de `./build.sh`.

#### Java 7 (JRE o JDK)

El Dockerfile acepta cualquiera de los dos:

| Archivo | Tamaño | Notas |
|---|---|---|
| `jre-7u80-linux-x64.tar.gz` | ~46 MB | Solo runtime; suficiente |
| `jdk-7u80-linux-x64.tar.gz` | ~153 MB | Incluye el JRE adentro; también funciona |

- **URL**: https://www.oracle.com/java/technologies/javase/javase7-archive-downloads.html
- **Requisito**: cuenta gratuita Oracle (registro en oracle.com).
- **SHA256 (JRE)**: `bad9a731639655118740bee119139c1ed019737571571a9c77f8f4b93d21438f`

Pasos:
1. Ir a la URL.
2. Iniciar sesión y aceptar la licencia.
3. Descargar `jre-7u80-linux-x64.tar.gz` (o el JDK).
4. Mover el archivo a la raíz del repositorio.

#### Adobe Flash Player 25 NPAPI

Distribuido libremente desde [Internet Archive](https://archive.org/details/flashplayerarchive). Atajo en una línea (descarga + extracción directa de `libflashplayer.so`):

```bash
wget -O /tmp/fp25.zip "https://archive.org/download/flashplayerarchive/pub%2Fflashplayer%2Finstallers%2Farchive%2Ffp_25.0.0.171_archive.zip"
unzip -p /tmp/fp25.zip "25_0_r0_171/flashplayer25_0r0_171_linux.x86_64.tar.gz" | tar xz libflashplayer.so
rm /tmp/fp25.zip
```

Si prefieres hacerlo manualmente:
1. Descargar [`fp_25.0.0.171_archive.zip`](https://archive.org/download/flashplayerarchive/pub%2Fflashplayer%2Finstallers%2Farchive%2Ffp_25.0.0.171_archive.zip) (~401 MB).
2. Extraer y navegar a `25_0_r0_171/`.
3. Extraer `flashplayer25_0r0_171_linux.x86_64.tar.gz`.
4. Copiar `libflashplayer.so` a la raíz del repositorio.

---

## Instalación paso a paso

### Estructura esperada antes de buildear

```
senae-browser-linux/
├── Dockerfile
├── build.sh
├── run.sh
├── README.md
├── ESPECIFICACIONES.md
├── LICENSE
├── jre-7u80-linux-x64.tar.gz   ← descargar (o jdk-...)
└── libflashplayer.so            ← descargar
```

### Construir la imagen

```bash
chmod +x build.sh run.sh
./build.sh
```

Esto:
1. Verifica que los dos archivos requeridos existen.
2. Ejecuta `docker build -t senae-browser:latest .`.
3. Tarda 2–5 minutos (depende de la conexión: descarga Firefox 41 ~47 MB).

Resultado esperado: `senae-browser:latest` aparece en `docker images`.

### Verificar el build (opcional)

```bash
docker run --rm --entrypoint /opt/senae-browser/firefox senae-browser:latest --version
# Debe imprimir: Mozilla Firefox 41.0.2

docker run --rm --entrypoint /opt/jre1.7.0_80/bin/java senae-browser:latest -version
# Debe imprimir: java version "1.7.0_80"
```

---

## Uso

### Abrir Ecuapass

```bash
./run.sh
```

Se abre Firefox 41 directamente en https://ecuapass.aduana.gob.ec.

### Otra URL

```bash
./run.sh https://portal.aduana.gob.ec
./run.sh about:plugins        # verifica plugins cargados
./run.sh about:config         # configuración avanzada de Firefox
```

### Forzar reset del perfil

```bash
RESET=1 ./run.sh
```

Borra el volumen `senae-profile` y arranca limpio. Útil si modificaste el `Dockerfile` y necesitas que el `prefs.js` baked-in vuelva a aplicarse, o si quieres descartar el historial/cookies.

### Detener el contenedor

Cierra la ventana del navegador, o desde otra terminal:

```bash
docker stop senae-browser
```

`run.sh` arranca con `--rm`, así que el container se elimina solo al detenerse (los datos del perfil persisten en el volumen).

---

## Arquitectura

```
┌─────────────────────────────────────────────┐
│  Host Linux (Ubuntu 24.04, Fedora, etc.)    │
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │ Container senae-browser:latest        │  │
│  │ ─────────────────────────────────────│  │
│  │ Ubuntu 24.04 + es_EC.UTF-8 locale    │  │
│  │                                       │  │
│  │  ┌──────────────────────────────┐    │  │
│  │  │ Firefox 41.0.2               │    │  │
│  │  │  ├─ libnpjp2.so (Java 7)     │    │  │
│  │  │  └─ libflashplayer.so (25)   │    │  │
│  │  └──────────────────────────────┘    │  │
│  │                                       │  │
│  │  Profile: /home/senae/.senae-profile │  │
│  └─────────────┬─────────────────────────┘  │
│                │                             │
│  Volumen:      │  Bind mounts:               │
│  senae-profile │  /tmp/.X11-unix (X11)       │
│                │  ~/.Xauthority (cookie)     │
│                │                             │
│  Servidor X (XWayland o Xorg)                │
└─────────────────────────────────────────────┘
```

### Componentes clave

- **Aislamiento**: el contenedor corre como usuario no-root `senae`. Tu Firefox del sistema no se afecta.
- **Plugins NPAPI**: enlazados simbólicamente en `/usr/lib/mozilla/plugins/` y `/home/senae/.mozilla/plugins/` (Firefox 41 escanea ambas).
- **Java**: el path `/opt/jre1.7.0_80/...` se normaliza vía symlink — funciona con JRE o JDK.
- **Locale**: `es_EC.UTF-8` para que la UI de Ecuapass renderice en español sin problemas de codificación.
- **X11**: `run.sh` genera una cookie xauth portable (`FamilyWild`) y agrega el container al grupo dueño del socket X — funciona en Wayland/Xorg sin pedir `xhost +`.

---

## Persistencia y reset

El perfil del navegador (cookies, sesiones, historial, certificados aceptados) se guarda en un volumen Docker llamado `senae-profile`.

```bash
# Inspeccionar el volumen
docker volume inspect senae-profile

# Borrar el perfil completo
docker volume rm senae-profile

# Backup
docker run --rm -v senae-profile:/data -v $(pwd):/backup ubuntu \
  tar czf /backup/senae-backup.tar.gz /data
```

> ⚠️ **Trampa común al iterar**: si modificas el `Dockerfile` (cambios al `prefs.js`, libs del sistema, configuración Java/Flash, plugins), tienes que invalidar el perfil cacheado. Docker copia el contenido baked-in al volumen **solo la primera vez** que el volumen no existe; además, Firefox guarda en el perfil el resultado del plugin scan, así que si la imagen anterior tenía dependencias rotas, ese resultado queda cacheado. Para forzar todo: `RESET=1 ./run.sh`.

---

## Solución de problemas

### `cannot open display: :0`

El contenedor no puede acceder al servidor X.

- **Wayland sin XWayland instalado**: `sudo apt install xwayland`.
- **Sesión Wayland pura**: forzar XWayland con `export DISPLAY=:0` antes de `./run.sh`.
- **Cookie X11 no se propaga**: `run.sh` ya genera una cookie portable. Si igual falla, verifica que `~/.Xauthority` existe en tu home.

### Pantalla en blanco / Flash no carga

Verifica en `./run.sh about:plugins` que aparezcan:
- **Java(TM) Platform SE 7 U80** — Estado: Siempre activar.
- **Shockwave Flash 25.0 r0** — Estado: Siempre activar.

#### Si Flash no aparece en `about:plugins`

Sigue estos pasos en orden:

**Paso 1 — Reset del perfil**: Firefox cachea el resultado del plugin scan dentro del perfil. Si reconstruiste la imagen (por ejemplo agregaste libs), el cache puede estar obsoleto:

```bash
RESET=1 ./run.sh about:plugins
```

**Paso 2 — Verificar dependencias de la imagen**: Flash 25 NPAPI requiere `libGL.so.1`, `libnss3.so`, `libsmime3.so`, `libssl3.so`, `libnspr4.so`. Si alguna falta, Firefox carga silenciosamente (no aparece, sin error visible):

```bash
docker run --rm --entrypoint /bin/bash senae-browser:latest -c \
  'ldd /opt/flash/libflashplayer.so | grep "not found"'
# Output esperado: vacio (ninguna falta)
```

Si aparecen libs faltantes, el Dockerfile no las incluye — abrir issue en GitHub.

**Paso 3 — Verificar el binario**:

```bash
file libflashplayer.so
# Debe decir: ELF 64-bit LSB shared object, x86-64
```

### Java no aparece en about:plugins

Verifica que el JRE/JDK descargado es de 64-bit:
```bash
tar tzf jre-7u80-linux-x64.tar.gz | grep libnpjp2
# Debe mostrar: jre1.7.0_80/lib/amd64/libnpjp2.so
```

### El applet Java pide confirmación constantemente

El Dockerfile ya configura `~/.java/deployment/security/exception.sites` con los dominios de Ecuapass. Si igual te pide aprobación, agrega manualmente la URL desde el Java Control Panel dentro del navegador o edita el archivo en el volumen.

### `permission denied` en Docker

```bash
sudo usermod -aG docker $USER
# Cerrar sesión y volver a entrar
```

---

## Notas de seguridad

> **Lee esto antes de usar el contenedor**

Este proyecto deliberadamente debilita configuraciones de seguridad para que software descontinuado (Java 7 con applets sin firmar válida y Flash 25 con su EULA) pueda ejecutarse:

| Configuración | Valor | Motivo |
|---|---|---|
| `deployment.security.level` | `MEDIUM` | Java rechazaría applets de Ecuapass |
| `deployment.insecure.jres` | `ALWAYS` | Permitir JRE 7 vencido |
| `deployment.security.expired.certificate` | `true` | El applet de Ecuapass está firmado con cert vencido |
| `deployment.security.validation.ocsp/crl` | `false` | OCSP responders viejos ya no funcionan |
| `RSLVerifyDigitalSignatures` (Flash) | `0` | RSL signature checks rotos |
| `security.mixed_content.block_active_content` (Firefox) | `false` | Ecuapass mezcla HTTP y HTTPS |

**Recomendaciones de uso:**
- Usar este browser **únicamente** para Ecuapass y sitios SENAE. No navegar por la web general.
- El contenedor corre con la red por defecto del Docker (bridge), no con `--network host`, así que está mínimamente aislado.
- Si necesitas mayor aislamiento, considera ejecutar el contenedor en una VM dedicada.
- Mantener el host actualizado — la seguridad del host no se ve comprometida por las configuraciones del contenedor.

---

## Licencia

Código y documentación: [MIT](LICENSE).

Componentes de terceros (Firefox, Java, Flash) mantienen sus licencias originales y no se redistribuyen en este repositorio. El usuario es responsable de cumplir con cada EULA al descargarlos.

---

## Créditos

- **Servicio Nacional de Aduana del Ecuador (SENAE)** — por mantener la plataforma Ecuapass y distribuir el [SENAE Browser oficial para Windows](https://www.aduana.gob.ec/senae-browser-descargas/).
- **Mozilla** por Firefox y los archivos históricos en ftp.mozilla.org.
- **Internet Archive** por preservar Adobe Flash en https://archive.org/details/flashplayerarchive.
- **Oracle** por mantener disponible JRE 7u80 en su archive.

---

## Contribuir

Issues y pull requests son bienvenidos. Antes de enviar un PR:
- Probar el build limpio: `./build.sh && RESET=1 ./run.sh about:plugins`.
- Documentar cualquier cambio en configuración Java/Flash en este README.
