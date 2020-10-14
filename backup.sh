###################################################################################
## This script creates a backup to usb, with a record of all installed packages  ##
## and essential directories from hp-prodesk.                                    ##
##                                                                               ##
## Docker containers are stopped before backup begins to help prevent file       ##
## corruption, and are restarted on completion.                                  ##
##                                                                               ##
## All directories are backed up, except those excluded below.                   ##
##                                                                               ##
###################################################################################

#!/bin/bash

echo "== running backup script =="

## collect a list of installed packages
##
echo
echo "== getting installed package list =="

dpkg --get-selections > /mnt/backup_usb/prodesk_install-list.txt

## stop containers
##
echo
echo "== stopping docker containers =="

docker stop $(docker ps -a -q)

## run rsync backup command
##
echo
echo "== running rsync backup =="
sleep 3

sudo rsync -aAXHS --info=progress2 --numeric-ids --one-file-system --delete  \
--exclude=/dev/ \
--exclude=/proc/ \
--exclude=/sys/ \
--exclude=/tmp/ \
--exclude=/run/ \
--exclude=/mnt/ \
--exclude=/media/ \
--exclude=/data/ \
--exclude=/swapfile \
--exclude=/lost+found \
--exclude=/home/dorothy/.cache \
--exclude=/home/dorothy/downloads/ \
--exclude=/home/dorothy/torrents/downloads/ \
--exclude=/home/dorothy/torrents/incomplete/ \
--exclude=/home/dorothy/torrents/watch/ \
--exclude=/home/dorothy/torrents/backup/ \
--exclude=/docker/ \
--exclude=/var/cache/ \
--exclude=/var/lib/containerd/ \
--exclude=/var/lib/docker-engine/ \
--exclude=/var/lib/docker/ \
--exclude=/var/log/ \
--exclude=/var/run/ \
--exclude=/var/spool/ \
--exclude=/var/tmp/ \
/ /mnt/backup_usb/prodesk/

## restart containers
##
echo
echo "== restarting docker containers =="
sleep 3

docker start $(docker ps -a -q -f status=exited)

## exit
##
echo
echo "== backup test complete =="

exit 0
