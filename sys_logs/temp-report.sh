#!/bin/bash
#=========================================================================
# This script prints gpu temp, cpu temp, local temp, and deltas.
# Can be used in conjunction with cron scheduling to record temps to log.
#
# REQUIRES: curl to collect local weather data;
#           nvidia-smi for nvidia gpu temp;
#           sensors for cpu temp.
#=========================================================================

## set wttr.in location variable
locale=Melbourne

## get sys date
date=$(date "+%D - %T")

## get local temp
local_data=$(curl wttr.in/$locale?format=%t 2> /dev/null)

## get curl exit code and set wttr n/a conditional
exit_code=$?
na=0

## check wttr exit code and output against regex and not empty, remove all non-integers if passes.
if ! [[ $local_data =~ [+][0-9].{2}C ]] || [ $error_code -ne 0 ] || [ -z $local_data ]; then
    na=1
else
    local_temp=$(echo $local_data | tr -dc '[:alnum:]' | sed 's/C$//' 2> /dev/null)
fi

## get hw temp
cpu_temp=$(sensors | grep 'Package id 0' | cut -c 17-18)
#cpu_temp=$(/opt/vc/bin/vcgencmd measure_temp | cut -c 6-7) # for raspberry-pi
gpu_temp=$(nvidia-smi -q -d temperature | grep 'GPU Current Temp' | cut -c 45-46)

## calc hw/local temp delta (can assume local temp will always be lower than hw temp)
## returns "--" for local temp when na=1
if [ $na -eq 1 ]; then
    cpu_delta="--"
    gpu_delta="--"
else
    cpu_delta=$(($cpu_temp - $local_temp))
    gpu_delta=$(($gpu_temp - $local_temp))
fi

## add leading space when values less than 10 for ouput alignment
## eg: transforms (9'C) into ( 9'C)
if [ ${#local_temp} -lt 2 ]; then
    local_temp=" $local_temp"
fi

if [ ${#cpu_temp} -lt 2 ]; then
    cpu_temp=" $cpu_temp"
fi

if [ ${#gpu_temp} -lt 2 ]; then
    gpu_temp=" $gpu_temp"
fi

if [ ${#cpu_delta} -lt 2 ]; then
    cpu_delta=" $cpu_delta"
fi

if [ ${#gpu_delta} -lt 2 ]; then
    gpu_delta=" $gpu_delta"
fi

## output
echo "$date ($local_temp'C): cpu: $cpu_temp'C (delta: +$cpu_delta'C)"
echo "$date ($local_temp'C): gpu: $gpu_temp'C (delta: +$gpu_delta'C)"

exit
