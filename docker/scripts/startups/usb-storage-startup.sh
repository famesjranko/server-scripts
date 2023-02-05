#!/bin/bash

# This script is used to mount an external drive with the UUID "8147280a-0776-47a7-9223-32e52ab22163"
# to the directory "/data/torrents". If the device is not found at startup, the script will retry every
# 5 seconds until the device is found and mounted. The drive is considered available if a file named
# "testfile" is found at the location "/data/torrents/testfile".

SCRIPT_NAME="USB-MOUNT"

UUID="8147280a-0776-47a7-9223-32e52ab22163"
MOUNT_PATH="/data/torrents/"
DRIVE_MOUNT_TESTFILE=$MOUNT_PATH"testfile"
WAIT_TIME=10

# Set max loop iterations (60x10secs=~10mins)
LOOP_LIMIT=60

# initial check if drive is mounted
stat $DRIVE_MOUNT_TESTFILE &> /dev/null
if [[ $? -eq 0 ]]; then
  echo $(date '+%y-%m-%d %T')" ["$SCRIPT_NAME"]: Drive is available and mounted at "$MOUNT_PATH
  exit 0
else
  echo $(date '+%y-%m-%d %T')" ["$SCRIPT_NAME"]: Drive at "$MOUNT_PATH" not yet available..."
fi

loop_count=0

while true; do
  (( loop_count++ ))
  
  if [ -b /dev/disk/by-uuid/$UUID ]; then
    # check if drive is mounted
    stat $DRIVE_MOUNT_TESTFILE &> /dev/null

    # exit if drive mounted confirmed
    if [[ $? -eq 0 ]]; then
      echo $(date '+%y-%m-%d %T')" ["$SCRIPT_NAME"]: Drive is available and mounted at "$MOUNT_PATH
      exit 0
    fi

    # mount usb drive
    echo $(date '+%y-%m-%d %T')" ["$SCRIPT_NAME"]: Attempting to mount drive "$UUID" at "$MOUNT_PATH
    mount /dev/disk/by-uuid/$UUID $MOUNT_PATH
  else
    echo $(date '+%y-%m-%d %T')" ["$SCRIPT_NAME"]: Device with UUID "$UUID "not found. Retrying in "$WAIT_TIME" seconds..."
  fi
  
  # exit if more than 10mins elapsed and some/all container_group won't start
  #if [[ $loop_count -gt $LOOP_LIMIT ]]; then
  #  echo $(date +"%y-%m-%d %T")" ["$SCRIPT_NAME"]: Exiting after hitting loop limit..."
  #  exit 1
  #fi
  
  sleep $WAIT_TIME
done
