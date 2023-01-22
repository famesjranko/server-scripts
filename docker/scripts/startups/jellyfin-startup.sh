#!/bin/bash

"""
DOCKER CONTAINER WAIT FOR NETWORK/MOUNT POINT START SCRIPT

This script is used to check for the availability of a mapped drive
and network connection before starting a deluge container.

The script will loop indefinitely until the drive and network are
available, at which point it will start the deluge container.

The drive and network availability is determined by the stat command
and ping command, respectively.

The script will also check if the container is already running and
exit the loop if it is.
"""

# Set script options
script_name="JELLYFIN STARTUP"
drive_mount=/data/media
drive_mount_testfile=/data/media/testfile  # any empty file on the remote drive
container=jellyfin # the docker container name

# Set network test option and ping address
check_network=false
network_address=8.8.8.8

# Set default mount and network state flags as false
mounted=false
networked=false

while true; do
    # Check for the availability of the mapped drive
    #if stat $drive_mount_testfile &> /dev/null && "$mounted" == "false"; then
    if [[ "$mounted" == "false" ]]; then
        stat $drive_mount_testfile &> /dev/null
        if [[ $? -eq 0 ]]; then
            echo $(date '+%y-%m-%d %T')" ["$script_name"]: "$drive_mount" is available!"
            mounted=true
        fi
    fi

    # Check the network status
    if [[ "$check_network" == "true" ]]; then
        if [[ "$networked" == "false" ]]; then
            ping -q -c 1 -W 5 $network_address >/dev/null
            if [[ $? -eq 0 ]]; then
                echo $(date '+%y-%m-%d %T')" ["$script_name"]: Network is up!"
                networked=true
            fi
        fi
    else
        networked=true
        check_network=false
    fi

    # Check if the container is running and exit if true
    if [[ $(docker inspect --format='{{.State.Running}}' $container) == "true" ]]; then
        echo $(date '+%y-%m-%d %T')" ["$script_name"]: "$container" is up!"
        break
    fi

    if [[ "$mounted" == "true" && "$networked" == "true" ]]; then
        # Start the container
        echo $(date '+%y-%m-%d %T')" ["$script_name"]: Starting "$container"..."
        docker start $container > /dev/null 2>&1
    fi

    sleep 5
done
