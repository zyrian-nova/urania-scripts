#!/bin/bash

# Function to execute a command and check for errors
execute_command() {
    echo "Running: $1..."
    if ! eval "$1"; then
        echo "Failed to execute: $1. Exiting..."
        exit 1
    fi
}

# Prompt the user for the website directory name
echo "Please enter the website directory name:"
read webSite

# Build the path to the website directory
webSitePath="/var/www/${webSite}"

# Check if the directory exists
if [ -d "$webSitePath" ]; then
    # Navigate to the website path
    cd "$webSitePath" || exit

    # Pull the latest changes from the repository
    execute_command "git pull"

    # Update PHP dependencies via Composer
    execute_command "composer update"

    # Update Node.js dependencies
    execute_command "npm install"

    # Build the project
    execute_command "npm run build"

    echo "Update completed successfully."
else
    echo "The website directory does not exist: $webSitePath"
    exit 1
fi
