#!/bin/bash

script_name="S-R-J-J STARTUP"

# set container names
container1=deluge
container2=jackett
container3=radarr
container4=sonarr
container5=jellyseerr

deluge=$(docker inspect --format='{{.State.Running}}' $container1)
jackett=$(docker inspect --format='{{.State.Running}}' $container2)
radarr=$(docker inspect --format='{{.State.Running}}' $container3)
sonarr=$(docker inspect --format='{{.State.Running}}' $container4)
jellyseerr=$(docker inspect --format='{{.State.Running}}' $container5)

# check for already running containers
if [[ "$jackett" == "true" ]]; then
    echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$container2" already up!"
fi

if [[ "$radarr" == "true" ]]; then
    echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$container3" already up!"
fi

if [[ "$sonarr" == "true" ]]; then
    echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$container4" already up!"
fi

if [[ "$jellyseerr" == "true" ]]; then
    echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$container5" already up!"
fi

# set loop counter, and single print flag for deluge container
loop_count=0
deluge_up=false

while true; do
    (( loop_count++ ))

    # check all container states on each loop
    deluge=$(docker inspect --format='{{.State.Running}}' $container1)
    jackett=$(docker inspect --format='{{.State.Running}}' $container2)
    radarr=$(docker inspect --format='{{.State.Running}}' $container3)
    sonarr=$(docker inspect --format='{{.State.Running}}' $container4)
    jellyseerr=$(docker inspect --format='{{.State.Running}}' $container5)

    # start jackett radarr sonarr and jellyseer if deluge is running
    # if deluge is running, that means torrent mapped drive and network are up!
    if [[ "$deluge" == "true" ]]; then

        # log deluge container running status
        if [[ "$deluge_up" == "false" ]]; then
            #echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$container1" is running!"
            deluge_up=true
        fi

        ## JACKET CONTAINER START SECTION
        if [[ "$jackett" == "false" ]]; then
            docker start $container2 >& /dev/null
            if [[ $? -eq 0 ]]; then
                echo $(date +"%y-%m-%d %T")" ["$script_name"]: Starting "$container2"..."
            else
                echo $(date +"%y-%m-%d %T")" ["$script_name"]: Error starting "$container2"! Will try again..."
            fi
        else
            echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$container2" started successfully!"
        fi

        ## RADARR CONTAINER START SECTION
        if [[ "$radarr" == "false" ]]; then
            docker start $container3 >& /dev/null
            if [[ $? -eq 0 ]]; then
                echo $(date +"%y-%m-%d %T")" ["$script_name"]: Starting "$container3"..."
            else
                echo $(date +"%y-%m-%d %T")" ["$script_name"]: Error starting "$container3"! Will try again..."
            fi
        else
            echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$container3" started successfully!"
        fi

        ## SONARR CONTAINER START SECTION
        if [[ "$sonarr" == "false" ]]; then
            docker start $container4 >& /dev/null
            if [[ $? -eq 0 ]]; then
                echo $(date +"%y-%m-%d %T")" ["$script_name"]: Starting "$container4"..."
            else
                echo $(date +"%y-%m-%d %T")" ["$script_name"]: Error starting "$container4"! Will try again..."
            fi
        else
            echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$container4" started successfully!"
        fi

        ## JELLYSEERR CONTAINER START SECTION
        if [[ "$jellyseerr" == "false" ]]; then
            docker start $container5 >& /dev/null
            if [[ $? -eq 0 ]]; then
                echo $(date +"%y-%m-%d %T")" ["$script_name"]: Starting "$container5"..."
            else
                echo $(date +"%y-%m-%d %T")" ["$script_name"]: Error starting "$container5"! Will try again..."
            fi
        else
            echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$container5" started successfully!"
        fi

    else
        echo $(date +"%y-%m-%d %T")" ["$script_name"]: "$container1" is not running yet..."
    fi

    # exit if all containers are up
    if [[ "$jackett" == "true" && "$radarr" == "true" && "$sonarr" == "true" && "$jellyseerr" == "true" ]]; then
        echo $(date +"%y-%m-%d %T")" ["$script_name"]: Exiting... All containers up!"
        break
    fi

    # exit if more than 10mins elapsed and some/all containers won't start
    if [[ $loop_count -gt 60 ]]; then
         echo $(date +"%y-%m-%d %T")" ["$script_name"]: Exiting after 60 loops... sonarr="$sonarr",radarr="$radarr",jackett="$jackett",jellyseerr="$jellyseerr
        break
    fi

    sleep 10
done
