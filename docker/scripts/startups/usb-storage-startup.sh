#!/bin/bash

# ===========================
# Author: Andrew J. McDonald
# Date: 2023-03-22
## ==============================================================================
## STARTUP EXTERNAL DRIVE MOUNT SCRIPT
##
## Description:
## This script mounts an external drive by its UUID. If the device is not found
## at startup, the script retries every 10 seconds until the device is found and
## mounted. The drive is considered available if a "testfile" is found at the
## drive mount location. The script exits with status code 0 if the drive is
## mounted successfully, or with status code 1 if mounting the drive failed after
## the maximum number of attempts.
##
## Variables:
## - UUID: the UUID of the drive to mount
## - MOUNT_PATH: the path where the drive should be mounted
## - DRIVE_MOUNT_TESTFILE: path of test file used to verify drive is mounted
## - WAIT_TIME: time (seconds) to wait before retrying to mount the drive
## - LOOP_LIMIT: max loops before exits with status code 1.
##
## The script requires the "stat" and "mount" commands to be installed.
## ==============================================================================

SCRIPT_NAME="USB-MOUNT"

UUID="8147280a-0776-47a7-9223-32e52ab22163"
MOUNT_PATH="/data/torrents/"
DRIVE_MOUNT_TESTFILE=$MOUNT_PATH"testfile"
WAIT_TIME=10

# Set max loop iterations (60x10secs=~10mins)
# Set to 0 to disable the loop limit.
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
  
  # exit when loop limit reached
  if [[ $LOOP_LIMIT -ne 0 && $loop_count -gt $LOOP_LIMIT ]]; then
    echo $(date +"%y-%m-%d %T")" ["$SCRIPT_NAME"]: Exiting after hitting loop limit..."
    exit 1
  fi
  
  sleep $WAIT_TIME
done
