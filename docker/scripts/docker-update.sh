#!/bin/bash

## ===============================================================
## This script is used to update and install Docker containers.
##
## It includes options for updating individual containers or a
## group of default containers, as well as displaying information
## about the directory structure. 
## ===============================================================

# global variables
PUID='1000'
PGID='8675309'
TZ='Australia/Melbourne'
BITWARDEN_TOKEN='SET-TOKEN'
RESTART_POLICY='unless-stopped'

# set whether to pause after container build or not (1=yes)
PAUSE=1

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
  ["U"]="update_group"
  ["u"]="update_group"
  ["D"]="dir_struct"
  ["d"]="dir_struct"
)

# Create array of default containers
default_group=("bitwarden" "jackett" "jellyfin" "jellyseerr" "radarr" "sonarr" "omada")

header() {
  sleep .3
  cat<< "EOF"

==============================
 Docker Update/Install Script
==============================

EOF
}

dir_struct() {
  clear
  header

  cat<< "EOF"
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
         User: dorothy [1000]
        Group: media   [8675309]

  Timezone: Australia/Melbourne
EOF

  pause
  clear
}

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

pause() {
  if [[ $PAUSE -eq 1 ]]; then
      read -n1 -rsp $'Press any key to continue...\n'
  fi
}

stop_and_remove_container() {
  container_name=$1
  container_id=$(docker ps -a -q --filter name=container_name)
  
  if [ ! -z "$container_id" ]; then
      echo -n "stopping $container_name container... "
      output=$(docker stop $container_name)
      if [ "$output" == "$container_name" ]; then
          echo -e "\t [ SUCCESS ]"
          echo -n "removing $container_name container... "
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
      echo -e "\t container not present"
  fi
}

bazarr() {
clear
header

  cat<< "EOF"
==================
 Updating: Bazarr
==================
EOF

  container_name="bazarr"
  stop_and_remove_container container_name
  #container_id=$(docker ps -a -q --filter name=$container_name)

  #if [ ! -z "$container_id" ]; then
  #    echo -n "stopping $container_name container... "
  #    output=$(docker stop $container_name)
  #    if [ "$output" == "$container_name" ]; then
  #        echo -e "\t [ SUCCESS ]"
  #        echo -n "removing $container_name container... "
  #        output=$(docker rm $container_name)
  #        if [ "$output" == "$container_name" ]; then
  #            echo -e "\t [ SUCCESS ]"
  #        else
  #            echo -e "\t [ FAIL ] $output"
  #        fi
  #    else
  #        echo -e "\t [ FAIL ] $output"
  #    fi
  #else
  #    echo -e "\t container not present"
  #fi

  echo "pull latest bazarr image..."
  docker pull ghcr.io/linuxserver/bazarr

  echo "initialise bazarr container..."
  docker run -d \
    --name=$container_name  \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -e TZ=$TZ \
    -e UMASK_SET=022 \
    -p 6767:6767 \
    -v /home/docker/bazarr/config:/config \
    -v /data/media/movies:/data/media/movies \
    -v /data/media/television:/data/media/television \
    --restart=$RESTART_POLICY \
    ghcr.io/linuxserver/bazarr

  echo
  echo "finished."
  pause
  clear
}

bitwarden() {
  clear
  header

  cat<< "EOF"
=====================
 Updating: Bitwarden
=====================
EOF

  container_name="bitwarden"
  stop_and_remove_container container_name
  #container_id=$(docker ps -a -q --filter name=$container_name)

  #if [ ! -z "$container_id" ]; then
  #    echo -n "stopping $container_name container... "
  #    output=$(docker stop $container_name)
  #    if [ "$output" == "$container_name" ]; then
  #        echo -e "\t [ SUCCESS ]"
  #        echo -n "removing $container_name container... "
  #        output=$(docker rm $container_name)
  #        if [ "$output" == "$container_name" ]; then
  #            echo -e "\t [ SUCCESS ]"
  #        else
  #            echo -e "\t [ FAIL ] $output"
  #        fi
  #    else
  #        echo -e "\t [ FAIL ] $output"
  #    fi
  #else
  #    echo -e "\t container not present"
  #fi

  echo "pull latest bitwarden image..."
  docker pull vaultwarden/server:latest

  echo "initialise bitwarden container..."
  docker run -d \
    --name=$container_name \
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
    -v /home/docker/bitwarden/data/:/data/ \
    --restart=$RESTART_POLICY \
    vaultwarden/server:latest

  echo
  echo "finished."
  pause
  clear
}

