#!/bin/bash

# ===========================
# Author: Andrew J. McDonald
# Date: 2023-03-22
# =====================================================================================
# Description:
# This script helps updating, installing and configuring various Docker containers via
# Docker-CLI that I run on my home server.. It contains a menu for updating specific
# containers or those that have been set within the default container group array. It
# also has options for showing the mapped directory structure if set, along with global
# container variables such as timezone, puid, pgid, and restart-policy.
#
# Sharing here in case it is helpful to anyone else who prefers docker-cli to compose.
# =====================================================================================

## Set global container variables
PUID='SET PUID'
PGID='SET PGID'
TZ='SET/TIMEZONE'
RESTART_POLICY='unless-stopped'

# Set container config base directory
DOCKER_HOME="/home/docker"

# Set media/torrent paths
MEDIA_DIR="/data/media"
DEFAULT_TORRENT_DIR="/data/torrents"
PRIVATE_TORRENT_DIR"/data/torrents_private"

# Set bitwarden security token
BITWARDEN_TOKEN=SET-TOKEN

# Create array of default container functions to call at once if desired
#
# container names = function names for specfified container
default_group=("bitwarden" "jackett" "jellyfin" "jellyseerr" "radarr" "sonarr" "omada")

# Set whether to pause after container build or not (1=yes)
PAUSE=1

# Set menu options key/value store for use in menu to call
# relevant functions.
#
# Key   = menu choice
# Value = function name 
declare -A options=(
  ["1"]="bazarr"
  ["2"]="bitwarden"
  ["3"]="jackett"
  ["4"]="jellyfin"
  ["5"]="portainer"
  ["6"]="qbittorrent"
  ["7"]="radarr"
  ["8"]="sonarr"
  ["9"]="omada"
  ["10"]="tmm"
  ["11"]="jellyseerr"
  ["12"]="deluge"
  ["13"]="rtorrent"
  ["14"]="tdarr"
  ["U"]="update_group"
  ["u"]="update_group"
  ["D"]="dir_struct"
  ["d"]="dir_struct"
)

# dir_struct - Display directory structure and permissions
#
# Description: 
#   This function displays the current directory structure and permissions that the script expects. 
#   It also displays the current timezone and restart policy.
#
# Usage: 
#   This function is called by the main menu when the user selects option "D" or "d".
#
# Returns: 
#   None.
header() {
  sleep .3
  cat<< "EOF"

==============================
 Docker Update/Install Script
==============================

EOF
}

# This function prints out the directory structure, permissions, timezone, and restart policy
# of the Docker container setup. The information is displayed in a formatted manner, where the
# directory structure is visualized using ASCII art. 
dir_struct() {
  clear
  header

  # EDIT TO MAP DIRECTORY STRUCTURE
  cat<< EOF
  Directory Structure:
        /data
           | - /torrents
           |       | - /radarr
           |       | - /tv-sonnar
           |
           | - /media
                   | - /movies
                   | - /tv

  Permissions:
         User: $PUID
        Group: $PGID

  Timezone: $TZ
  Restart-Policy: $RESTART_POLICY
EOF

  pause
  clear
}

# menu - Display the menu of options for the main script
#
# Description: 
#   This function displays the menu of options for the main script. It uses the
#   global array "options" to display each option as a menu item with a number.
#   It also includes additional options to update all standard containers, show
#   the directory structure, and quit the script.
#
# Usage:
#   menu
#
# Returns:
#   None.
menu() {
  header
  for i in $(echo ${!options[@]} | tr " " "\n" | sort -n); do
    if [ $i -eq $i 2> /dev/null ]; then
      printf " (%2s) update %s\n" "$i" "${options[$i]}"
    fi
  done
  echo -e "\n  (u) update all standard containers: {$(IFS=","; echo "${default_group[*]}")}"
  echo -e "\n  (d) show directory structure"
  echo -e "\n  (q) quit\n"
}

# This function prints the final message of the Docker update script
# and shows the list of all running containers
final_print() {
  clear
  cat<< "EOF"

=================================
 Docker Update Script completed.
=================================

EOF

  echo "all running containers..."
  docker ps --format "table {{.ID}}: \t{{.Names}} \t{{.RunningFor}} \t{{.Status}}"
}

