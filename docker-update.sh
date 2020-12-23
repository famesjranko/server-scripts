#!/bin/bash

## global variables
PUID='1000'
PGID='8675309'
TZ='Australia/Melbourne'

header () {
sleep .2
cat<< "EOF"

=========================================================================================================
     ____             __                __  __          __      __          _____           _       __
    / __ \____  _____/ /_____  _____   / / / /___  ____/ /___ _/ /____     / ___/__________(_)___  / /_
   / / / / __ \/ ___/ //_/ _ \/ ___/  / / / / __ \/ __  / __ `/ __/ _ \    \__ \/ ___/ ___/ / __ \/ __/
  / /_/ / /_/ / /__/ ,< /  __/ /     / /_/ / /_/ / /_/ / /_/ / /_/  __/   ___/ / /__/ /  / / /_/ / /_
 /_____/\____/\___/_/|_|\___/_/      \____/ .___/\__,_/\__,_/\__/\___/   /____/\___/_/  /_/ .___/\__/
                                         /_/                                             /_/
=========================================================================================================

EOF
}

dir_struct () {
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
         User: dorothy/1000
        Group: media/8675309

EOF

pause
clear
}

menu () {
header
cat<< "EOF"
    (1) update bazarr
    (2) update jackett
    (3) update jellyfin
    (4) update radarr
    (5) update sonarr
    (6) update qbittorrent

    (7) update all
    (8) show dir structure

    (Q)uit

    Please enter your choice:
EOF
}

final_print () {
clear
cat<< "EOF"

===============================
Docker Update Script completed.
===============================

EOF

echo "all running containers..."
docker ps
}

pause () {
 read -n1 -rsp $'Press any key to continue...\n'
}

bazarr () {
clear
header

cat<< "EOF"
==================
Updating: Bazarr
==================
EOF

echo "stopping bazarr container..."
docker stop bazarr

echo "remove bazarr container..."
docker rm jackett

echo "pull latest bazarr image..."
docker pull ghcr.io/linuxserver/bazarr

echo "re-initialise bazarr container..."
docker run -d \
  --name=bazarr \
  -e PUID=1000 \
  -e PGID=8675309 \
  -e TZ=Australia/Melbourne \
  -e UMASK_SET=022 \
  -p 6767:6767 \
  -v /home/docker/bazarr/config:/config \
  -v /data/media/movies:/data/media/movies \
  -v /data/media/television:/data/media/television \
  --restart unless-stopped \
  ghcr.io/linuxserver/bazarr

echo
echo "finished."
pause
clear
}

jackett () {
clear
header

cat<< "EOF"
==================
Updating: Jackett
==================
EOF

echo "stopping jackett container..."
docker stop jackett

echo "remove jackett container..."
docker rm jackett

echo "pull latest jackett image..."
docker pull linuxserver/jackett

echo "re-initialise jackett container..."
docker run -d \
  --name=jackett \
  -e PUID=1000 \
  -e PGID=8675309 \
  -e TZ=Australia/Melbourne \
  -p 9117:9117 \
  -v /home/docker/jackett/config:/config \
  -v /home/dorothy/torrents/downloads:/downloads \
  --restart unless-stopped \
  linuxserver/jackett

echo
echo "finished."
pause
clear
}

jellyfin () {
clear
header

cat<< "EOF"
===================
Updating: Jellyfin
===================
EOF

echo "stopping jellyfin container..."
docker stop jellyfin

echo "remove jellyfin container..."
docker rm jellyfin

echo "pull latest jellyfin image..."
docker pull linuxserver/jellyfin

echo "re-initialise jellyfin container..."
docker run -d \
  --name=jellyfin \
  --runtime=nvidia \
  --gpus all \
  -e NVIDIA_DRIVER_CAPABILITIES=all \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e PUID=1000 \
  -e PGID=8675309 \
  -e TZ=Australia/Melbourne \
  -e UMASK_SET=002 \
  -p 8096:8096 \
  -p 8920:8920 \
  -v /data/media/television:/data/tvshows \
  -v /data/media/movies:/data/movies \
  -v /home/docker/jellyfin/config:/config \
  -v /home/docker/jellyfin/transcode:/transcode \
  --device /dev/dri/renderD128:/dev/dri/renderD128 \
  --device /dev/dri/card0:/dev/dri/card0 \
  --restart unless-stopped \
linuxserver/jellyfin

echo
echo "finished."
pause
clear
}

