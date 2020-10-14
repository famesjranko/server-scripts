##################################################################################
## This script creates a backup to usb, with a record of all installed packages ##
## and essential directories from hp-prodesk.                                   ##
## Docker containers are stopped before backup begins to help prevent file      ##
## corruption, and are restarted on completion.                                 ##
##                                                                              ##
## All directories are backed up, except those excluded below.                  ##
##################################################################################

#!/bin/bash

## backup drive mount point
DIR='/mnt/backup_usb '

## full backup directory
BDIR='/mnt/backup_usb/prodesk-full/ '

## package list file location
PFILE="/mnt/backup_usb/prodesk_install-list.txt "

## is docker used on system
DOCKER="true"

## clear screen
clear
echo
echo "============================"
echo "  RSYNC FULL SYSTEM BACKUP  "
echo "============================"

## test backup drive is mounted
echo
if grep -qs $DIR /proc/mounts; then
  echo "backup directory: " $DIR
  echo "found!"

  ## collect and print drive stats
  stats=$(df $DIR -h | head -2 | tail -1 | awk '{print 'size='$2, $3, $4, $5}')
  statsinfo=( $stats )
  echo
  echo "backup drive stats: "
  echo "	size: " ${statsinfo[0]}
  echo "	used: " ${statsinfo[1]}, ${statsinfo[3]}
  echo "	free: " ${statsinfo[2]}
else
  echo "backup directory: " $DIR " not found"
  echo "exiting now... "
  exit 1
fi

## quit method on failure
quit () {
  echo
  echo -n "Something went wrong, would you like to quit (y/n): ? "
  read yno
  case $yno in
    [yY] | [yY][Ee][Ss] )
      echo "exiting now... "
      exit 0
      ;;
    [nN] | [n|N][O|o] )
      echo "continuing with backup... "
      break
      ;;
    *) echo "Invalid input"
      ;;
  esac
}

## user confirmation method
question () {
echo -n "Continue with full-backup (y/n): ? "
while :
do
  read yno
  case $yno in
    [yY] | [yY][Ee][Ss] )
      echo
      echo "continuing with backup... "
      break
      ;;
    [nN] | [n|N][O|o] )
      echo
      echo "cancelling backup and exiting now... "
      exit 0
      ;;
    *) echo "Invalid input"
      ;;
  esac
done
}

## package-list installer method
package-list () {
  # backup list of installed packages
  echo
  echo "== installed system packages backup =="
  echo
  echo -n "Do you wish to backup installed package list (y/n): ? "
  while :
  do
    read yno
    case $yno in
      [yY] | [yY][Ee][Ss] )
        echo "backing up installed package list..."
        echo
        if { var="$( { dpkg --get-selections > $PFILE; } 2>&1 1>&3 3>&- )"; } 3>&1; then
          echo "installed package list backup successful"
        else
          echo "installed package list backup failed"
          echo "error: " $var
          quit
        fi
        break
        ;;
      [nN] | [n|N][O|o] )
        echo "skipping installed package list backup"
        break
        ;;
      *) echo "Invalid input"
        ;;
    esac
  done
}

## backup method
backup () {
  ## stop containers
  if [ $DOCKER = "true" ]
  then
    echo
    echo "== stopping docker containers =="
    docker stop $(docker ps -a -q)
  fi

  ## run rsync
  echo
  echo "== running rsync backup =="
  sleep 1
  sudo rsync -aAXHS --info=progress2 --numeric-ids --one-file-system --delete-before \
  --exclude=/dev/ \
  --exclude=/proc/ \
  --exclude=/sys/ \
  --exclude=/tmp/ \
  --exclude=/run/ \
  --exclude=/data/ \
  --exclude=/mnt/ \
  --exclude=/media/ \
  --exclude=/lost+found \
  --exclude=/home/dorothy/.cache \
  --exclude=/home/dorothy/downloads/ \
  --exclude=/home/dorothy/torrents/ \
  --exclude=/docker/ \
  --exclude=/var/cache/ \
  --exclude=/var/lib/containerd/ \
  --exclude=/var/lib/docker-engine/ \
  --exclude=/var/lib/docker/ \
  --exclude=/var/lib/spool/ \
  --exclude=/var/tmp/ \
  / $BDIR

  ## restart containers
  if [ $DOCKER = "true" ]
  then
    echo
    echo "== restarting docker containers =="
    docker start $(docker ps -a -q -f status=exited)
  fi

  ## show backed up files
  echo
  echo "== backed up system files =="
  echo
  echo "/mnt/backup/hp-prodesk-full/"
  echo
  ls -l --color=auto $BDIR

  echo
  echo "== backup complete =="

  exit 0
}

## main menu
main () {
  echo
  echo -n "Do you wish to perform a full system backup (y/n): ? "
  while :
  do
  read yno
    case $yno in
      [yY] | [yY][Ee][Ss] )
        package-list
        question
        backup
        ;;
      [nN] | [n|N][O|o] )
        echo "exiting now... "
        exit 1
        ;;
     * )  echo "invalid option" ;;
    esac
  done
}

## run main program
main