# This function pauses the script and waits for user input before
# continuing, if PAUSE variable is set to 1
pause() {
  if [ $PAUSE -eq 1 ]
    then
      read -n1 -rsp $'Press any key to continue...\n'
  fi
}

# stop_and_remove_container - Stop and remove a Docker container
#
# Description: 
#   This function stops and removes a Docker container with the given name and ID.
#   If the container is not present, it will print a message indicating so.
#
# Arguments:
#   container_name - The name of the Docker container to stop and remove.
#   container_id - The ID of the Docker container to stop and remove.
#
# Usage:
#   stop_and_remove_container "my_container" "123abc"
#
# Returns:
#   None.
function stop_and_remove_container() {
    local container_name=$1
    local container_id=$2

    if [ ! -z "$container_id" ]; then
        echo -n "Stopping $container_name container... "
        output=$(docker stop $container_name)
        if [ "$output" == "$container_name" ]; then
            echo -e "\t [ SUCCESS ]"
            echo -n "Removing $container_name container... "
            output=$(docker rm $container_name)
            if [ "$output" == "$container_name" ]; then
                echo -e "\t [ SUCCESS ]"
            else
                echo -e "\t [ FAIL ] $output"
            fi
        else
            echo -e "\t [ FAIL ] $output"
        fi
    else
        echo -e "Container $container_name not present..."
    fi
}

# tdarr - Update and initialize a Tdarr Docker container
#
# Description: 
#   This function updates and initializes a Tdarr Docker container with the latest
#   image. It first stops and removes any existing container with the same name,
#   and then pulls the latest image from the registry. It then initializes a new
#   container with the given configuration and options.
#
# Usage:
#   tdarr
#
# Returns:
#   None.
tdarr() {
clear
header

  cat<< "EOF"
==================
 Updating: Tdarr
==================
EOF

  container_name="tdarr"
  container_id=$(docker ps -a -q --filter name=$container_name)

  stop_and_remove_container $container_name $container_id

  echo "pull latest $container_name image..."
  docker pull ghcr.io/haveagitgat/tdarr

  echo "initialise $container_name container..."
  docker run -d \
    --name=tdarr \
    -v $DOCKER_HOME/tdarr/server:/app/server \
    -v $DOCKER_HOME/tdarr/configs:/app/configs \
    -v $DOCKER_HOME/tdarr/logs:/app/logs \
    -v $DOCKER_HOME/tdarr/transcode_cache:/temp \
    -v $MEDIA_DIR:/media \
    -e serverIP=0.0.0.0 \
    -e serverPort=8266 \
    -e webUIPort=8265 \
    -e internalNode=true \
    -e nodeName=MyInternalNode \
    -p 8265:8265 \
    -p 8266:8266 \
    -e TZ=$TZ \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -e NVIDIA_DRIVER_CAPABILITIES=all \
    -e NVIDIA_VISIBLE_DEVICES=all \
    --gpus=all \
    --device /dev/dri/renderD128:/dev/dri/renderD128 \
    --device /dev/dri/card0:/dev/dri/card0 \
    --log-opt max-size=10m \
    --log-opt max-file=5 \
    --network bridge \
    --restart=$RESTART_POLICY \
    ghcr.io/haveagitgat/tdarr

  echo -e "\nfinished."
  pause
  clear
}

# bazarr - Update and initialise the Bazarr Docker container
#
# Description: 
#   This function updates the Docker image for the Bazarr container, stops and removes any
#   existing containers with the same name, then initialises a new container with the updated
#   image. It uses the global variables $PUID, $PGID, $TZ, and $RESTART_POLICY to configure
#   the container. It also displays messages to indicate the progress of the update and 
#   initialisation processes, and prompts the user to press any key to continue after the
#   processes are complete.
#
# Usage:
#   bazarr
#
# Returns:
#   None.
bazarr() {
clear
header

  cat<< "EOF"
==================
 Updating: Bazarr
==================
EOF

  container_name="bazarr"
  container_id=$(docker ps -a -q --filter name=$container_name)

  stop_and_remove_container $container_name $container_id

  echo "pull latest $container_name image..."
  docker pull ghcr.io/linuxserver/bazarr

  echo "initialise $container_name container..."
  docker run -d \
    --name=bazarr \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -e TZ=$TZ \
    -e UMASK_SET=022 \
    -p 6767:6767 \
    -v $DOCKER_HOME/bazarr/config:/config \
    -v $MEDIA_DIR/movies:/data/media/movies \
    -v $MEDIA_DIR/television:/data/media/television \
    --restart=$RESTART_POLICY \
    ghcr.io/linuxserver/bazarr

  echo -e "\nfinished."
  pause
  clear
}

