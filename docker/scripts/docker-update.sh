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

# Set global container variables
PUID='1000'
PGID='1000'
TZ='COUNTRY/CITY'
RESTART_POLICY='unless-stopped'

# Set bitwarden security token
BITWARDEN_TOKEN=

# Set container config base directory
DOCKER_HOME="/path/to/docker-base-path"

# Set media dir path
MEDIA_DIR="/path/to/media"

# Set torrent dir path/s - I use both public and private trackers
DEFAULT_TORRENT_DIR="/path/to/default-torrents"
PRIVATE_TORRENT_DIR="/path/to/private-torrents"

# set whether to pause after container build or not (1=yes)
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

# Create array of default container functions to call at once if desired
# container names = function names for specfified container
default_group=("bitwarden" "jackett" "jellyfin" "jellyseerr" "radarr" "sonarr" "omada")

# Description:
#   This function displays the current directory structure and permissions that the script
#   expects. It also displays the current timezone and restart policy.
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

# Description:
#   This function prints out the directory structure, permissions, timezone, and restart
#   policy of the Docker container setup. The information is displayed in a formatted
#   manner, where the directory structure is visualized using ASCII art.
# Returns:
#   None.
dir_struct() {
  clear
  header
  
  # Get directory trees - depth=1, only dirs
  home_tree=$(tree $DOCKER_HOME -L 1 -d | grep -v "directories" | sed 's/^/      /')
  media_tree=$(tree $MEDIA_DIR -L 1 -d | grep -v "directories" | sed 's/^/      /')
  default_torrent_tree=$(tree $DEFAULT_TORRENT_DIR -L 1 -d | grep -v "directories" | sed 's/^/      /')
  private_torrent_tree=$(tree $PRIVATE_TORRENT_DIR -L 1 -d | grep -v "directories" | sed 's/^/      /')

  cat<< EOF
  Docker Home Directory Structure:
$home_tree
  Media Directory Structure:
$media_tree
  Default Torrent Directory Structure:
$default_torrent_tree
  Private Torrent Directory Structure:
$private_torrent_tree
  Permissions:
	 User: $PUID
	Group: $PGID
  
  Timezone: $TZ
  
EOF

  pause
  clear
}

# Description:
#   This function displays the menu of options for the main script. It uses the
#   global array "options" to display each option as a menu item with a number.
#   It also includes additional options to update all standard containers, show
#   the directory structure, and quit the script.
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

# Description:
#   This function prints the final message of the Docker update script
#   and shows the list of all running containers
# Returns:
#   None.
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

# Description:
#   This function pauses the script and waits for user input before
#   continuing, if PAUSE variable is set to 1
# Returns:
#   None.
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

# =================================================================================
# CONTAINER UPDATE FUNCTIONS
# Description:
#   These functions update and initialise respective Docker containers with the
#   latest image. They first stop and remove any existing container with the same
#   name as the container to be updated, and then pull the latest image from their
#   respective repository. They then initializes a new container with the prior
#   containers configuration and options as set within each update function.
# ==================================================================================

# TDARR CONTAINER UPDATE FUNCTION
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

  echo
  echo "finished."
  pause
  clear
}

# BAZARR CONTAINER UPDATE FUNCTION
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
    -v $MEDIA_DIR/movies:$MEDIA_DIR/movies \
    -v $MEDIA_DIR/television:$MEDIA_DIR/television \
    --restart=$RESTART_POLICY \
    ghcr.io/linuxserver/bazarr

  echo
  echo "finished."
  pause
  clear
}

# BITWARDEN CONTAINER UPDATE FUNCTION
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

  echo
  echo "finished."
  pause
  clear
}

# DELUGE CONTAINER UPDATE FUNCTION
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
    -v $DEFAULT_TORRENT_DIR:$DEFAULT_TORRENT_DIR \
    -v $PRIVATE_TORRENT_DIR:$PRIVATE_TORRENT_DIR \
    --restart=$RESTART_POLICY \
    lscr.io/linuxserver/deluge:latest

  echo
  echo "finished."
  pause
  clear
}

# JACKETT CONTAINER UPDATE FUNCTION
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

  echo
  echo "finished."
  pause
  clear
}

# JELLYFIN CONTAINER UPDATE FUNCTION
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

  echo
  echo "finished."
  pause
  clear
}

# JELLYSEERR CONTAINER UPDATE FUNCTION
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

  echo
  echo "finished."
  pause
  clear
}

# OMADA CONTROLLER CONTAINER UPDATE FUNCTION
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

  echo
  echo "finished."
  pause
  clear
}

# PORTAINER CONTAINER UPDATE FUNCTION
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

  echo
  echo "finished."
  pause
  clear
}

# RADARR CONTAINER UPDATE FUNCTION
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

  echo
  echo "finished."
  pause
  clear
}

# RTORRENT CONTAINER UPDATE FUNCTION
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
    -v $DEFAULT_TORRENT_DIR:$DEFAULT_TORRENT_DIR \
    -v $PRIVATE_TORRENT_DIR:$PRIVATE_TORRENT_DIR \
    --restart=$RESTART_POLICY \
    crazymax/rtorrent-rutorrent:latest

  echo
  echo "finished."
  pause
  clear
}

# SONARR CONTAINER UPDATE FUNCTION
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

  echo
  echo "finished."
  pause
  clear
}

# TINY MEDIA MANAGER CONTAINER UPDATE FUNCTION
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
    -v $MEDIA_DIR/movies:$MEDIA_DIR/movies \
    -v $MEDIA_DIR/television:$MEDIA_DIR/television \
    -v $DEFAULT_TORRENT_DIR:$DEFAULT_TORRENT_DIR \
    -p 5800:5800 \
    --restart=$RESTART_POLICY \
    romancin/tinymediamanager:latest-v4

  echo
  echo "finished."
  pause
  clear
}

# QBITTORRENT CONTAINER UPDATE FUNCTION
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
    -v $DEFAULT_TORRENT_DIR:$DEFAULT_TORRENT_DIR \
    -v $PRIVATE_TORRENT_DIR:$PRIVATE_TORRENT_DIR \
    --restart=$RESTART_POLICY \
    linuxserver/qbittorrent

  # INFO: use old ver. if torrent naming issue present
  #     linuxserver/qbittorrent:14.2.5.99202004250119-7015-2c65b79ubuntu18.04.1-ls93
  # INFO: otherwise, use current
  #     linuxserver/qbittorrent

  echo
  echo "finished."
  pause
  clear
}

# =================================
# CONTAINER UPDATE FUNCTIONS - END
# =================================

# Description:
#   This function updates the default group of applications by calling each function
#   in the group
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

# Description:
#   This function is the main entry point of the script. It displays a menu of options to
#   the user and prompts for input. It then processes the user's input and either executes
#   the corresponding function, or prints an error message if the input is invalid.
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

# clear screen and execute main fcnction
clear
main
