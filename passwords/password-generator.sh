#!/bin/bash

# Password length (adjust the number according to your needs)
length=12

# Minimum number of required symbols
min_symbols=3

# Valid characters for the password
characters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+{}[]|:;<>,.?/~"

# Function to generate the password
generate_password() {
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
    elif [[ "$char" =~ ["!@#$%^&*()_+{}[\]|:;<>,.?/~"] ]]; then
      [[ $symbol_count -lt $min_symbols ]] && password+="$char" && ((symbol_count++))
    fi
  done

  echo "$password"
}

# Generate the random password
password=$(generate_password)

# Display the generated password
echo "Generated Password: $password"