# bitwarden - Update and initialise the Bitwarden container
#
# Description: 
#   This function updates the Bitwarden container by stopping and removing it
#   if it exists, pulling the latest image, and initialising a new container with
#   the updated image. The container is initialised with various environment
#   variables, port mappings, and volume mappings. The function then waits for
#   user input before clearing the screen and returning.
#
# Usage:
#   bitwarden
#
# Returns:
#   None.
bitwarden() {
  clear
  header

  cat<< "EOF"
=====================
 Updating: Bitwarden
=====================
EOF

  container_name="bitwarden"
  container_id=$(docker ps -a -q --filter name=$container_name)

  stop_and_remove_container $container_name $container_id

  echo "pull latest $container_name image..."
  docker pull vaultwarden/server:latest

  echo "initialise $container_name container..."
  docker run -d \
    --name=bitwarden \
    -e TZ=$TZ \
    -u 1000:1000 \
    -e ADMIN_TOKEN=$BITWARDEN_TOKEN \
    -e LOG_LEVEL=error \
    -e EXTENDED_LOGGING=true \
    -e LOG_FILE=/data/bitwarden.log \
    -e WEBSOCKET_ENABLED=true \
    -e WEB_VAULT_ENABLED=true \
    -e INVITATIONS_ALLOWED=true \
    -e SIGNUPS_ALLOWED:false \
    -e SHOW_PASSWORD_HINT:false \
    -e ROCKET_PORT=8080 \
    -p 8343:8080 \
    -p 3012:3012 \
    -v $DOCKER_HOME/bitwarden/data/:/data/ \
    --restart=$RESTART_POLICY \
    vaultwarden/server:latest

  echo -e "\nfinished."
  pause
  clear
}

# deluge - Update and run Deluge Docker container
#
# Description: 
#   This function updates the Deluge Docker container to the latest version and
#   starts a new container with the specified configuration. It uses the "stop_and_remove_container"
#   function to stop and remove any existing container with the same name before
#   starting a new one. The function also sets environment variables and mounts volumes
#   as required for the container to function correctly. 
#
# Usage:
#   deluge
#
# Returns:
#   None.
deluge() {
  clear
  header

  cat<< "EOF"
=====================
 Updating: Deluge
=====================
EOF

  container_name="deluge"
  container_id=$(docker ps -a -q --filter name=$container_name)

  stop_and_remove_container $container_name $container_id

  echo "pull latest $container_name image..."
  docker pull lscr.io/linuxserver/deluge:latest

  echo "initialise $container_name container..."
  docker run -d  \
    --name=deluge \
    -e PUID=1000  \
    -e PGID=8675309 \
    -e UMASK_SET=022 \
    -e TZ=Australia/Melbourne \
    -e DELUGE_LOGLEVEL=error `#optional` \
    -p 8112:8112 \
    -p 60401:60401 \
    -p 60401:60401/udp \
    -v $DOCKER_HOME/deluge/config:/config \
    -v $DEFAULT_TORRENT_DIR:/data/torrents \
    -v $PRIVATE_TORRENT_DIR:/data/torrents_private \
    --restart=$RESTART_POLICY \
    lscr.io/linuxserver/deluge:latest

  echo -e "\nfinished."
  pause
  clear
}

# jackett - Update and start a Jackett Docker container
#
# Description: 
#   This function updates the Docker image for Jackett and starts a new container
#   with the specified configuration options. It uses the global variables $PUID,
#   $PGID, $TZ, and $RESTART_POLICY to configure the container. The function also
#   mounts a host directory to the container to store the configuration and
#   downloads directories.
#
# Usage:
#   jackett
#
# Returns:
#   None.
jackett() {
  clear
  header

  cat<< "EOF"
===================
 Updating: Jackett
===================
EOF

  container_name="jackett"
  container_id=$(docker ps -a -q --filter name=$container_name)

  stop_and_remove_container $container_name $container_id

  echo "pull latest $container_name image..."
  docker pull linuxserver/jackett

  echo "initialise $container_name container..."
  docker run -d \
    --name=jackett \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -e TZ=$TZ \
    -p 9117:9117 \
    -v $DOCKER_HOME/jackett/config:/config \
    -v $DEFAULT_TORRENT_DIR/jackett:/downloads \
    --restart=$RESTART_POLICY \
    linuxserver/jackett

  echo -e "\nfinished."
  pause
  clear
}

