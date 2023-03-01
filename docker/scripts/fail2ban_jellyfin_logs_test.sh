#!/bin/bash

## ========================================================
##  This script compares fail2ban's logs for the jellyfin
##  jail against the current active jellyfin logs. If they
##  DO NOT match, then fail2ban will be restarted.
## ========================================================

# =====================
#  set script defaults
# =====================

# SET JELLYFIN LOG LOCATION
JELLYFIN_LOG_DIR="/home/docker/jellyfin/config/log/log*.log"

# SET FAIL2BAN JELLYFIN JAIL NAME
JELLYFIN_JAIL="jellyfin"

# ============================================
#  run script to check jellyfin/fail2ban logs
# ============================================

# Get the input string
fail2ban_jellyfin_info=$(fail2ban-client status $JELLYFIN_JAIL | grep "File list:")

# Split the input string by space and get the number of elements
num_elements=$(awk '{print NF}' <<< "$fail2ban_jellyfin_info")

# Get the elements from position 5 to the end
fail2ban_logs=$(awk -v num=$num_elements '{for(i=5;i<=num;i++) print $i}' <<< "$fail2ban_jellyfin_info")

# Get the list of files to check against
jellyfin_logs=$(ls $JELLYFIN_LOG_DIR)

# Split the input strings by space and store them in arrays
fail2ban_logs_array=( $(awk '{for(i=1;i<=NF;i++) print $i}' <<< "$fail2ban_logs" | sort) )
jellyfin_logs_array=( $(awk '{for(i=1;i<=NF;i++) print $i}' <<< "$jellyfin_logs" | sort) )
#echo "${fail2ban_logs_array[@]}"
#echo "${jellyfin_logs_array[@]}"

# Set match flag default to true
match=true

# Check if the arrays have the same length
if [[ ${#fail2ban_logs_array[@]} -ne ${#jellyfin_logs_array[@]} ]]; then
  match=false
fi

# Check if the arrays have the same content
if $match; then
  for i in "${!fail2ban_logs_array[@]}"; do
    if [[ "${fail2ban_logs_array[$i]}" != "${jellyfin_logs_array[$i]}" ]]; then
      match=false
      break
    fi
  done
fi

# Print the result
if $match; then
  echo $(date '+%y-%m-%d %T')" [fail2ban_jellyfin_logs]: logs match! No need to do anything!"
  exit 0
else
  echo $(date '+%y-%m-%d %T')" [fail2ban_jellyfin_logs]: logs DO NOT match! Restarting fail2ban..."
  systemctl restart fail2ban.service
fi
