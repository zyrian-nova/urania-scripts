#!/bin/bash
# Para poder utilizar este script como si fuese un comando en la CLI, es necesario que
# este sea utilizado como un alias. El alias elegido y que se usa en el resto de scripts
# es el de: webupdater.
# Alias en BASH y ZSH
# Elimina los # al pegar en el archivo .bashrc o .zshrc que se encuentra en tu directorio /home/$USER
# webupdater() {
#    local webSite="$1"
#    ~/urania-scripts/website-updater/command-webupdater-es.sh "$webSite" "${@:2}"
#}

# Función para ejecutar el comando y verificar errores
execute_command() {
    echo "Ejecutando: $1..." | tee >(logger -t webupdater)
    if ! eval "$1"; then
        echo "Fallo al ejecutar: $1. Saliendo..." | tee >(logger -t webupdater)
        exit 1
    else
        echo "Ejecutado con éxito: $1" | tee >(logger -t webupdater)
    fi
}

# Verificar si se proporcionó el nombre del sitio web como argumento al usarlo
if [ $# -eq 0 ]; then
    echo "Uso: $0 <website_name>" | tee >(logger -t webupdater "Error de uso: No se proporcionó el nombre del sitio.")
    exit 1
fi

# Asignar el directorio del nombre del sitio web (o proyecto) del argumento de la línea de comandos
webSite="$1"

# Construir la ruta al directorio del sitio web
webSitePath="/var/www/${webSite}"

# Verificar si el directorio ya existe
if [ -d "$webSitePath" ]; then
    # Navegar a la ruta del sitio web
    cd "$webSitePath" || exit

    # Obtener los últimos cambios del repositorio (si no hay clave SSH, pedirá las credenciales)
    execute_command "git pull"

    # Actualizar dependencias de PHP a través de Composer
    execute_command "composer update"

    # Actualizar dependencias de Node.js
    execute_command "npm install"

    # Construir el proyecto
    execute_command "npm run build"

    # Mensaje de éxito
    echo "Actualización completada con éxito para $webSite." | tee >(logger -t webupdater)
else
    # Mensaje de directorio no existente
    echo "El directorio del sitio web no existe: $webSitePath" | tee >(logger -t webupdater)
    exit 1
fi
