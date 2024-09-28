#!/bin/bash

header () {
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

EOF
}

menu () {
header
cat<< "EOF"
    (1) update jackett
    (2) update jellyfin
    (3) update radarr
    (4) update sonarr
    (5) update qbittorrent

    (6) update all
    (7) show dir structure

    (Q)uit

    Please enter your choice:
EOF
}

final_print () {
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

jackett () {
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
  -e PUID=<PUID> \
  -e PGID=<PGID> \
  -e TZ=<Country/City> \
  -p 9117:9117 \
  -v /home/docker/jackett/config:/config \
  -v /home/dorothy/torrents/downloads:/downloads \
  --restart unless-stopped \
  linuxserver/jackett

echo
echo "finished."
}

jellyfin () {
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
  -e PUID=<PUID> \
  -e PGID=<PGID> \
  -e TZ=<Country/City> \
  -e UMASK_SET=002 \
  -e NVIDIA_DRIVER_CAPABILITIES=all \
  -e NVIDIA_VISIBLE_DEVICES=all \
  --runtime=nvidia \
  --gpus all \
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
}

radarr () {
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
  -e PUID=<PUID> \
  -e PGID=<PGID> \
  -e TZ=<Country/City> \
  -e UMASK_SET=002 \
  -p 7878:7878 \
  -v /home/docker/radarr/config:/config \
  -v /data:/data \
  --restart unless-stopped \
  linuxserver/radarr

echo
echo "finished."
}

sonarr () {
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
  -e PUID=<PUID> \
  -e PGID=<PGID> \
  -e TZ=<Country/City> \
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
}

qbittorrent () {
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
  -e PUID=<PUID> \
  -e PGID=<PGID> \
  -e TZ=<Country/City> \
  -e UMASK_SET=002 \
  -e WEBUI_PORT=8081 \
  -p 60499:51413 \
  -p 60499:51413/udp \
  -p 8081:8081 \
  -v /home/docker/qbittorrent/config:/config \
  -v /data/torrents:/data/torrents \
  --restart unless-stopped \
  linuxserver/qbittorrent

echo
echo "finished."
}

update_all () {
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
    "1")  clear && header && jackett     && pause && clear && menu ;;
    "2")  clear && header && jellyfin    && pause && clear && menu ;;
    "3")  clear && header && radarr      && pause && clear && menu ;;
    "4")  clear && header && sonarr      && pause && clear && menu ;;
    "5")  clear && header && qbittorrent && pause && clear && menu ;;
    "6")  clear && header && update_all  && pause && clear && menu ;;
    "7")  clear && header && dir_struct  && pause && clear && menu ;;
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
