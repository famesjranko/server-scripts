#!/bin/bash

## =================================================================
## DOCKER CONTAINER GROUP WAIT FOR REQUIRED CONTAINER START SCRIPT
## 
## This script is used to start a set of containers in a specific
## order and only when certain conditions are met.
##
## The script will loop indefinitely until the deluge container
## is running. Once the deluge container is running, it will start
## the jackett, radarr, sonarr and jellyseerr containers.
## 
## If any of the jackett, radarr, sonarr and jellyseerr containers
## are already running when the script is started, it will log that
## they are already running and skip starting them.
## =================================================================

script_name="S-R-J-J STARTUP"

# required container before starting group
required=rutorrent #deluge

# container start group
container1=jackett
container2=radarr
container3=sonarr
container4=jellyseerr

# set initial container states
required_state=$(docker inspect --format='{{.State.Running}}' $required)
container1_state=$(docker inspect --format='{{.State.Running}}' $container1)
container2_state=$(docker inspect --format='{{.State.Running}}' $container2)
container3_state=$(docker inspect --format='{{.State.Running}}' $container3)
container4_state=$(docker inspect --format='{{.State.Running}}' $container4)

# check for already running containers
if [[ "$container1_state" == "true" ]]; then
    echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$container1" already up!"
fi

if [[ "$container2_state" == "true" ]]; then
    echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$container2" already up!"
fi

if [[ "$container3_state" == "true" ]]; then
    echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$container3" already up!"
fi

if [[ "$container4_state" == "true" ]]; then
    echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$container4" already up!"
fi

# init loop counter and echo flag
loop_count=0
required_state_up=false

while true; do
    (( loop_count++ ))

    # check all container states on each loop
    required_state=$(docker inspect --format='{{.State.Running}}' $required)
    container1_state=$(docker inspect --format='{{.State.Running}}' $container1)
    container2_state=$(docker inspect --format='{{.State.Running}}' $container2)
    container3_state=$(docker inspect --format='{{.State.Running}}' $container3)
    container4_state=$(docker inspect --format='{{.State.Running}}' $container4)

    # start container1 container2 container3 and container4 if required is running
    # if required container is running, that means torrent mapped drive and network are up!
    if [[ "$required_state" == "true" ]]; then

        # log required container running status
        if [[ "$required_state_up" == "false" ]]; then
            echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$required" is running!"
            required_state_up=true
        fi

        ## CONTAINER1 START SECTION
        if [[ "$container1_state" == "false" ]]; then
            docker start $container1 >& /dev/null
            if [[ $? -eq 0 ]]; then
                echo $(date +"%y-%m-%d %T")" ["$script_name"]: Starting "$container1"..."
            else
                echo $(date +"%y-%m-%d %T")" ["$script_name"]: Error starting "$container1"! Will try again..."
            fi
        else
            echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$container1" started successfully!"
        fi

        ## CONTAINER2 START SECTION
        if [[ "$container2_state" == "false" ]]; then
            docker start $container2 >& /dev/null
            if [[ $? -eq 0 ]]; then
                echo $(date +"%y-%m-%d %T")" ["$script_name"]: Starting "$container2"..."
            else
                echo $(date +"%y-%m-%d %T")" ["$script_name"]: Error starting "$container2"! Will try again..."
            fi
        else
            echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$container2" started successfully!"
        fi

        ## CONTAINER3 START SECTION
        if [[ "$container3_state" == "false" ]]; then
            docker start $container3 >& /dev/null
            if [[ $? -eq 0 ]]; then
                echo $(date +"%y-%m-%d %T")" ["$script_name"]: Starting "$container3"..."
            else
                echo $(date +"%y-%m-%d %T")" ["$script_name"]: Error starting "$container3"! Will try again..."
            fi
        else
            echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$container3" started successfully!"
        fi

        ## CONTAINER4 START SECTION
        if [[ "$container4_state" == "false" ]]; then
            docker start $container4 >& /dev/null
            if [[ $? -eq 0 ]]; then
                echo $(date +"%y-%m-%d %T")" ["$script_name"]: Starting "$container4"..."
            else
                echo $(date +"%y-%m-%d %T")" ["$script_name"]: Error starting "$container4"! Will try again..."
            fi
        else
            echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$container4" started successfully!"
        fi

    else
        echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$required" is not running yet..."
    fi

    # exit if all containers are up
    if [[ "$container1_state" == "true" && "$container2_state" == "true" && "$container3_state" == "true" && "$container4_state" == "true" ]]; then
        echo $(date +"%y-%m-%d %T")" ["$script_name"]: Exiting... All containers up!"
        break
    fi

    # exit if more than 10mins elapsed and some/all containers won't start
    if [[ $loop_count -gt 60 ]]; then
         echo $(date +"%y-%m-%d %T")" ["$script_name"]: Exiting after 60 loops... "$container1"="$container3_state","$container2"="$container2_state","$container3"="$container3_state","$container4"="$container4_state
        break
    fi

    sleep 10
done

