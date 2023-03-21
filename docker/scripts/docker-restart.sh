#!/bin/bash

# ===========================
# Author: Andrew J. McDonald
# Date: 2023-03-22
# ============================================================================
# Description: simple script to stop and restart all and only currently
# running docker containers
# ============================================================================

# Get list of currently running containers
echo -n "Currently running docker containers: "
containers_to_restart=$(docker ps --format "{{.Names}}" | sort)

# check if there are any running containers
if [ -z "$containers_to_restart" ]; then
    echo "No running containers found."
    exit 1
fi

# Convert the list to an array
readarray -t containers_to_restart <<< "$containers_to_restart"

# Print the list of containers to restart
echo -e "${containers_to_restart[@]}"

# Stop running containers
echo -e "\nStopping containers"
if ! docker stop "${containers_to_restart[@]}"; then
    echo "Failed to stop containers."
    exit 1
fi

# Print 5 second counter...
echo -ne "\nWaiting for 5 seconds: "
for (( i=1; i<=5; i++ )); do
  echo -n " $i"
  sleep 1
done

# Restart previously stopped containers
echo -e "\n\nRestarting containers"
if ! docker start "${containers_to_restart[@]}"; then
    echo "Failed to restart containers."
    exit 1
fi

echo -e "\nFinished!"
exit 0
