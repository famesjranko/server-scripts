#!/bin/bash

## =================================================================
##  This script compares fail2ban's logs for the jellyfin jail
##  against the current active jellyfin logs. If they DO NOT MATCH
##  the jellfyin fail will be reloaded, which will resynch the logs
## =================================================================

# =====================
#  SET SCRIPT DEFAULTS
# =====================

# Set jellyfin logs dir path <- same as one set as logpath in jail.local
#JELLYFIN_LOG_DIR="/path/to/jellyfin/config/log/log*.log"

# Set fail2ban jellyfin jail name
JELLYFIN_JAIL="jellyfin"

# Define the maximum number of retries for restarting service
MAX_RETRIES=5

# Define the sleep time between retries (in seconds)
RETRY_SLEEP=5

# ==========================================
#  LOG INFO AND EQUALITY TEST FUNCTIONS
# ==========================================

# Function to retrieve current fail2ban jellyfin jail watch logs
# returns an array of log paths
get_fail2ban_jellyfin_info() {
  local fail2ban_jellyfin_info=$(fail2ban-client status "$JELLYFIN_JAIL" | grep "File list:") || {
    echo $(date '+%y-%m-%d %T')" [fail2ban_jellyfin_logs]: Failed to get Fail2ban Jellyfin info! Exiting..."
    exit 1
  }

  # Split the input string by space and get the number of elements
  local num_elements=$(awk '{print NF}' <<< "$fail2ban_jellyfin_info")

  # Get elements from position 5 to the end - log path references start at element 5
  local fail2ban_logs=$(awk -v num=$num_elements '{for(i=5;i<=num;i++) print $i}' <<< "$fail2ban_jellyfin_info")

  # Split the input strings (log paths) by space, sort them and store in an array
  local fail2ban_logs_array=( $(awk '{for(i=1;i<=NF;i++) print $i}' <<< "$fail2ban_logs" | sort) )

  # Return the log array
  echo "${fail2ban_logs_array[@]}"
}

# Function to retrieve current active jellyfin logs
# prints an error of log paths
get_jellyfin_logs() {
  local jellyfin_logs=$(ls $JELLYFIN_LOG_DIR) || {
    echo $(date '+%y-%m-%d %T')" [fail2ban_jellyfin_logs]: Failed to get list of Jellyfin logs! Exiting..."
    exit 1
  }

  # Split the input strings (log paths) by space, sort them and store in an array
  local jellyfin_logs_array=( $(awk '{for(i=1;i<=NF;i++) print $i}' <<< "$jellyfin_logs" | sort) )

  # Return the log array
  echo "${jellyfin_logs_array[@]}"
}

# Function to test if two arrays have the same length and content
# Returns true if the arrays match, false otherwise
function test_arrays_match {
  local array1=("${!1}")
  local array2=("${!2}")
  local match=true

  # Check if the arrays have the same length
  if [[ ${#array1[@]} -ne ${#array2[@]} ]]; then
    match=false
  fi

  # Check if the arrays have the same content
  if $match; then
    for i in "${!array1[@]}"; do
      if [[ "${array1[$i]}" != "${array2[$i]}" ]]; then
        match=false
        break
      fi
    done
  fi

  # Return the result
  echo "$match"
}

# ============================================
#  run script to check jellyfin/fail2ban logs
# ============================================

# Build log arrays from jellyfin active, and fail2ban jellyfin jail, respecctively
fail2ban_logs_array=$(get_fail2ban_jellyfin_info)
jellyfin_logs_array=$(get_jellyfin_logs)
#echo "fail2ban_logs_array: ${fail2ban_logs_array[@]}"
#echo "jellyfin_logs_array: ${jellyfin_logs_array[@]}"

# Check fail2ban and jellyfin logs arrays for equality and reload jail if necessary
if $(test_arrays_match fail2ban_logs_array jellyfin_logs_array); then
  echo $(date '+%y-%m-%d %T')" [fail2ban_jellyfin_logs]: logs match! No need to do anything!"
  exit 0
else
  echo $(date '+%y-%m-%d %T')" [fail2ban_jellyfin_logs]: logs DO NOT match! Restarting jellyfin jail..."

  #echo "fail2ban_logs_array: ${fail2ban_logs_array[@]}"
  #echo "jellyfin_logs_array: ${jellyfin_logs_array[@]}"

  # Attempt to restart fail2ban jellyfin jail, up to max_retries times
  retries=0
  while ! $(test_arrays_match fail2ban_logs_array jellyfin_logs_array) && (( retries < MAX_RETRIES )); do
    # Reload fail2ban
    fail2ban-client reload jellyfin >/dev/null 2>&1
    sleep ${RETRY_SLEEP}

    # Update log arrays
    fail2ban_logs_array=$(get_fail2ban_jellyfin_info)
    jellyfin_logs_array=$(get_jellyfin_logs)

    # Check fail2ban and jellyfin logs arrays for equality, break on success
    if $(test_arrays_match fail2ban_logs_array jellyfin_logs_array); then
      break
    fi

    (( retries++ ))
  done

  # Confirm status of fail2ban jellyfin jail reload and log sync
  fail2ban-client status jellyfin >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    echo $(date '+%y-%m-%d %T')" [fail2ban_jellyfin_logs]: jellyfin jail is running!"
    if $(test_arrays_match fail2ban_logs_array jellyfin_logs_array); then
      echo $(date '+%y-%m-%d %T')" [fail2ban_jellyfin_logs]: logs match after reload! Success."
      exit 0
    else
      echo $(date '+%y-%m-%d %T')" [fail2ban_jellyfin_logs]: logs still DO NOT match after reload! Exiting..."
      exit 1
    fi
  else
    echo $(date '+%y-%m-%d %T')" [fail2ban_jellyfin_logs]: after $retries attempts, jellyfin jail is NOT running!"
  fi
fi