# jellyfin - Update and initialize the Jellyfin Docker container
#
# Description: 
#   This function updates the Jellyfin Docker container to the latest version,
#   and initializes a new container with the updated image. It stops and removes
#   any existing container with the name "jellyfin", and then pulls the latest
#   "jellyfin/jellyfin" image from Docker Hub. It initializes the new container
#   with the necessary environment variables and volume mounts, and exposes the
#   necessary ports for Jellyfin to function. It also sets up the necessary GPU
#   device mappings for NVIDIA hardware acceleration, if available.
#
# Usage:
#   jellyfin
#
# Returns:
#   None.
jellyfin() {
  clear
  header

  cat<< "EOF"
====================
 Updating: Jellyfin
====================
EOF

  container_name="jellyfin"
  container_id=$(docker ps -a -q --filter name=$container_name)

  stop_and_remove_container $container_name $container_id

  echo "pull latest $container_name image..."
  #docker pull linuxserver/jellyfin
  docker pull jellyfin/jellyfin

  echo "initialise $container_name container..."
  docker run -d \
    --name=jellyfin \
    --runtime=nvidia \
    --gpus all \
    --network=host \
    -e NVIDIA_DRIVER_CAPABILITIES=all \
    -e NVIDIA_VISIBLE_DEVICES=all \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -e TZ=$TZ \
    -e UMASK_SET=002 \
    -p 8096:8096 \
    -p 8920:8920 \
    -v $MEDIA_DIR/television:/data/tvshows \
    -v $MEDIA_DIR/movies:/data/movies \
    -v $DOCKER_HOME/jellyfin/config:/config \
    -v $DOCKER_HOME/jellyfin/cache:/cache \
    -v $DOCKER_HOME/jellyfin/transcode:/transcode \
    -v $DOCKER_HOME/jellyfin/dist:/jellyfin/jellyfin-web \
    --device /dev/dri/renderD128:/dev/dri/renderD128 \
    --device /dev/dri/card0:/dev/dri/card0 \
    --restart=$RESTART_POLICY \
    jellyfin/jellyfin
    #linuxserver/jellyfin

  echo -e "\nfinished."
  pause
  clear
}

# jellyseerr - Update and run the Jellyseerr container
#
# Description: 
#   This function updates the Jellyseerr container to the latest version and runs
#   it with the specified configuration and environment variables. It first stops
#   and removes any existing container with the same name to avoid conflicts. It
#   then pulls the latest image from Docker Hub and initializes the container
#   with the specified configuration and environment variables. Once the container
#   is running, the function displays a message indicating that the process is
#   finished and prompts the user to press any key to continue. Finally, the screen
#   is cleared and the function returns.
#
# Usage:
#   jellyseerr
#
# Returns:
#   None.
jellyseerr() {
  clear
  header

  cat<< "EOF"
====================
 Updating: Jellyseerr
====================
EOF

  container_name="jellyseerr"
  container_id=$(docker ps -a -q --filter name=$container_name)

  stop_and_remove_container $container_name $container_id

  echo "pull latest $container_name image..."
  docker pull fallenbagel/jellyseerr:latest

  echo "initialise $container_name container..."
  docker run -d \
    --name jellyseerr \
    -e LOG_LEVEL=debug \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -e TZ=$TZ \
    -p 5055:5055 \
    -v $DOCKER_HOME/jellyseerr/config:/app/config \
    --restart=$RESTART_POLICY \
    fallenbagel/jellyseerr:latest

  echo -e "\nfinished."
  pause
  clear
}

