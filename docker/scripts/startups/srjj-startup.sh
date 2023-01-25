#!/bin/bash

## =================================================================
## DOCKER CONTAINER GROUP WAIT FOR REQUIRED CONTAINER START SCRIPT
## 
## Starts a set of containers only if a required container is already
## running... 
##
## Once the required container is running, it will initialise the
## container startup group's startup process.
##
## The script will loop for ~10mins or all containers are running.
## =================================================================

script_name="S-R-J-J STARTUP"

# set required container
required=rutorrent

# set container start group
container_group=(jackett radarr sonarr jellyseerr)

# check if required container is running
required_state=$(docker inspect --format='{{.State.Running}}' $required)
required_running_logged=false
if [[ "$required_state" == "true" ]]; then
	echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$required" is running!"
	required_running_logged=true
fi

# check for already running containers in startup group
for container in ${container_group[@]}; do
    container_state=$(docker inspect --format='{{.State.Running}}' $container)
    if [[ "$container_state" == "true" ]]; then
        echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$container" already up!"
        already_running[$container]=true  # set a flag for container already running
    else
        already_running[$container]=false
    fi
done

# Set max loop iterations (60x10secs=~10mins)
loop_limit=60

loop_count=0

# init startup loop
while true; do
    (( loop_count++ ))

    # check all container states on each loop
    required_state=$(docker inspect --format='{{.State.Running}}' $required)
    for container in ${container_group[@]}; do
        container_state=$(docker inspect --format='{{.State.Running}}' $container)
    done

    # start container_group if required is running
    if [[ "$required_state" == "true" ]]; then

        # log required container running status
        if [[ "$required_running_logged" == "false" ]]; then
            echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$required" is running!"
            required_running_logged=true
        fi

        ## CONTAINER START SECTION
		for container in ${container_group[@]}; do
			if [[ "${already_running[$container]}" == "false" ]]; then
				container_state=$(docker inspect --format='{{.State.Running}}' $container)  # re-assign container state
				if [[ "$container_state" == "false" ]]; then
					docker start $container >& /dev/null
					if [[ $? -eq 0 ]]; then
						echo $(date +"%y-%m-%d %T")" ["$script_name"]: Starting "$container"..."
					else
						echo $(date +"%y-%m-%d %T")" ["$script_name"]: Error starting "$container"! Will try again..."
					fi
				else
					echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$container" started successfully!"
				fi
			fi
		done

		# exit if all containers are up
		all_container_group_up=true
		for container in ${container_group[@]}; do
			container_state=$(docker inspect --format='{{.State.Running}}' $container)
			if [[ "$container_state" != "true" ]]; then
				all_container_group_up=false
				break
			fi
		done

		if [[ "$all_container_group_up" == "true" ]]; then
			echo $(date +"%y-%m-%d %T")" ["$script_name"]: Exiting... All containers up!"
			break
		fi
	fi

	# exit if more than 10mins elapsed and some/all container_group won't start
	if [[ $loop_count -gt $loop_limit ]]; then
		echo -n $(date +"%y-%m-%d %T")" ["$script_name"]: Exiting after hitting loop limit... "
		for container in ${container_group[@]}; do
			container_state=$(docker inspect --format='{{.State.Running}}' $container)
			echo -n $container"="$container_state","
		done
		echo
		break
	fi

    sleep 10
done
