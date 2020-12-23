#!/bin/bash
#=========================================================================
# This script prints gpu temp, cpu temp, local temp, and deltas.
# Can be used in conjunction with cron scheduling to record temps to log.
#
# REQUIRES: curl to collect local weather data;
#           nvidia-smi for nvidia gpu temp;
#           sensors for cpu temp.
#=========================================================================

## get sys date
date=$(date "+%D - %T")

## set wttr n/a conditional
na=0

## get local temp
locale=Melbourne
local_data=$(curl wttr.in/$locale?format=%t 2> /dev/null)

## check wttr output against regex, convert if passes
if ! [[ $local_data =~ [+][0-9].{2}C ]]; then
    na=1
else
    local_temp=$(echo $local_data | tr -dc '[:alnum:]' | sed 's/C$//' 2> /dev/null)
fi

## check converted wttr data sanity
if [ "$local_temp" = "SorrywearerunningoutofqueriestotheweatherserviceatthemomentHereistheweatherreportforthedefaultcityjusttoshowyouwhatitlookslikeWewillgetnewqueriesassoonaspossibleYoucanfollowhttpstwittercomigorchubinfortheupdates" ]; then
    local_temp="--"
    na=1
elif [ "$local_temp" = "Unknownlocationpleasetry3781421751449631608" ]; then
    local_temp="--"
    na=1
elif [ "$local_temp" = "- " ]; then
    local_temp="--"
    na=1
elif [ -z "$local_temp" ]; then
    local_temp="--"
    na=1
fi

## get hw temp
cpu_temp=$(sensors | grep 'Package id 0' | cut -c 17-18)
#cpu_temp=$(/opt/vc/bin/vcgencmd measure_temp | cut -c 6-7) # for raspberry-pi
gpu_temp=$(nvidia-smi -q -d temperature | grep 'GPU Current Temp' | cut -c 45-46)

## calc hw/local temp delta (can assume local temp will always be lower than hw temp)
## returns -- when local temp is not available
if [ $na -eq 1 ]; then
    cpu_delta="--"
    gpu_delta="--"
else
    cpu_delta=$(($cpu_temp - $local_temp))
    gpu_delta=$(($gpu_temp - $local_temp))
fi

## adds leading space to local temp when -lt 10'C for ouput alignment
## eg: transforms (9'C) into ( 9'C)
if [ ${#local_temp} -lt 2 ]; then
    local_temp=" $local_temp"
fi

## output
echo "$date ($local_temp'C): cpu: $cpu_temp'C (delta: +$cpu_delta'C)"
echo "$date ($local_temp'C): gpu: $gpu_temp'C (delta: +$gpu_delta'C)"

exit
