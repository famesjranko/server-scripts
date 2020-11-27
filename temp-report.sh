#!/bin/bash
#===============================================================================
# This is a simple script that prints gpu temp, cpu temp, local temp, and deltas.
# Can be used in conjunction with cron scheduling to record temps to log.

# REQUIRES: inxi or weather-util to collect local weather data, nvidia-smi for 
# nvidia gpu temp, and sensors for cpu temp.
#===============================================================================

## get local date and temp
date=$(date "+%D - %T")
local_temp=$(weather "ymml" | grep Temperature | awk '{print $4}' | cut -c 2-)
#local_temp=$(inxi -w | grep Temperature | awk '{print $3, $4}')

## get hardware temp
cpu_temp=$(sensors | grep 'Package id 0' | cut -c 17-18)
#cpu_temp=$(/opt/vc/bin/vcgencmd measure_temp | cut -c 6-7) # for raspberry-pi
gpu_temp=$(nvidia-smi -q -d temperature | grep 'GPU Current Temp' | cut -c 45-46)

## calc hardware/local temp delta
cpu_delta=$(($cpu_temp - $local_temp))
gpu_delta=$(($gpu_temp - $local_temp))

## print
echo "$date ($local_temp'C): cpu: $cpu_temp'C (delta: +$cpu_delta'C)"
echo "$date ($local_temp'C): gpu: $gpu_temp'C (delta: +$gpu_delta'C)"

exit
