#!/bin/bash
# Este script te permite personalizar los caracteres aleatorios que se pueden usar para una contraseña.
# También puedes personalizar la longitud de la contraseña y la densidad de símbolos.
# Utilizo esto como una manera rápida de crear contraseñas que expirarán en unas pocas horas
# o credenciales seguras para un primer inicio de sesión.
# Omití símbolos como '^' y '$' para evitar problemas con el script o simbolos que no se encuentren en teclados de forma sencilla.

# Define colores
NC='\033[0m' # No Color
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'

# Longitud de la contraseña por defecto
default_length=10

# Número mínimo de símbolos especiales requeridos
min_symbols=3

# Caracteres válidos para la contraseña
characters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%&*()_+{}[]|:;<>,.?/~"

# Función para generar la contraseña
generate_password() {
  local length=$1
  local password=""
  local prev_char=""
  local consecutive_letters=0
  local consecutive_numbers=0
  local symbol_count=0

  while [ ${#password} -lt $length ]; do
    char=$(LC_ALL=C tr -dc "$characters" </dev/urandom | fold -w 1 | head -n 1)

    if [[ "$char" =~ [a-zA-Z] ]]; then
      [[ "$char" == "$prev_char" ]] && ((consecutive_letters++)) || consecutive_letters=0
      [[ $consecutive_letters -lt 5 ]] && password+="$char" && prev_char="$char"
    elif [[ "$char" =~ [0-9] ]]; then
      [[ "$char" == "$prev_char" ]] && ((consecutive_numbers++)) || consecutive_numbers=0
      [[ $consecutive_numbers -lt 5 ]] && password+="$char" && prev_char="$char"
    elif [[ "$char" =~ ["!@#%&*()_+{}[\]|:;<>,.?/~"] ]]; then
      [[ $symbol_count -lt $min_symbols ]] && password+="$char" && ((symbol_count++))
    fi
  done

  echo "$password"
}

# Longitud de la contraseña proporcionada como parámetro, o usar el valor por defecto
length=${1:-$default_length}

# Generar la contraseña aleatoria
password=$(generate_password $length)

# Mostrar la contraseña generada
echo -e "${BLUE}Contraseña Generada: ${YELLOW}$password${NC}"
