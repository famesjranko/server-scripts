#!/bin/bash

## global variables
PUID='1000'
PGID='8675309'
TZ='Australia/Melbourne'
PAUSE=0

header() {
  sleep .3
  cat<< "EOF"

====================================
 Docker Update/Install Script [sdb1]
====================================

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
	 User: dorothy/1000
	Group: media/8675309

EOF

  pause
  clear
}

menu() {
  header
  cat<< "EOF"
   ( 1) update Bazarr
   ( 2) update Bitwarden
   ( 3) update Jackett
   ( 4) update Jellyfin
   ( 5) update Portainer
   ( 6) update Qbittorrent
   ( 7) update Radarr
   ( 8) update Sonarr
   ( 9) update Omada-Controller
   (10) update TinyMediaManager
   (11) update Jellyseerr
   (12) update Deluge

    (u) update all standard containers:
	{Bitwarden, Jackett, Jellyfin, Portainer, qBittorrent, Deluge, Radarr, Sonarr, Omada}

    (d) show dir structure

    (q)uit

EOF
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
  if [ $PAUSE -eq 1 ]
    then
      read -n1 -rsp $'Press any key to continue...\n'
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

  echo -n "stopping bazarr container..."
  bzoutput=$(docker stop bazarr)
  if [ "$bzoutput" == "bazarr" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo -n "remove bazarr container..."
  bzoutput=$(docker rm bazarr)
  if [ "$bzoutput" == "bazarr" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo "pull latest bazarr image..."
  docker pull ghcr.io/linuxserver/bazarr

  echo "initialise bazarr container..."
  docker run -d \
    --name=bazarr \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -e TZ=$TZ \
    -e UMASK_SET=022 \
    -p 6767:6767 \
    -v /home/docker/bazarr/config:/config \
    -v /data/media/movies:/data/media/movies \
    -v /data/media/television:/data/media/television \
    --restart no \
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

  echo -n "stopping bitwarden container..."
  bwoutput=$(docker stop bitwarden)
  if [ "$bwoutput" == "bitwarden" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo -n "remove bitwarden container..."
  bwoutput=$(docker rm bitwarden)
  if [ "$bwoutput" == "bitwarden" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo "pull latest bitwarden image..."
  docker pull vaultwarden/server:latest

  echo "initialise bitwarden container..."
  docker run -d \
    --name=bitwarden \
    -e TZ=$TZ \
    -u 1000:1000 \
    -e ADMIN_TOKEN=I9/NMemIyydtjEr2Nz0YgoYvf74fbdosFvls6O1UPdsXR9IwRDKxX5bDUa5DuaQz \
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
    --restart always \
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

  echo -n "stopping deluge container..."
  dloutput=$(docker stop deluge)
  if [ "$dloutput" == "deluge" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo -n "remove deluge container..."
  dloutput=$(docker rm deluge)
  if [ "$dloutput" == "deluge" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo "pull latest deluge image..."
  docker pull lscr.io/linuxserver/deluge:latest

  echo "initialise deluge container..."
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
    -v /home/docker/deluge/config:/config \
    -v /data/torrents:/data/torrents \
    --restart=no \
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

  echo -n "stopping jackett container..."
  joutput=$(docker stop jackett)
  if [ "$joutput" == "jackett" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo -n "remove jackett container..."
  joutput=$(docker rm jackett)
  if [ "$joutput" == "jackett" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo "pull latest jackett image..."
  docker pull linuxserver/jackett

  echo "initialise jackett container..."
  docker run -d \
    --name=jackett \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -e TZ=$TZ \
    -p 9117:9117 \
    -v /home/docker/jackett/config:/config \
    -v /data/torrents/jackett:/downloads \
    --restart=on-failure:5 \
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

  echo -n "stopping jellyfin container..."
  jfoutput=$(docker stop jellyfin)
  if [ "$jfoutput" == "jellyfin" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo -n "remove jellyfin container..."
  jfoutput=$(docker rm jellyfin)
  if [ "$jfoutput" == "jellyfin" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo "pull latest jellyfin image..."
  docker pull linuxserver/jellyfin

  echo "initialise jellyfin container..."
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
    -v /data/media/television:/data/tvshows \
    -v /data/media/movies:/data/movies \
    -v /home/docker/jellyfin/config:/config \
    -v /home/docker/jellyfin/transcode:/transcode \
    --device /dev/dri/renderD128:/dev/dri/renderD128 \
    --device /dev/dri/card0:/dev/dri/card0 \
    --restart=on-failure:5 \
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

  echo -n "stopping jellyseerr container..."
  jfsoutput=$(docker stop jellyseerr)
  if [ "$jfsoutput" == "jellyseerr" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo -n "remove jellyseerr container..."
  jfsoutput=$(docker rm jellyseerr)
  if [ "$jfsoutput" == "jellyseerr" ]
    then
      echo -e "\t\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo "pull latest jellyseerr image..."
  docker pull fallenbagel/jellyseerr:latest

  docker run -d \
    --name jellyseerr \
    -e LOG_LEVEL=debug \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -e TZ=$TZ \
    -p 5055:5055 \
    -v /home/docker/jellyseerr/config:/app/config \
    --restart=no \
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

  echo -n "stopping omada-controller container..."
  omoutput=$(docker stop omada-controller)
  if [ "$omoutput" == "omada-controller" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo -n "remove omada-controller container..."
  omoutput=$(docker rm omada-controller)
  if [ "$omoutput" == "omada-controller" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo "pull latest omada-controller image..."
  docker pull mbentley/omada-controller:latest

  echo "initialise omada-controller container..."
  docker run -d \
    --name omada-controller \
    --restart always \
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

  echo -n "stopping portainer container..."
  poutput=$(docker stop portainer)
  if [ "$poutput" == "portainer" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo -n "remove portainer container..."
  poutput=$(docker rm portainer)
  if [ "$poutput" == "portainer" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo "pull latest portainer image..."
  docker pull portainer/portainer-ce

  echo "initialise portainer container..."
  docker run -d \
    --name=portainer \
    --restart unless-stopped \
    -e USER_ID=$PUID \
    -e GROUP_ID=$PGID \
    -e TZ=$TZ \
    -p 8000:8000 \
    -p 9000:9000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /home/docker/portainer:/data \
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

  echo -n "stopping radarr container..."
  routput=$(docker stop radarr)
  if [ "$routput" == "radarr" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo -n "remove radarr container..."
  routput=$(docker rm radarr)
  if [ "$routput" == "radarr" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo "pull latest radarr image..."
  docker pull linuxserver/radarr

  echo "initialise radarr container..."
  docker run -d \
    --name=radarr \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -e TZ=$TZ \
    -e UMASK_SET=002 \
    -p 7878:7878 \
    -v /home/docker/radarr/config:/config \
    -v /data:/data \
    --restart=on-failure:5 \
    linuxserver/radarr

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

  echo -n "stopping sonarr container..."
  soutput=$(docker stop sonarr)
  if [ "$soutput" == "sonarr" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo -n "remove sonarr container..."
  soutput=$(docker rm sonarr)
  if [ "$soutput" == "sonarr" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo "pull latest sonarr image..."
  docker pull linuxserver/sonarr

  echo "initialise sonarr container..."
  docker run -d \
    --name=sonarr \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -e TZ=$TZ \
    -e UMASK_SET=002 \
    -p 8989:8989 \
    -v /home/docker/sonarr/config:/config \
    -v /data:/data \
    --restart=on-failure:5 \
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

  echo -n "stopping tinymediamanager container..."
  tmoutput=$(docker stop tmm)
  if [ "$tmoutput" == "tmm" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo -n "remove tinymediamanager container..."
  tmoutput=$(docker rm tmm)
  if [ "$tmoutput" == "tmm" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo "pull latest tinymediamanager image..."
  docker pull romancin/tinymediamanager:latest-v4

  echo "initialise tinymediamanager container..."
  docker run -d \
    --name=tmm \
    -e TZ=$TZ \
    -e PUID=$PUID \
    -e PGID=$PGID \
    -v /home/docker/tinymediamanager/config:/config \
    -v /data/media/movies:/data/media/movies \
    -v /data/media/television:/data/media/television \
    -v /data/torrents:/data/torrents \
    -p 5800:5800 \
    --restart no \
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

  echo -n "stopping qbittorrent container..."
  qboutput=$(docker stop qbittorrent)
  if [ "$qboutput" == "qbittorrent" ]
    then
      echo -e "\t [ SUCCES ]"
    else
      echo -e "\t [  FAIL  ]"
  fi

  echo -n "remove qbittorrent container..."
  qboutput=$(docker rm qbittorrent)
  if [ "$qboutput" == "qbittorrent" ]
    then
      echo -e "\t\t [ SUCCES ]"
    else
      echo -e "\t\t [  FAIL  ]"
  fi

  echo "pull latest qbittorrent image..."
  docker pull linuxserver/qbittorrent
  #docker pull linuxserver/qbittorrent:14.2.5.99202004250119-7015-2c65b79ubuntu18.04.1-ls93

  echo "initialise qbittorrent container..."
  docker run -d \
    --name=qbittorrent \
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
    --restart unless-stopped \
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

update_all() {
  # turn user request to continue off
  PAUSE=0

  # call update functions
  bitwarden
  deluge
  jackett
  jellyfin
  jellyseerr
  portainer
  qbittorrent
  radarr
  sonarr
  omada

  # turn user request to continue back on
  PAUSE=1
}

main() {
  menu
  while :
  do
    read -r -p "Please enter your choice: "
    case "$REPLY" in
    "1" )  bazarr;      menu ;;
    "2" )  bitwarden;   menu ;;
    "3" )  jackett;     menu ;;
    "4" )  jellyfin;    menu ;;
    "5" )  portainer;   menu ;;
    "6" )  qbittorrent; menu ;;
    "7" )  radarr;      menu ;;
    "8" )  sonarr;      menu ;;
    "9" )  omada;       menu ;;
    "10")  tmm;         menu ;;
    "11")  jellyseerr;  menu ;;
    "12")  deluge;      menu ;;
    "U" )  update_all;  menu ;;
    "u" )  update_all;  menu ;;
    "D" )  dir_struct;  menu ;;
    "d" )  dir_struct;  menu ;;
    "Q" )  final_print; break ;;
    "q" )  final_print; break ;;
     *  )  echo; echo "invalid option, try again..." ;;
    esac
  done
  exit
}

## execute main
clear
main
