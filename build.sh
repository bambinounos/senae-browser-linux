#!/bin/bash
set -e

# Verificar archivos necesarios
if [ ! -f "jre-7u80-linux-x64.tar.gz" ] && [ ! -f "jdk-7u80-linux-x64.tar.gz" ]; then
    echo "ERROR: Falta jre-7u80-linux-x64.tar.gz (o jdk-7u80-linux-x64.tar.gz)"
    echo "Descargar desde: https://www.oracle.com/java/technologies/javase/javase7-archive-downloads.html"
    exit 1
fi

if [ ! -f "libflashplayer.so" ]; then
    echo "ERROR: Falta libflashplayer.so"
    echo "Descargar desde: https://archive.org/details/flashplayerarchive"
    echo "  -> fp_25.0.0.171_archive.zip -> extraer libflashplayer.so"
    exit 1
fi

echo "Construyendo imagen senae-browser..."
docker build -t senae-browser:latest .
echo ""
echo "Imagen construida exitosamente: senae-browser:latest"
echo "Ejecutar con: ./run.sh"
