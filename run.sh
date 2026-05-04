#!/bin/bash
set -e

# Reset opcional del perfil persistido: RESET=1 ./run.sh
if [ "${RESET:-0}" = "1" ]; then
    docker volume rm senae-profile 2>/dev/null || true
fi

# Cookie X11 portable: rewrite family field a FFFF (FamilyWild) para que sirva
# desde cualquier hostname (el container tiene un hostname distinto al host).
XAUTH_FILE="/tmp/.senae-browser-xauth"
rm -f "$XAUTH_FILE"
touch "$XAUTH_FILE"
xauth nlist "$DISPLAY" 2>/dev/null | sed -e 's/^..../ffff/' | xauth -f "$XAUTH_FILE" nmerge - 2>/dev/null || true
chmod 644 "$XAUTH_FILE"

# Hedge adicional: autorizar conexiones X11 locales
xhost +local: 2>/dev/null || true

# GID del socket X11 -- el usuario "senae" (UID 1001) dentro del container
# necesita pertenecer a este grupo para poder conectarse al socket
# (que tiene permisos rwxrwxr-x del grupo del host, normalmente GID 1000).
# OJO: el directorio /tmp/.X11-unix suele ser root:root (GID 0), pero el
# socket Xn DENTRO es del usuario que lanzó X. Hay que stat al socket, no al dir.
DISP_NUM=$(echo "$DISPLAY" | sed -E 's/^[^:]*:([0-9]+).*/\1/')
X11_SOCKET="/tmp/.X11-unix/X${DISP_NUM:-0}"
X11_GID=$(stat -c '%g' "$X11_SOCKET" 2>/dev/null || echo 1000)

docker run --rm --init \
    -e DISPLAY="$DISPLAY" \
    -e XAUTHORITY=/tmp/.docker-xauth \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v "$XAUTH_FILE:/tmp/.docker-xauth:ro" \
    -v senae-profile:/home/senae/.senae-profile \
    --group-add "$X11_GID" \
    --name senae-browser \
    senae-browser:latest "$@"