deluge() {
  clear
  header

  cat<< "EOF"
=====================
 Updating: Deluge
=====================
EOF

  container_name="deluge"
  stop_and_remove_container container_name
  #container_id=$(docker ps -a -q --filter name=$container_name)

  #if [ ! -z "$container_id" ]; then
  #    echo -n "stopping $container_name container... "
  #    output=$(docker stop $container_name)
  #    if [ "$output" == "$container_name" ]; then
  #        echo -e "\t [ SUCCESS ]"
  #        echo -n "removing $container_name container... "
  #        output=$(docker rm $container_name)
  #        if [ "$output" == "$container_name" ]; then
  #            echo -e "\t [ SUCCESS ]"
  #        else
  #            echo -e "\t [ FAIL ] $output"
  #        fi
  #    else
  #        echo -e "\t [ FAIL ] $output"
  #    fi
  #else
  #    echo -e "\t container not present"
  #fi

  echo "pull latest deluge image..."
  docker pull lscr.io/linuxserver/deluge:latest

  echo "initialise deluge container..."
  docker run -d  \
    --name=$container_name  \
    -e PUID=1000  \
    -e PGID=8675309 \
    -e UMASK_SET=022 \
    -e TZ=Australia/Melbourne \
    -e DELUGE_LOGLEVEL=error `#optional` \
    -p 8112:8112 \
    -p 60401:60401 \
    -p 60401:60401/udp \
    -v /home/docker/deluge/config:/config \
    -v /data/torrents:/data/torrents \
    --restart=$RESTART_POLICY \
    lscr.io/linuxserver/deluge:latest

  echo
  echo "finished."
  pause
  clear
}

jackett() {
  clear
  header

  cat<< "EOF"
===================
 Updating: Jackett
===================
EOF

  container_name="jackett"
  stop_and_remove_container container_name
  #container_id=$(docker ps -a -q --filter name=$container_name)

  #if [ ! -z "$container_id" ]; then
  #    echo -n "stopping $container_name container... "
  #    output=$(docker stop $container_name)
  #    if [ "$output" == "$container_name" ]; then
  #        echo -e "\t [ SUCCESS ]"
  #        echo -n "removing $container_name container... "
  #        output=$(docker rm $container_name)
  #        if [ "$output" == "$container_name" ]; then
  #            echo -e "\t [ SUCCESS ]"
  #        else
  #            echo -e "\t [ FAIL ] $output"
  #        fi
  #    else
  #        echo -e "\t [ FAIL ] $output"
  #    fi
  #else
  #    echo -e "\t container not present"
  #fi

  echo "pull latest jackett image..."
  docker pull linuxserver/jackett

  echo "initialise jackett container..."
  docker run -d \
    --name=$container_name  \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -e TZ=$TZ \
    -p 9117:9117 \
    -v /home/docker/jackett/config:/config \
    -v /data/torrents/jackett:/downloads \
    --restart=$RESTART_POLICY \
    linuxserver/jackett

  echo
  echo "finished."
  pause
  clear
}

jellyfin() {
  clear
  header

  cat<< "EOF"
====================
 Updating: Jellyfin
====================
EOF

  container_name="jellyfin"
  stop_and_remove_container container_name
  #container_id=$(docker ps -a -q --filter name=$container_name)

  #if [ ! -z "$container_id" ]; then
  #    echo -n "stopping $container_name container... "
  #    output=$(docker stop $container_name)
  #    if [ "$output" == "$container_name" ]; then
  #        echo -e "\t [ SUCCESS ]"
  #        echo -n "removing $container_name container... "
  #        output=$(docker rm $container_name)
  #        if [ "$output" == "$container_name" ]; then
  #            echo -e "\t [ SUCCESS ]"
  #        else
  #            echo -e "\t [ FAIL ] $output"
  #        fi
  #    else
  #        echo -e "\t [ FAIL ] $output"
  #    fi
  #else
  #    echo -e "\t container not present"
  #fi

  echo "pull latest jellyfin image..."
  docker pull linuxserver/jellyfin

  echo "initialise jellyfin container..."
  docker run -d \
    --name=$container_name  \
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
    -v /data/media/television:/data/tvshows \
    -v /data/media/movies:/data/movies \
    -v /home/docker/jellyfin/config:/config \
    -v /home/docker/jellyfin/transcode:/transcode \
    --device /dev/dri/renderD128:/dev/dri/renderD128 \
    --device /dev/dri/card0:/dev/dri/card0 \
    --restart=$RESTART_POLICY \
    linuxserver/jellyfin

  echo
  echo "finished."
  pause
  clear
}

