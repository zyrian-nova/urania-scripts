#!/bin/bash

# Función para ejecutar un comando y verificar errores
ejecutar_comando() {
    echo "Ejecutando: $1..."
    if ! eval "$1"; then
        echo "Error al ejecutar: $1. Saliendo..."
        exit 1
    fi
}

# Verificar si se proporciona el nombre del sitio web como argumento
if [ $# -eq 0 ]; then
    echo "Uso: $0 <nombre_del_sitio_web>"
    exit 1
fi

# Asignar el nombre del sitio web desde el argumento de la línea de comandos
webSite="$1"

# Construir la ruta al directorio del sitio web
webSitePath="/var/www/${webSite}"

# Verificar si el directorio existe
if [ -d "$webSitePath" ]; then
    # Navegar a la ruta del sitio web
    cd "$webSitePath" || exit

    # Obtener los últimos cambios del repositorio
    ejecutar_comando "git pull"

    # Actualizar las dependencias de PHP a través de Composer
    ejecutar_comando "composer update"

    # Actualizar las dependencias de Node.js
    ejecutar_comando "npm install"

    # Compilar el proyecto
    ejecutar_comando "npm run build"

    echo "Actualización completada con éxito."
else
    echo "El directorio del sitio web no existe: $webSitePath"
    exit 1
fi
