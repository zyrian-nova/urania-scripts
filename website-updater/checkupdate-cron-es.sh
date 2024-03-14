#!/bin/bash
# Este script revisa si se han realizado cambios a los proyectos de git pertenecientes a desarrollos web.
# Si estos están alojados en un servidor con pocos recursos o en un homelab, puede añadirse a crontab,
# de esta manera, se puede monitorizar si los repositorios han sufrido cambios, y en caso de que así sea,
# descargar las actualizaciones.
# Para que las actualizaciones se descarguen y el sitio se vuelva a construir automáticamente, es necesario
# que los proyectos tengan sus llaves SSH y así evitar el uso de autenticación por contraseña.
# Cabe añadir, que el comando al que hace referencia la línea 21 (webupdater $PROJECT) es otro script que se
# encuentra en el mismo repositorio.
# En él (command-webupdater-es.sh), indica como añadirlo como alias en .bashrc o .zshrc

# Lista de proyectos a revisar. Añade los nombres de los proyectos separados por espacios.
PROJECTS="proyecto1 proyectoX"

# Bucle para iterar sobre cada proyecto.
for PROJECT in $PROJECTS; do
    # Configurar el directorio del repositorio local de Git basado en el nombre del proyecto.
    REPO_DIR="/var/www/$PROJECT"

    # Configurar el comando a ejecutar si hay cambios.
    UPDATE_COMMAND="webupdater $PROJECT"

    # Obtener la fecha y hora actual.
    CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')

    # Ir al directorio del repositorio.
    cd "$REPO_DIR"

    # Actualizar el repositorio local.
    git fetch

    # Revisar si hay cambios entre el HEAD local y el origin/main (ajustar a tu rama por defecto si es necesario).
    if [[ $(git diff HEAD origin/main) ]]; then
        # Usar logger para registrar el mensaje
        logger -t checkupdate "$PROJECT: Hay cambios. Ejecutando el comando de actualización..."
        # Ejecutar el comando de actualización y capturar su salida con logger
        $UPDATE_COMMAND 2>&1 | logger -t checkupdate
    else
        # Usar logger para registrar que no hay cambios
        logger -t checkupdate "$PROJECT: No hay cambios en el repositorio."
    fi
done
