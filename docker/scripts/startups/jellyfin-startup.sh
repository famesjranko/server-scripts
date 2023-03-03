#!/bin/bash

## =======================================================================
## DOCKER CONTAINER WAIT FOR NETWORK/MOUNT POINT START SCRIPT
##
## This script is used to check for the availability of a mapped drive
## and network connection before starting docker container, and init the
## fail2ban logging workaround.
##
## The script will run until either the drive and network (optional are
## available, at which point it will start the container, clear the
## previous log, and start tail of logging.  Or will exit on fail if the
## loop limit is reached before conditions are met.
##
## The drive and network availability is determined by the stat command
## and ping command, respectively.  Stat requires that the test file has
## been created on the mapped drive beforehand.
##
## The script will also check if the container is already running and
## exit the loop if it is - this is to allow docker restart-policy always
## restart to be used.
## =======================================================================

# Set the script name for echo logging
script_name="JELLYFIN STARTUP"

# Set container name
container=jellyfin

# Set mount point and testfile
drive_mount=/data/media
drive_mount_testfile=/data/media/testfile  # any empty file on the remote drive

# Set network test option and ping address
check_network=false
network_address=8.8.8.8

# Set logging output file path
logging_output_path=/home/docker/jellyfin/container.log

# Set max loop iterations (60x10secs=~10mins)
loop_limit=60

# Init conditional flags and counter
mounted=false
networked=false
loop_count=0

while true; do
    (( loop_count++ ))

    # Check for the availability of the mapped drive
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
	
	# empty old log
	echo $(date '+%y-%m-%d %T')" ["$script_name"]: Clearing older logs from "$logging_output_path
        echo $(date '+%y-%m-%d %T')" ["$script_name"]: Older logs cleared..." > $logging_output_path

	# Start container log tail and redirect to output log - optional: limit to 200 previous lines with '-n 200'
	echo $(date '+%y-%m-%d %T')" ["$script_name"]: Starting log redirect at "$logging_output_path
	docker logs -f -n 200 $container &> $logging_output_path &
	
        break
    fi

    if [[ "$mounted" == "true" && "$networked" == "true" ]]; then
        # Start the container
        echo $(date '+%y-%m-%d %T')" ["$script_name"]: Starting "$container"..."
        docker start $container > /dev/null 2>&1
    fi
    
    # exit if more than 10mins elapsed and some/all containers won't start
    if [[ $loop_count -gt $loop_limit ]]; then
        echo -n $(date +"%y-%m-%d %T")" ["$script_name"]: Exiting after hitting loop limit..."
	echo -n "mounted="$mounted
	echo -n ",networked="$networked
	echo ",$container="$(docker inspect --format='{{.State.Running}}' $container)
        break
    fi

    sleep 10
done
