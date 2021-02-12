#!/bin/bash

## set temp logging input/output files
input="/home/dorothy/temp.log"
output="/home/dorothy/temp_graph.log"

## set variables
date=''
clock=''
local_temp=''
cpu_temp=''
gpu_temp=''

## set counters/checks
hw_check=''
hw_count=0

## reset file and set graphing header for output
echo "date; time; local-temp; cpu-temp; gpu-temp" > $output

while IFS= read -r line
do
  ## get variables
  date=$(echo $line | awk '{print $1}')
  clock=$(echo $line | awk '{print $3}')
  local_temp=$(echo $line | awk '{print $4}' | cut -c 2-3)

  ## check if gpu or cpu
  hw_check=$(echo $line | awk '{print $5}' | cut -c -3)

  ## get cpu or gpu variable
  if [ "$hw_check" == "cpu" ]; then
    cpu_temp=$(echo $line | awk '{print $6}' | cut -c -2)
    hw_count=$((hw_count+1))
  elif [ "$hw_check" == "gpu" ]; then
    gpu_temp=$(echo $line | awk '{print $6}' | cut -c -2)
    hw_count=$((hw_count+1))
  fi

  ## print variables to graphing log
  if [ $hw_count -eq 2 ]; then
    echo "$date; $clock; $local_temp; $cpu_temp; $gpu_temp" >> $output
    hw_count=0
  fi

  ## reset h/w check
  hw_check=''
done < "$input"

echo "done!"
exit