jellyseerr() {
  clear
  header

  cat<< "EOF"
====================
 Updating: Jellyseerr
====================
EOF

  container_name="jellyseerr"
  stop_and_remove_container container_name
  #container_id=$(docker ps -a -q --filter name=$container_name)

  #if [ ! -z "$container_id" ]; then
  #    echo -n "stopping $container_name container... "
  #    output=$(docker stop $container_name)
  #    if [ "$output" == "$container_name" ]; then
  #        echo -e "\t [ SUCCESS ]"
  #        echo -n "removing $container_name container... "
  #        output=$(docker rm $container_name)
  #        if [ "$output" == "$container_name" ]; then
  #            echo -e "\t [ SUCCESS ]"
  #        else
  #            echo -e "\t [ FAIL ] $output"
  #        fi
  #    else
  #        echo -e "\t [ FAIL ] $output"
  #    fi
  #else
  #    echo -e "\t container not present"
  #fi

  echo "pull latest jellyseerr image..."
  docker pull fallenbagel/jellyseerr:latest

  docker run -d \
    --name=$container_name  \
    -e LOG_LEVEL=debug \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -e TZ=$TZ \
    -p 5055:5055 \
    -v /home/docker/jellyseerr/config:/app/config \
    --restart=$RESTART_POLICY \
    fallenbagel/jellyseerr:latest

  echo
  echo "finished."
  pause
  clear
}

omada() {
  clear
  header

 cat<< "EOF"
============================
 Updating: Omada-Controller
============================
EOF

  container_name="omada-controller"
  stop_and_remove_container container_name
  #container_id=$(docker ps -a -q --filter name=$container_name)

  #if [ ! -z "$container_id" ]; then
  #    echo -n "stopping $container_name container... "
  #    output=$(docker stop $container_name)
  #    if [ "$output" == "$container_name" ]; then
  #        echo -e "\t [ SUCCESS ]"
  #        echo -n "removing $container_name container... "
  #        output=$(docker rm $container_name)
  #        if [ "$output" == "$container_name" ]; then
  #            echo -e "\t [ SUCCESS ]"
  #        else
  #            echo -e "\t [ FAIL ] $output"
  #        fi
  #    else
  #        echo -e "\t [ FAIL ] $output"
  #    fi
  #else
  #    echo -e "\t container not present"
  #fi

  echo "pull latest omada-controller image..."
  docker pull mbentley/omada-controller:latest

  echo "initialise omada-controller container..."
  docker run -d \
    --name=$container_name  \
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
    -v /home/docker/omada/data:/opt/tplink/EAPController/data \
    -v /home/docker/omada/work:/opt/tplink/EAPController/work \
    -v /home/docker/omada/logs:/opt/tplink/EAPController/logs \
        --restart=$RESTART_POLICY \
    mbentley/omada-controller:latest

  echo
  echo "finished."
  pause
  clear
}

portainer() {
  clear
  header

 cat<< "EOF"
=====================
 Updating: Portainer
=====================
EOF

  container_name="portainer"
  stop_and_remove_container container_name
  #container_id=$(docker ps -a -q --filter name=$container_name)

  #if [ ! -z "$container_id" ]; then
  #    echo -n "stopping $container_name container... "
  #    output=$(docker stop $container_name)
  #    if [ "$output" == "$container_name" ]; then
  #        echo -e "\t [ SUCCESS ]"
  #        echo -n "removing $container_name container... "
  #        output=$(docker rm $container_name)
  #        if [ "$output" == "$container_name" ]; then
  #            echo -e "\t [ SUCCESS ]"
  #        else
  #            echo -e "\t [ FAIL ] $output"
  #        fi
  #    else
  #        echo -e "\t [ FAIL ] $output"
  #    fi
  #else
  #    echo -e "\t container not present"
  #fi

  echo "pull latest portainer image..."
  docker pull portainer/portainer-ce

  echo "initialise portainer container..."
  docker run -d \
    --name=$container_name  \
    -e USER_ID=$PUID \
    -e GROUP_ID=$PGID \
    -e TZ=$TZ \
    -p 8000:8000 \
    -p 9000:9000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /home/docker/portainer:/data \
        --restart=$RESTART_POLICY \
    portainer/portainer-ce

  echo
  echo "finished."
  pause
  clear
}

