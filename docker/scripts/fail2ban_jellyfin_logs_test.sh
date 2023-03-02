#!/bin/bash

## ========================================================
##  This script compares fail2ban's logs for the jellyfin
##  jail against the current active jellyfin logs. If they
##  DO NOT match, then fail2ban will be restarted.
## ========================================================

# =====================
#  set script defaults
# =====================

# Set jellyfin log dir path
JELLYFIN_LOG_DIR="/home/docker/jellyfin/config/log/log*.log"

# Set fail2ban jellyfin jail name
JELLYFIN_JAIL="jellyfin"

# Define the maximum number of retries for restarting service
MAX_RETRIES=5

# Define the sleep time between retries (in seconds)
RETRY_SLEEP=5

# ============================================
#  run script to check jellyfin/fail2ban logs
# ============================================

# Get Fail2ban Jellyfin info
fail2ban_jellyfin_info=$(fail2ban-client status "$JELLYFIN_JAIL" | grep "File list:") || {
  echo $(date '+%y-%m-%d %T')" [fail2ban_jellyfin_logs]: Failed to get Fail2ban Jellyfin info! Exiting..."
  exit 1
}

# Split the input string by space and get the number of elements
num_elements=$(awk '{print NF}' <<< "$fail2ban_jellyfin_info")

# Get the elements from position 5 to the end
fail2ban_logs=$(awk -v num=$num_elements '{for(i=5;i<=num;i++) print $i}' <<< "$fail2ban_jellyfin_info")

# Get the list of files to check against
jellyfin_logs=$(ls "$JELLYFIN_LOG_DIR") || {
  echo $(date '+%y-%m-%d %T')" [fail2ban_jellyfin_logs]: Failed to get list of Jellyfin logs! Exiting..."
  exit 1 
}

# Split the input strings by space, sort them and store in arrays
fail2ban_logs_array=( $(awk '{for(i=1;i<=NF;i++) print $i}' <<< "$fail2ban_logs" | sort) )
jellyfin_logs_array=( $(awk '{for(i=1;i<=NF;i++) print $i}' <<< "$jellyfin_logs" | sort) )
#echo "${fail2ban_logs_array[@]}"
#echo "${jellyfin_logs_array[@]}"

# Set match flag default to true
match=true

# TEST1 - Check if the arrays have the same length
if [[ ${#fail2ban_logs_array[@]} -ne ${#jellyfin_logs_array[@]} ]]; then
  match=false
fi

# TEST2 - Check if the arrays have the same content
if $match; then
  for i in "${!fail2ban_logs_array[@]}"; do
    if [[ "${fail2ban_logs_array[$i]}" != "${jellyfin_logs_array[$i]}" ]]; then
      match=false
      break
    fi
  done
fi

# Log and act on result of TESTS
if $match; then
  echo $(date '+%y-%m-%d %T')" [fail2ban_jellyfin_logs]: logs match! No need to do anything!"
  exit 0
else
  echo $(date '+%y-%m-%d %T')" [fail2ban_jellyfin_logs]: logs DO NOT match! Restarting fail2ban..."

  # Attempt to restart fail2ban up to max_retries times
  retries=0
  while ! systemctl restart fail2ban.service && (( retries < MAX_RETRIES )); do
    echo $(date '+%y-%m-%d %T')" [fail2ban_jellyfin_logs]: failed to restart fail2ban! Retrying in ${RETRY_SLEEP}s..."
    sleep ${RETRY_SLEEP}
    (( retries++ ))
  done

  # Check whether fail2ban restarted successfully
  if systemctl is-active --quiet fail2ban.service; then
    echo $(date '+%y-%m-%d %T')" [fail2ban_jellyfin_logs]: fail2ban restarted successfully."
    exit 0
  else
    echo $(date '+%y-%m-%d %T')" [fail2ban_jellyfin_logs]: failed to restart fail2ban after ${retries} retries!"
    exit 1
  fi
fi
