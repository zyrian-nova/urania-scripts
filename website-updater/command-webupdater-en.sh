#!/bin/bash

# Function to execute the command and check for errors
execute_command() {
    echo "Running: $1..."
    if ! eval "$1"; then
        echo "Failed to execute: $1. Exiting..."
        exit 1
    fi
}

# Check if the website name is provided as an argument when using it
if [ $# -eq 0 ]; then
    echo "Usage: $0 <website_name>"
    exit 1
fi

# Assign the website name directoy (or project) from the command line argument
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
    echo "Update completed successfully."
else
    # Not directory message
    echo "The website directory does not exist: $webSitePath"
    exit 1
fi