radarr() {
  clear
  header

 cat<< "EOF"
==================
 Updating: Radarr
==================
EOF

  container_name="radarr"
  stop_and_remove_container container_name
  #container_id=$(docker ps -a -q --filter name=$container_name)

  #if [ ! -z "$container_id" ]; then
  #    echo -n "stopping $container_name container... "
  #    output=$(docker stop $container_name)
  #    if [ "$output" == "$container_name" ]; then
  #        echo -e "\t [ SUCCESS ]"
  #        echo -n "removing $container_name container... "
  #        output=$(docker rm $container_name)
  #        if [ "$output" == "$container_name" ]; then
  #            echo -e "\t [ SUCCESS ]"
  #        else
  #            echo -e "\t [ FAIL ] $output"
  #        fi
  #    else
  #        echo -e "\t [ FAIL ] $output"
  #    fi
  #else
  #    echo -e "\t container not present"
  #fi

  echo "pull latest radarr image..."
  docker pull linuxserver/radarr

  echo "initialise radarr container..."
  docker run -d \
    --name=$container_name  \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -e TZ=$TZ \
    -e UMASK_SET=002 \
    -p 7878:7878 \
    -v /home/docker/radarr/config:/config \
    -v /data:/data \
    --restart=$RESTART_POLICY \
    linuxserver/radarr

  echo
  echo "finished."
  pause
  clear
}

rtorrent () {
  clear
  header

 cat<< "EOF"
==================
 Updating: RuTorrent
==================
EOF

  container_name="rtorrent_crazymax"
  stop_and_remove_container container_name
  #container_id=$(docker ps -a -q --filter name=$container_name)

  #if [ ! -z "$container_id" ]; then
  #    echo -n "stopping $container_name container... "
  #    output=$(docker stop $container_name)
  #    if [ "$output" == "$container_name" ]; then
  #        echo -e "\t [ SUCCESS ]"
  #        echo -n "removing $container_name container... "
  #        output=$(docker rm $container_name)
  #        if [ "$output" == "$container_name" ]; then
  #            echo -e "\t [ SUCCESS ]"
  #        else
  #            echo -e "\t [ FAIL ] $output"
  #        fi
  #    else
  #        echo -e "\t [ FAIL ] $output"
  #    fi
  #else
  #    echo -e "\t container not present"
  #fi

  ## ===========================================
  ## k44sh version, fork of crazy max (think so)
  ## ===========================================
  #echo "pull latest $container_name image..."
  #docker pull k44sh/rutorrent:latest

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
  echo "pull latest rutorrent image..."
  docker pull crazymax/rtorrent-rutorrent:latest

  docker run -d \
    --name $container_name \
    --ulimit nproc=65535 \
    --ulimit nofile=32000:40000 \
    -e PUID=1000 \
    -e PGID=8675309 \
    -e TZ=Australia/Melbourne \
    -e UMASK_SET=022 \
    -p 6882:6881/udp \
    -p 8100:8000 \
    -p 8085:8080 \
    -p 9100:9000 \
    -p 60402:60402 \
    -v /home/docker/rtorrent_crazymax/data:/data \
    -v /home/docker/rtorrent_crazymax/passwd:/passwd \
    -v /data/torrents:/data/torrents \
    --restart=$RESTART_POLICY \
    crazymax/rtorrent-rutorrent:latest

  ## ===========================
  ## romancin version (older...)
  ## ===========================
  #echo "pull latest rutorrent image..."
  #docker pull romancin/rutorrent:latest

  #docker run -d \
    #--name=$container_name  \
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

  echo
  echo "finished."
  pause
  clear
}

