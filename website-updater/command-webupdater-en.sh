#!/bin/bash
# To use this script as if it were a command in the CLI, it needs to be utilized as an alias.
# The chosen alias used in the rest of the scripts is: webupdater.
# Alias in BASH and ZSH
# Remove the # when pasting into the .bashrc or .zshrc file located in your /home/$USER directory
# webupdater() {
#    local webSite="$1"
#    ~/urania-scripts/website-updater/command-webupdater-es.sh "$webSite" "${@:2}"
#}

# Function to execute the command and check for errors
execute_command() {
    echo "Running: $1..." | tee >(logger -t webupdater)
    if ! eval "$1"; then
        echo "Failed to execute: $1. Exiting..." | tee >(logger -t webupdater)
        exit 1
    else
        echo "Successfully executed: $1" | tee >(logger -t webupdater)
    fi
}

# Check if the website name is provided as an argument when using it
if [ $# -eq 0 ]; then
    echo "Usage: $0 <website_name>" | tee >(logger -t webupdater "Usage error: No website name provided.")
    exit 1
fi

# Assign the website name directory (or project) from the command line argument
webSite="$1"

# Build the path to the website directory
webSitePath="/var/www/${webSite}"

# Check if the directory already exists
if [ -d "$webSitePath" ]; then
    # Navigate to the website path
    cd "$webSitePath" || exit

    # Pull the latest changes from the repository (if there is no SSH key, it will ask for the credentials)
    execute_command "git pull"

    # Update PHP dependencies via Composer
    execute_command "composer update"

    # Update Node.js dependencies
    execute_command "npm install"

    # Build the project
    execute_command "npm run build"

    # Successful message
    echo "Update completed successfully for $webSite." | tee >(logger -t webupdater)
else
    # Not directory message
    echo "The website directory does not exist: $webSitePath" | tee >(logger -t webupdater)
    exit 1
fi
