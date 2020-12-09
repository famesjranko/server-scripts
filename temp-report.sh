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

## get local temp
locale=Melbourne
local_data=$(curl wttr.in/$locale?format=%t 2> /dev/null)
local_temp=$(echo $local_data | tr -dc '[:alnum:]' | sed 's/C$//')
na=0

if [ "$local_temp" = "SorrywearerunningoutofqueriestotheweatherserviceatthemomentHereistheweatherreportforthedefaultcityjusttoshowyouwhatitlookslikeWewillgetnewqueriesassoonaspossibleYoucanfollowhttpstwittercomigorchubinfortheupdates" ]; then
    local_temp="--"
    na=1
fi

## get hw temp
cpu_temp=$(sensors | grep 'Package id 0' | cut -c 17-18)
#cpu_temp=$(/opt/vc/bin/vcgencmd measure_temp | cut -c 6-7) # for raspberry-pi
gpu_temp=$(nvidia-smi -q -d temperature | grep 'GPU Current Temp' | cut -c 45-46)

## calc hw/local temp delta (can assume local temp will always be lower than hw temp)
if [ $na -eq 1 ]; then
    cpu_delta="--"
    gpu_delta="--"
else
    cpu_delta=$(($cpu_temp - $local_temp))
    gpu_delta=$(($gpu_temp - $local_temp))
fi

## adds leading space to var when local -lt 10'C for ouput alignment
## eg: transforms (9) into ( 9)
if [ ${#local_temp} -lt 2 ]; then
    local_temp=" $local_temp"
fi

## print
echo "$date ($local_temp'C): cpu: $cpu_temp'C (delta: +$cpu_delta'C)"
echo "$date ($local_temp'C): gpu: $gpu_temp'C (delta: +$gpu_delta'C)"

exit