sonarr() {
  clear
  header

  cat<< "EOF"
==================
 Updating: Sonarr
==================
EOF

  container_name="sonarr"
  stop_and_remove_container container_name
  #container_id=$(docker ps -a -q --filter name=$container_name)

  #if [ ! -z "$container_id" ]; then
  #    echo -n "stopping $container_name container... "
  #    output=$(docker stop $container_name)
  #    if [ "$output" == "$container_name" ]; then
  #        echo -e "\t [ SUCCESS ]"
  #        echo -n "removing $container_name container... "
  #        output=$(docker rm $container_name)
  #        if [ "$output" == "$container_name" ]; then
  #            echo -e "\t [ SUCCESS ]"
  #        else
  #            echo -e "\t [ FAIL ] $output"
  #        fi
  #    else
  #        echo -e "\t [ FAIL ] $output"
  #    fi
  #else
  #    echo -e "\t container not present"
  #fi

  echo "pull latest sonarr image..."
  docker pull linuxserver/sonarr

  echo "initialise sonarr container..."
  docker run -d \
    --name=$container_name  \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -e TZ=$TZ \
    -e UMASK_SET=002 \
    -p 8989:8989 \
    -v /home/docker/sonarr/config:/config \
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

tmm() {
  clear
  header

  cat<< "EOF"
============================
 Updating: TinyMediaManager
============================
EOF

  container_name="tmm"
  stop_and_remove_container container_name
  #container_id=$(docker ps -a -q --filter name=$container_name)

  #if [ ! -z "$container_id" ]; then
  #    echo -n "stopping $container_name container... "
  #    output=$(docker stop $container_name)
  #    if [ "$output" == "$container_name" ]; then
  #        echo -e "\t [ SUCCESS ]"
  #        echo -n "removing $container_name container... "
  #        output=$(docker rm $container_name)
  #        if [ "$output" == "$container_name" ]; then
  #            echo -e "\t [ SUCCESS ]"
  #        else
  #            echo -e "\t [ FAIL ] $output"
  #        fi
  #    else
  #        echo -e "\t [ FAIL ] $output"
  #    fi
  #else
  #    echo -e "\t container not present"
  #fi

  echo "pull latest tinymediamanager image..."
  docker pull romancin/tinymediamanager:latest-v4

  echo "initialise tinymediamanager container..."
  docker run -d \
    --name=$container_name  \
    -e TZ=$TZ \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -v /home/docker/tinymediamanager/config:/config \
    -v /data/media/movies:/data/media/movies \
    -v /data/media/television:/data/media/television \
    -v /data/torrents:/data/torrents \
    -p 5800:5800 \
    --restart=$RESTART_POLICY \
    romancin/tinymediamanager:latest-v4

  echo
  echo "finished."
  pause
  clear
}

qbittorrent() {
  clear
  header

  cat<< "EOF"
=======================
 Updating: Qbittorrent
=======================
EOF

  container_name="qbittorrent"
  stop_and_remove_container container_name
  #container_id=$(docker ps -a -q --filter name=$container_name)

  #if [ ! -z "$container_id" ]; then
  #    echo -n "stopping $container_name container... "
  #    output=$(docker stop $container_name)
  #    if [ "$output" == "$container_name" ]; then
  #        echo -e "\t [ SUCCESS ]"
  #        echo -n "removing $container_name container... "
  #        output=$(docker rm $container_name)
  #        if [ "$output" == "$container_name" ]; then
  #            echo -e "\t [ SUCCESS ]"
  #        else
  #            echo -e "\t [ FAIL ] $output"
  #        fi
  #    else
  #        echo -e "\t [ FAIL ] $output"
  #    fi
  #else
  #    echo -e "\t container not present"
  #fi

  echo "pull latest qbittorrent image..."
  docker pull linuxserver/qbittorrent
  #docker pull linuxserver/qbittorrent:14.2.5.99202004250119-7015-2c65b79ubuntu18.04.1-ls93

  echo "initialise qbittorrent container..."
  docker run -d \
    --name=$container_name  \
    -e TZ=$TZ \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -e UMASK_SET=002 \
    -e WEBUI_PORT=8081 \
    -p 51443:51443 \
    -p 51443:51443/udp \
    -p 8081:8081 \
    -v /home/docker/qbittorrent/config:/config \
    -v /data/torrents:/data/torrents \
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