# omada - Update and start the Omada-Controller container
#
# Description: 
#   This function updates and starts the Omada-Controller container. It uses
#   the global variable "TZ" to set the container's timezone. It also maps
#   the container's ports to the host and mounts the container's data,
#   work, and log directories to the host's file system. Finally, it uses
#   the "stop_and_remove_container" function to stop and remove any existing
#   container with the same name before starting a new one.
#
# Usage:
#   omada
#
# Returns:
#   None.
omada() {
  clear
  header

 cat<< "EOF"
============================
 Updating: Omada-Controller
============================
EOF

  container_name="omada-controller"
  container_id=$(docker ps -a -q --filter name=$container_name)

  stop_and_remove_container $container_name $container_id

  echo "pull latest $container_name image..."
  docker pull mbentley/omada-controller:latest

  echo "initialise $container_name container..."
  docker run -d \
    --name omada-controller \
    -p 8088:8088 \
    -p 8043:8043 \
    -p 8843:8843 \
    -p 27001:27001/udp \
    -p 27002:27002 \
    -p 27017:27017 \
    -p 29810:29810 \
    -p 29810:29810/udp \
    -p 29811:29811 \
    -p 29811:29811/udp \
    -p 29812:29812 \
    -p 29812:29812/udp \
    -p 29813:29813 \
    -p 29813:29813/udp \
    -p 29814:29814 \
    -p 29814:29814/udp \
    -e TZ=$TZ \
    -e MANAGE_HTTP_PORT=8088 \
    -e MANAGE_HTTPS_PORT=8043 \
    -e PORTAL_HTTP_PORT=8088 \
    -e PORTAL_HTTPS_PORT=8843 \
    -e SHOW_SERVER_LOGS=true \
    -e SHOW_MONGODB_LOGS=false \
    -e SSL_CERT_NAME="tls.crt" \
    -e SSL_KEY_NAME="tls.key" \
    -v $DOCKER_HOME/omada/data:/opt/tplink/EAPController/data \
    -v $DOCKER_HOME/omada/work:/opt/tplink/EAPController/work \
    -v $DOCKER_HOME/omada/logs:/opt/tplink/EAPController/logs \
    --restart=$RESTART_POLICY \
    mbentley/omada-controller:latest

  echo -e "\nfinished."
  pause
  clear
}

# portainer - Update and initialize the Portainer container
#
# Description:
#   This function updates and initializes the Portainer container. It first
#   stops and removes any existing container with the same name, then pulls
#   the latest Portainer image and initializes a new container with the
#   specified configuration.
#
# Usage:
#   portainer
#
# Returns:
#   None.
portainer() {
  clear
  header

 cat<< "EOF"
=====================
 Updating: Portainer
=====================
EOF

  container_name="portainer"
  container_id=$(docker ps -a -q --filter name=$container_name)

  stop_and_remove_container $container_name $container_id

  echo "pull latest $container_name image..."
  docker pull portainer/portainer-ce

  echo "initialise $container_name container..."
  docker run -d \
    --name=portainer \
    -e USER_ID=$PUID \
    -e GROUP_ID=$PGID \
    -e TZ=$TZ \
    -p 8000:8000 \
    -p 9000:9000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $DOCKER_HOME/portainer:/data \
    --restart=$RESTART_POLICY \
    portainer/portainer-ce

  echo -e "\nfinished."
  pause
  clear
}

# radarr - Update and run Radarr container
#
# Description: 
#   This function updates the Radarr container by pulling the latest image and
#   starting a new container with the specified configurations. It uses the
#   global variables "PUID", "PGID", "TZ", and "RESTART_POLICY" to set the
#   container environment variables and options.
#
# Usage:
#   radarr
#
# Returns:
#   None.
radarr() {
  clear
  header

 cat<< "EOF"
==================
 Updating: Radarr
==================
EOF

  container_name="radarr"
  container_id=$(docker ps -a -q --filter name=$container_name)

  stop_and_remove_container $container_name $container_id

  echo "pull latest $container_name image..."
  docker pull linuxserver/radarr

  echo "initialise $container_name container..."
  docker run -d \
    --name=radarr \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -e TZ=$TZ \
    -e UMASK_SET=002 \
    -p 7878:7878 \
    -v $DOCKER_HOME/radarr/config:/config \
    -v /data:/data \
    --restart=$RESTART_POLICY \
    linuxserver/radarr

  echo -e "\nfinished."
  pause
  clear
}

