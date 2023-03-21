#!/bin/sh

# ===========================
# Author: Andrew J. McDonald
# Date: 2023-03-22
# ===================================================================================
# This is a network monitoring script that checks if the WAN (Wide Area Network)
# IP address of a network interface is reachable or not. If the WAN IP address is
# not reachable, the script logs a message saying that the connection is down and
# waits until the connection is restored. Once the connection is restored, the
# script logs a message saying that the connection is restored.
# ===================================================================================

# Set WAN interface name
WAN="igb0"

# Set whether to run once or loop continuously...
SINGLE_RUN=true

# Initialise default variables and condition flags
ip=""
interface=
connection=

while true; do
  # Get IP address of WAN interface
  wan_ip=$(ifconfig "$WAN" | grep "inet " | awk '{print $2}')

  # If WAN IP is empty or 0.0.0.0, log log status and update connection flag
  if [ -z "$wan_ip" ] || [ "$wan_ip" = "0.0.0.0" ]; then
    echo "$(date '+%y-%m-%d %T'): Connection is down"
    connection=false
  fi

  # Run the following code continuously until the connection is restored
  while [ "$connection" = false ]; do
    # Update IP address of WAN interface
    wan_ip=$(ifconfig "$WAN" | grep "inet " | awk '{print $2}')

    # If WAN IP is not empty and not 0.0.0.0, log status message and update connection flag
    if [ "$wan_ip" != "0.0.0.0" ] && [ ! -z "$wan_ip" ]; then
      echo "$(date '+%y-%m-%d %T'): Connection restored"
      connection=true

      # Exit inner loop, resume outer loop
      break
    fi

    # Wait before checking the connection again
    sleep 60
  done
  
  # exit when single run desired
  if $SINGLE_RUN; then
    break
  fi

  # Wait before checking the connection again
  sleep 60
done
