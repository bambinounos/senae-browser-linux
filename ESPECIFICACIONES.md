# SENAE Browser para Ubuntu 24.04 - Especificaciones de Descarga

## Resumen del proyecto

Contenedor Docker que empaqueta un entorno completo para acceder al sistema
Ecuapass (Aduana del Ecuador) desde Ubuntu 24.04, usando componentes nativos Linux.

| Componente | Versión | Arquitectura |
|---|---|---|
| Sistema base | Ubuntu 24.04 LTS | x86_64 |
| Navegador | Firefox 41.0.2 | Linux x86_64 |
| Java Runtime | JRE 1.7.0 Update 80 | Linux x64 |
| Flash Player | 25.0.0.171 NPAPI | Linux x86_64 |

---

## Archivos a descargar

### 1. Firefox 41.0.2 (descarga automática en Dockerfile)

- **Archivo**: `firefox-41.0.2.tar.bz2`
- **Tamaño**: 47 MB
- **URL directa**: https://ftp.mozilla.org/pub/firefox/releases/41.0.2/linux-x86_64/es-ES/firefox-41.0.2.tar.bz2
- **SHA512**: verificar en https://ftp.mozilla.org/pub/firefox/releases/41.0.2/SHA512SUMS
- **Licencia**: Mozilla Public License 2.0
- **Requisito**: Ninguno (descarga libre)
- **Nota**: Se descarga automáticamente durante `docker build`. No requiere acción manual.

### 2. Java 7 Update 80 — JRE o JDK (descarga manual requerida)

El Dockerfile acepta cualquiera de los dos archivos:

- **Opción A — JRE** (más liviano): `jre-7u80-linux-x64.tar.gz` (~46 MB)
- **Opción B — JDK** (incluye el JRE adentro): `jdk-7u80-linux-x64.tar.gz` (~153 MB)

Datos comunes:

- **URL**: https://www.oracle.com/java/technologies/javase/javase7-archive-downloads.html
- **SHA256 (JRE)**: `bad9a731639655118740bee119139c1ed019737571571a9c77f8f4b93d21438f`
- **Licencia**: Oracle Binary Code License Agreement for Java SE
- **Requisito**: Cuenta Oracle gratuita (registrarse en oracle.com)
- **Instrucciones**:
  1. Ir a la URL indicada
  2. Buscar sección "Java SE Runtime Environment 7u80" (JRE) o "Java SE Development Kit 7u80" (JDK)
  3. Aceptar licencia
  4. Descargar el `.tar.gz` que prefieras
  5. Colocar el archivo en la carpeta `SENAE-Browser-Docker-Ubuntu/`

### 3. Flash Player 25.0.0.171 NPAPI Linux (descarga manual requerida)

- **Archivo origen**: `fp_25.0.0.171_archive.zip`
- **Tamaño del ZIP**: 401.1 MB (contiene todas las plataformas)
- **Archivo necesario**: `libflashplayer.so` (~17 MB, extraído del ZIP)
- **URL**: https://archive.org/details/flashplayerarchive
- **Descarga directa del ZIP**: https://archive.org/download/flashplayerarchive/pub%2Fflashplayer%2Finstallers%2Farchive%2Ffp_25.0.0.171_archive.zip
- **Licencia**: Adobe Flash Player EULA (uso personal/comercial permitido)
- **Requisito**: Ninguno (descarga libre desde Archive.org)
- **Instrucciones**:
  1. Descargar `fp_25.0.0.171_archive.zip` (401 MB)
  2. Extraer el ZIP
  3. Dentro navegar a: `25_0_r0_171/`
  4. Buscar: `flashplayer25_0r0_171_linux.x86_64.tar.gz`
  5. Extraer ese .tar.gz
  6. Copiar `libflashplayer.so` a la carpeta `SENAE-Browser-Docker-Ubuntu/`

Atajo en una línea (descarga + extracción directa de `libflashplayer.so`):

```bash
wget -O /tmp/fp25.zip "https://archive.org/download/flashplayerarchive/pub%2Fflashplayer%2Finstallers%2Farchive%2Ffp_25.0.0.171_archive.zip"
unzip -p /tmp/fp25.zip "25_0_r0_171/flashplayer25_0r0_171_linux.x86_64.tar.gz" | tar xz libflashplayer.so
rm /tmp/fp25.zip
```

---

## Estructura final del directorio

```
SENAE-Browser-Docker-Ubuntu/
├── Dockerfile                      [incluido]
├── ESPECIFICACIONES.md             [este archivo]
├── README.md                       [incluido]
├── build.sh                        [incluido]
├── run.sh                          [incluido]
├── jre-7u80-linux-x64.tar.gz      [DESCARGAR - Oracle]
└── libflashplayer.so               [DESCARGAR - Archive.org]
```

---

## Dependencias del sistema host (Ubuntu 24.04)

Paquetes que deben estar instalados en el host para ejecutar el contenedor:

```bash
sudo apt install docker.io docker-compose-v2
sudo usermod -aG docker $USER
# Cerrar sesión y volver a entrar para que el grupo surta efecto
```

Para entornos con Wayland (Ubuntu 24.04 por defecto):

```bash
sudo apt install xwayland
```

---

## Configuración incluida en la imagen

### Flash Player (`/etc/adobe/mms.cfg`)

```ini
RSLVerifyDigitalSignatures=0
SilentAutoUpdateEnable=0
AutoUpdateDisable=1
EOLUninstallDisable=1
EnableAllowList=0
```

### Java Security (`~/.java/deployment/security/exception.sites`)

```
https://ecuapass.aduana.gob.ec
http://ecuapass.aduana.gob.ec
https://portal.aduana.gob.ec
```

### Java Deployment (`~/.java/deployment/deployment.properties`)

```properties
deployment.security.level=MEDIUM
deployment.expiration.check.enabled=false
deployment.security.validation.ocsp=false
deployment.security.validation.crl=false
deployment.insecure.jres=ALWAYS
deployment.security.expired.certificate=true
```

### Firefox Preferences (`prefs.js`)

```javascript
user_pref("plugin.state.java", 2);
user_pref("plugin.state.npjp2", 2);
user_pref("plugin.state.npdeployjava1", 2);
user_pref("plugin.state.flash", 2);
user_pref("plugin.scan.plid.all", true);
user_pref("security.mixed_content.block_active_content", false);
user_pref("browser.startup.homepage", "https://ecuapass.aduana.gob.ec");
```

---

## Comandos de operación

### Construir la imagen

```bash
cd SENAE-Browser-Docker-Ubuntu
chmod +x build.sh run.sh
./build.sh
```

Tiempo estimado: 2-5 minutos (descarga Firefox + construye imagen).

### Ejecutar SENAE Browser

```bash
./run.sh
```

Abre Firefox 41 directamente en https://ecuapass.aduana.gob.ec

### Ejecutar con URL diferente

```bash
./run.sh https://portal.aduana.gob.ec
```

### Ver plugins cargados

```bash
./run.sh about:plugins
```

### Detener el contenedor

Cerrar la ventana del navegador o:

```bash
docker stop senae-browser
```

### Reset del perfil persistido

Si modificaste el `Dockerfile` y necesitas que el `prefs.js` baked-in vuelva a copiarse al volumen, o querés borrar todo el estado del navegador:

```bash
RESET=1 ./run.sh
```

Esto borra el volumen `senae-profile` antes de arrancar el container. La primera ejecución después tomará unos segundos extra mientras Firefox regenera el perfil.

---

## Persistencia de datos

El perfil del navegador (cookies, sesiones, historial) se almacena en un
volumen Docker nombrado `senae-profile`.

```bash
# Ver volumen
docker volume inspect senae-profile

# Eliminar datos guardados (reset completo)
docker volume rm senae-profile

# Backup del perfil
docker run --rm -v senae-profile:/data -v $(pwd):/backup ubuntu tar czf /backup/senae-backup.tar.gz /data
```

---

## Solución de problemas

### Error: "cannot open display"

```bash
xhost +local:
./run.sh
```

### Error: "permission denied" en Docker

```bash
sudo usermod -aG docker $USER
# Cerrar sesión y volver a entrar
```

### Pantalla en blanco o no carga Flash

Verificar que `libflashplayer.so` es la versión correcta:

```bash
file libflashplayer.so
# Debe mostrar: ELF 64-bit LSB shared object, x86-64
```

### Java no aparece en about:plugins

Verificar que el JRE es 64-bit:

```bash
tar tzf jre-7u80-linux-x64.tar.gz | grep libnpjp2
# Debe mostrar: jre1.7.0_80/lib/amd64/libnpjp2.so
```

### En Wayland (Ubuntu 24.04 por defecto)

Si la ventana no aparece, forzar X11:

```bash
# Opción 1: Cambiar sesión a "Ubuntu on Xorg" en la pantalla de login

# Opción 2: Usar XWayland
export DISPLAY=:0
xhost +local:
./run.sh
```

---

## Verificación post-instalación

1. Ejecutar `./run.sh about:plugins`
2. Verificar que aparecen:
   - **Java(TM) Platform SE 7 U80** - Estado: Siempre activar
   - **Shockwave Flash 25.0 r0** - Estado: Siempre activar
3. Navegar a `https://ecuapass.aduana.gob.ec`
4. La aplicación Flex debe cargar sin Error #2046

---

## Información de compatibilidad

| Sistema host | Soportado | Notas |
|---|---|---|
| Ubuntu 24.04 LTS | Sí | Probado |
| Ubuntu 22.04 LTS | Sí | Mismo procedimiento |
| Debian 12 | Sí | Instalar docker.io |
| Fedora 39+ | Sí | Usar podman o docker-ce |
| Arch Linux | Sí | Instalar docker |
| Linux Mint 22 | Sí | Basado en Ubuntu 24.04 |
| WSL2 (Windows) | Parcial | Necesita WSLg para GUI |