# rtorrent - Update and initialize a docker container with RuTorrent
#
# Description:
#   This function updates and initializes a docker container running RuTorrent
#   with recommended settings. The container is based on the "crazymax"
#   version, as recommended by "linuxserver.io".
#
# Usage:
#   rtorrent
#
# Returns:
#   None.
rtorrent () {
  clear
  header

 cat<< "EOF"
==================
 Updating: RuTorrent
==================
EOF

  container_name="rtorrent_crazymax"
  container_id=$(docker ps -a -q --filter name=$container_name)

  stop_and_remove_container $container_name $container_id

  ## ===========================================
  ## k44sh version, fork of crazy max (think so)
  ## ===========================================
  #echo "pull latest $container_name image..."
  #docker pull k44sh/rutorrent:latest

  #echo "initialise $container_name container..."
  #docker run -d \
    #--name $container_name \
    #--ulimit nproc=65535 \
    #--ulimit nofile=32000:40000 \
    #-e PUID=$PUID \
    #-e PGID=$PGID \
    #-e TZ=$TZ \
    #-e UMASK_SET=022 \
    #-p 6881:6881/udp \
    #-p 8000:8000 \
    #-p 8084:8080 \
    #-p 9000:9000 \
    #-p 60403:60403 \
    #-v /home/docker/rtorrent/config:/config \
    #-v /home/docker/rtorrent/passwd:/passwd \
    #-v /data/torrents:/data/torrents \
    #--restart=$RESTART_POLICY \
    #k44sh/rutorrent:latest

  ## ==================================================
  ## crazy max version (recommended by linux server io)
  ## ==================================================
  echo "pull latest $container_name image..."
  docker pull crazymax/rtorrent-rutorrent:latest

  echo "initialise $container_name container..."
  docker run -d \
    --name $container_name \
    --ulimit nproc=65535 \
    --ulimit nofile=32000:40000 \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -e TZ=$TZ \
    -e UMASK_SET=022 \
    -p 6881:6881/udp \
    -p 8100:8000 \
    -p 8085:8080 \
    -p 9100:9000 \
    -p 60402:60402 \
    -v $DOCKER_HOME/rtorrent_crazymax/data:/data \
    -v $DOCKER_HOME/rtorrent_crazymax/passwd:/passwd \
    -v $DEFAULT_TORRENT_DIR:/data/torrents \
    -v $PRIVATE_TORRENT_DIR:/data/torrents_private \
    --restart=$RESTART_POLICY \
    crazymax/rtorrent-rutorrent:latest

  ## ===========================
  ## romancin version (older...)
  ## ===========================
  #echo "pull latest rutorrent image..."
  #docker pull romancin/rutorrent:latest

  #echo "initialise $container_name container..."
  #docker run -d \
    #--name=rutorrent \
    #-e PUID=$PUID \
    #-e PGID=$PGID \
    #-e TZ=$TZ \
    #-e UMASK_SET=022 \
    #-p 8113:80 \
    #-p 60402-60402:60402-60402 \
    #-v /home/docker/rutorrent/config:/config \
    #-v /data/torrents:/data/torrents \
    #--restart=$RESTART_POLICY \
    #romancin/rutorrent:latest

  echo -e "\nfinished."
  pause
  clear
}

