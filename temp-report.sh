#!/bin/bash
#===============================================================================
# This is a simple script that prints gpu temp, cpu temp, local temp, and deltas.
# Can be used in conjunction with cron scheduling to record temps to log.

# REQUIRES: curl to collect local weather data, nvidia-smi for nvidia gpu temp, 
# and sensors for cpu temp.
#===============================================================================

## get local date and time
date=$(date "+%D - %T")

# get local temp from wttr.in
local_data=$(curl wttr.in/Melbourne?format=1 2> /dev/null)
local_temp=$(echo $local_data | awk '{print $2}' | cut -c 2-3)

## get hw temp
cpu_temp=$(sensors | grep 'Package id 0' | cut -c 17-18)
#cpu_temp=$(/opt/vc/bin/vcgencmd measure_temp | cut -c 6-7) # for raspberry-pi
gpu_temp=$(nvidia-smi -q -d temperature | grep 'GPU Current Temp' | cut -c 45-46)

## calc hw/local temp delta (can assume local temp will always be lower than hw temp)
cpu_delta=$(($cpu_temp - $local_temp))
gpu_delta=$(($gpu_temp - $local_temp))

## print
echo "$date ($local_temp'C): cpu: $cpu_temp'C (delta: +$cpu_delta'C)"
echo "$date ($local_temp'C): gpu: $gpu_temp'C (delta: +$gpu_delta'C)"

exit
