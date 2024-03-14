#!/bin/bash
# This script checks for changes made to git projects related to web development.
# If these are hosted on a server with few resources or in a homelab, it can be added to crontab.
# This way, you can monitor if the repositories have undergone changes, and if so,
# download the updates.
# To have the updates downloaded and the site rebuilt automatically, it is necessary
# that the projects have their SSH keys to avoid the use of password authentication.
# It is worth mentioning that the command referenced in line 21 (webupdater $PROJECT) is another
# script that is located in the same repository.
# In it (command-webupdater-en.sh), it indicates how to add it as an alias in .bashrc or .zshrc.

# List of projects to check. Add the names of the projects separated by spaces.
PROJECTS="project1 projectX"

# Loop to iterate over each project.
for PROJECT in $PROJECTS; do
    # Set up the local Git repository directory based on the project name.
    REPO_DIR="/var/www/$PROJECT"

    # Set up the command to execute if there are changes.
    UPDATE_COMMAND="webupdater $PROJECT"

    # Get the current date and time.
    CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')

    # Go to the repository directory.
    cd "$REPO_DIR"

    # Update the local repository.
    git fetch

    # Check for changes between the local HEAD and origin/main (adjust to your default branch if necessary).
    if [[ $(git diff HEAD origin/main) ]]; then
        # Use logger to record the message
        logger -t checkupdate "$PROJECT: Changes detected. Executing the update command..."
        # Execute the update command and capture its output with logger
        $UPDATE_COMMAND 2>&1 | logger -t checkupdate
    else
        # Use logger to record that there are no changes
        logger -t checkupdate "$PROJECT: No changes in the repository."
    fi
done