# sonarr - Update and start a Sonarr Docker container
#
# Description:
#   This function updates the Sonarr Docker container and starts it with the
#   specified configuration. It also creates a symlink between the Sonarr
#   container's torrent directory and the /downloads directory for easier
#   access. The function uses the LinuxServer.io image of Sonarr.
#
# Usage:
#   sonarr
#
# Returns:
#   None.
sonarr() {
  clear
  header

  cat<< "EOF"
==================
 Updating: Sonarr
==================
EOF

  container_name="sonarr"
  container_id=$(docker ps -a -q --filter name=$container_name)

  stop_and_remove_container $container_name $container_id

  echo "pull latest $container_name image..."
  docker pull linuxserver/sonarr

  echo "initialise $container_name container..."
  docker run -d \
    --name=sonarr \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -e TZ=$TZ \
    -e UMASK_SET=002 \
    -p 8989:8989 \
    -v $DOCKER_HOME/sonarr/config:/config \
    -v /data:/data \
    --restart=$RESTART_POLICY \
    linuxserver/sonarr

  echo -n "symlink sonarr torrent directory to /downloads ...  "
  docker exec -it sonarr /bin/bash -c "ln -s /data/torrents/tv-sonarr/ downloads" > /dev/null 2>&1

  if [ $? -eq 0 ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo -e "\nfinished."
  pause
  clear
}

# tmm - Update and initialize the TinyMediaManager Docker container
#
# Description:
#   This function updates the TinyMediaManager Docker container to the latest
#   version, and then initializes it with the specified configuration and volume
#   mappings. This container is used to manage and organize media files, such as
#   movies and TV shows.
#
# Usage:
#   tmm
#
# Returns:
#   None.
tmm() {
  clear
  header

  cat<< "EOF"
============================
 Updating: TinyMediaManager
============================
EOF

  container_name="tmm"
  container_id=$(docker ps -a -q --filter name=$container_name)

  stop_and_remove_container $container_name $container_id

  echo "pull latest $container_name image..."
  docker pull romancin/tinymediamanager:latest-v4

  echo "initialise $container_name container..."
  docker run -d \
    --name=tmm \
    -e TZ=$TZ \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -v $DOCKER_HOME/tinymediamanager/config:/config \
    -v $MEDIA_DIR/movies:/data/media/movies \
    -v $MEDIA_DIR/television:/data/media/television \
    -v $DEFAULT_TORRENT_DIR:/data/torrents \
    -p 5800:5800 \
    --restart=$RESTART_POLICY \
    romancin/tinymediamanager:latest-v4

  echo -e "\nfinished."
  pause
  clear
}

# qbittorrent - Update and initialise the qbittorrent Docker container
#
# Description:
#   This function updates the qbittorrent Docker container to the latest version
#   or a specific version, depending on which image is pulled. It then initialises
#   the container with the necessary environment variables, volumes and port mappings.
#
# Usage:
#   qbittorrent
#
# Returns:
#   None.
qbittorrent() {
  clear
  header

  cat<< "EOF"
=======================
 Updating: Qbittorrent
=======================
EOF

  container_name="qbittorrent"
  container_id=$(docker ps -a -q --filter name=$container_name)

  stop_and_remove_container $container_name $container_id

  echo "pull latest $container_name image..."
  docker pull linuxserver/qbittorrent
  #docker pull linuxserver/qbittorrent:14.2.5.99202004250119-7015-2c65b79ubuntu18.04.1-ls93

  echo "initialise $container_name container..."
  docker run -d \
    --name=qbittorrent \
    -e TZ=$TZ \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -e UMASK_SET=002 \
    -e WEBUI_PORT=8081 \
    -p 60402:60402 \
    -p 60402:60402/udp \
    -p 8081:8081 \
    -v $DOCKER_HOME/qbittorrent/config:/config \
    -v $DEFAULT_TORRENT_DIR:/data/torrents \
    -v $PRIVATE_TORRENT_DIR:/data/torrents_private \
    --restart=$RESTART_POLICY \
    linuxserver/qbittorrent

  # INFO: use old ver. if torrent naming issue present
  #     linuxserver/qbittorrent:14.2.5.99202004250119-7015-2c65b79ubuntu18.04.1-ls93
  # INFO: otherwise, use current
  #     linuxserver/qbittorrent

  echo -e "\nfinished."
  pause
  clear
}

# update_group - Update the default group of applications
#
# Description:
#   This function updates the default group of applications by calling each function
#   in the group
#
# Usage:
#   update_group
#
# Returns:
#   None.
update_group() {
  # Turn user request to continue off
  #PAUSE=0

  # Loop through and call each function
  for i in "${default_group[@]}"; do
    $i
  done

  # Turn user request to continue back on
  #PAUSE=1
}

# main - The main function that displays the menu and handles user input
#
# Description:
#   This function is the main entry point of the script. It displays a menu of options to the user and
#   prompts for input. It then processes the user's input and either executes the corresponding function,
#   or prints an error message if the input is invalid.
#
# Usage:
#   main
#
# Returns:
#   None.
main() {
  menu
  while :
  do
    read -r -p "Please enter your choice: " choice
    if [ "${options[$choice]}" != "" ]; then
        "${options[$choice]}";
        menu
    else
        case "$choice" in
        "U"|"u")  update_group; menu ;;
        "D"|"d")  dir_struct;   menu ;;
        "Q"|"q")  final_print;  break ;;
        *) echo "Invalid option, try again..." ;;
        esac
    fi
  done
  exit
}

## execute main
clear
main