radarr () {
clear
header

cat<< "EOF"
=================
Updating: Radarr
=================
EOF

echo "stopping radarr container..."
docker stop radarr

echo "remove radarr container..."
docker rm radarr

echo "pull latest radarr image..."
docker pull linuxserver/radarr

echo "re-initialise radarr container..."
docker run -d \
  --name=radarr \
  -e PUID=1000 \
  -e PGID=8675309 \
  -e TZ=Australia/Melbourne \
  -e UMASK_SET=002 \
  -p 7878:7878 \
  -v /home/docker/radarr/config:/config \
  -v /data:/data \
  --restart unless-stopped \
  linuxserver/radarr

echo
echo "finished."
pause
clear
}

sonarr () {
clear
header

cat<< "EOF"
=================
Updating: Sonarr
=================
EOF

echo "stopping sonarr container..."
docker stop sonarr

echo "remove sonarr container..."
docker rm sonarr

echo "pull latest sonarr image..."
docker pull linuxserver/sonarr

echo "re-initialise sonarr container..."
docker run -d \
  --name=sonarr \
  -e PUID=1000 \
  -e PGID=8675309 \
  -e TZ=Australia/Melbourne \
  -e UMASK_SET=002 \
  -p 8989:8989 \
  -v /home/docker/sonarr/config:/config \
  -v /data:/data \
  --restart unless-stopped \
  linuxserver/sonarr

printf "symlink torrent location to /downloads...  "
docker exec -it sonarr /bin/bash -c "ln -s /data/torrents/tv-sonarr/ downloads"

if [ $? -eq 0 ]; then
   echo [ OK   ]
else
   echo [ FAIL ]
fi

echo
echo "finished."
pause
clear
}

qbittorrent () {
clear
header

cat<< "EOF"
======================
Updating: Qbittorrent
======================
EOF

echo "stopping qbittorrent container..."
docker stop qbittorrent

echo "remove qbittorrent container..."
docker rm qbittorrent

echo "pull latest qbittorrent image..."
docker pull linuxserver/qbittorrent

echo "re-initialise qbittorrent container..."
docker run -d \
  --name=qbittorrent \
  -e PUID=1000 \
  -e PGID=8675309 \
  -e TZ=Australia/Melbourne \
  -e UMASK_SET=002 \
  -e WEBUI_PORT=8081 \
  -p 60499:60499 \
  -p 60499:60499/udp \
  -p 8081:8081 \
  -v /home/docker/qbittorrent/config:/config \
  -v /data/torrents:/data/torrents \
  --restart unless-stopped \
  linuxserver/qbittorrent:14.2.5.99202004250119-7015-2c65b79ubuntu18.04.1-ls93
# using old ver. due to torrent naming issue
#  linuxserver/qbittorrent

echo
echo "finished."
pause
clear
}

update_all () {
bazarr
jackett
jellyfin
radarr
sonarr
qbittorrent
}

main () {
menu
while :
do
    read -n1 -s
    case "$REPLY" in
    "1")  bazarr      && menu ;;
    "2")  jackett     && menu ;;
    "3")  jellyfin    && menu ;;
    "4")  radarr      && menu ;;
    "5")  sonarr      && menu ;;
    "6")  qbittorrent && menu ;;
    "7")  update_all  && menu ;;
    "8")  dir_struct  && menu ;;
    "Q")  final_print && exit 0 ;;
    "q")  final_print && exit 0 ;;
     * )  echo "invalid option" ;;
    esac
done
}

## execute main
clear
main
echo
