#!/bin/sh

# ===========================
# Author: Andrew J. McDonald
# Date: 2023-03-15
# ===================================================================================
# This script was written for pfsense, it checks if the dpinger service is running
# and restarts it if necessary. If dpinger is down, it will attempt to restart it up
# to 5 times, with a 5 second sleep period between attempts.
# ===================================================================================

# Define a function to start dpinger and retry if necessary
start_dpinger() {
  echo "$(date '+%y-%m-%d %T') [STATUS]: restarting dpinger..."
  /usr/local/sbin/pfSsh.php playback svc start dpinger > /dev/null 2>&1

  # Set the maximum number of attempts and the sleep period between attempts
  max_attempts=5
  attempt=1
  sleep_period=5

  # Loop through up to the maximum number of attempts to restart dpinger
  while [ $attempt -le $max_attempts ]; do
    # Check if dpinger is now running and return success if it is
    if /usr/local/sbin/pfSsh.php playback svc status dpinger | grep 'running' > /dev/null 2>&1; then
      return 0
    # If dpinger is still not running, log the attempt number and sleep before trying again
    else
      echo "$(date '+%y-%m-%d %T') [STATUS]: attempt $attempt failed to restart dpinger..."
      attempt=$((attempt + 1))
      sleep $sleep_period
      start_dpinger
    fi
  done

  # If all attempts fail, return failure
  return 1
}

# Define a function to check if dpinger is running
check_dpinger() {
  if /usr/local/sbin/pfSsh.php playback svc status dpinger | grep 'running' > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Check if dpinger is running
if check_dpinger; then
  echo "$(date '+%y-%m-%d %T') [STATUS]: dpinger is up!"
else
  # If dpinger is down, attempt to restart it and log the success or failure
  echo "$(date '+%y-%m-%d %T') [STATUS]: dpinger is down!"
  if start_dpinger; then
    echo "$(date '+%y-%m-%d %T') [SUCCESS]: dpinger restarted!"
  else
    echo "$(date '+%y-%m-%d %T') [ERROR]: all attempts failed to restart dpinger."
  fi
fi
