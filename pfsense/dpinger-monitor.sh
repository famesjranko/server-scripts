#!/bin/sh

# ===========================
# Author: Andrew J. McDonald
# Date: 2023-03-22
# ===================================================================================
# This script was written for pfsense, it checks if the dpinger service is running
# and restarts it if necessary. If dpinger is down, it will attempt to restart it up
# to n times, with a n second sleep period between attempts.
# ===================================================================================

# Set whether to run once or loop continuously...
SINGLE_RUN=true

# Function to check if dpinger is not running
# returns 0 if dpinger is down
# returns 1 if dpinger is up
dpinger_down() {
  if /usr/local/sbin/pfSsh.php playback svc status dpinger | grep "Service dpinger is running." > /dev/null 2>&1; then
    return 1
  else
    return 0
  fi
}

# Function to start dpinger and retry if necessary
# returns 0 if dpinger restart succeeds
# returns 1 if dpinger restart fails
dpinger_start() {
  # Set max attempts
  max_attempts=10

  # Set wait before next attempt
  sleep_period=15

  echo "$(date '+%y-%m-%d %T') [STATUS]: restarting dpinger..."

  attempt=1

  # Attempt to restart dpinger
  while [ $attempt -le $max_attempts ]; do
    # restart dpinger...
    /usr/local/sbin/pfSsh.php playback svc start dpinger > /dev/null 2>&1

    if dpinger_down; then
      echo "$(date '+%y-%m-%d %T') [STATUS]: attempt $attempt failed to restart dpinger..."
      attempt=$((attempt + 1))
      sleep $sleep_period
    else
      return 0
    fi
  done

  # Run final dpinger status check
  if dpinger_down; then
    return 1
  else
    return 0
  fi
}

while true; do
  if dpinger_down; then
    echo "$(date '+%y-%m-%d %T') [STATUS]: dpinger is down!"
    if dpinger_start; then
      echo "$(date '+%y-%m-%d %T') [SUCCESS]: dpinger restarted!"
    else
      echo "$(date '+%y-%m-%d %T') [ERROR]: all attempts failed to restart dpinger."
    fi
  #else
  #  echo "$(date '+%y-%m-%d %T') [STATUS]: dpinger is up."
  fi

  if $SINGLE_RUN; then
    break
  fi

  # wait 5mins before checking again...
  sleep 300
done
