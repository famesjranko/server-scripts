#!/bin/sh

## ================================
#  this is a simple script that
#  prints gpu temp, cpu temp, local temp, and deltas
#
#  REQUIRES: curl to collect local weather data
## ================================

# Get system date
DATE=$(date "+%D - %T")

## ================================
#  WEATHER TEMPERATURE
## ================================

# Set wttr.in location variable
LOCATION=Melbourne

# Set the maximum number of retries for the speedtest command
MAX_RETRIES=6

# Set the delay between retries (in seconds)
RETRY_DELAY=90

local_temp=
weather_na=
tries_count=0

#for i in {1..$MAX_RETRIES}; do
for i in $(seq 1 $MAX_RETRIES); do
  #echo "loop" $i

  # Get local temp
  request=$(curl -s wttr.in/"$LOCATION"?format=%t)

  # Get curl exit code and set wttr n/a conditional
  exit_code=$?

  ## safety check that -> in case local_temp doesn't match regex, is empty, or curl exit code has errors
  ## -> regex matches any string integer or float
  #if ! [[ $request =~ ^\+[0-9]+(\.[0-9]+)?°C$ ]] || [ $exit_code -ne 0 ] || [ -z $request ]
  if ! echo "$request" | grep -qE "^\+[0-9]+(\.[0-9]+)?°C$" || [ $exit_code -ne 0 ] || [ -z "$request" ]
    then
      local_temp="--"
      weather_na=1
    else
      # Remove the leading '+' and '°C' from the temperature value
      local_temp=${request#"+"}
      local_temp=${local_temp%"°C"}

      # change to float with single decimal
      local_temp=$(printf "%2.1f" "$local_temp")
      weather_na=0
  fi

  if [ $weather_na -eq 0 ]; then
    break
  fi

  tries_count=$((tries_count+1))
  sleep $RETRY_DELAY
done

# if all attempts failed, fall back to empty local_temp
if [ $tries_count -eq $MAX_RETRIES ]; then
  #echo "tries_count == MAX_RETRIES"
  local_temp="--"
  weather_na=1
fi

## ================================
#  CPU TEMPERATURE
## ================================

## Get CPU hardware temp
sensors_output=
cpu_temp=

# Check if the 'sensors' command is available
if command -v sensors > /dev/null
  then
    # Get the output of the 'sensors' command as a string
    sensors_output=$(sensors 2> /dev/null)
  else
    # If the 'sensors' command is not available, output an error message
    echo "ERROR: The 'sensors' command is not available."
    exit 1
fi

# Use grep and a regular expression to find the line that matches "Package id 0:  +36.0°C"
line=$(echo "$sensors_output" | grep -E "Package id 0:  \+[0-9]*\.[0-9]*°C")

cpu_na=0
# Check if the line was found
if [ -n "$line" ]
  then
    # Extract the temperature value using a regular expression and store it in a variable
    cpu_temp=$(echo "$line" | grep -Eo "\+[0-9]*\.[0-9]*" | head -n 1)

    # Remove the leading '+' and '°C' from the temperature value
    cpu_temp=${cpu_temp#"+"}
    cpu_temp=${cpu_temp%"°C"}

    # change to float with single decimal
    cpu_temp=$(printf "%2.1f" "$cpu_temp")
  else
    # If the line was not found, output an error message
    #echo "ERROR: Could not find temperature value in the output of the 'sensors' command."
    cpu_temp="--"
    cpu_na=1
fi

## ================================
#  GPU TEMPERATURE
## ================================

gpu_temp=
gpu_na=0

# Check if the 'nvidia-smi' command is installed
if ! which nvidia-smi > /dev/null
  then
    # If the 'nvidia-smi' command is not installed, output an error message and exit with an error code
    #echo "ERROR: The 'nvidia-smi' command is not installed."
    gpu_na=1
    #exit 1
  else
    # Get the output of the 'nvidia-smi' command as a string
    nvidia_output=$(nvidia-smi -q -d temperature)

    # Use grep and the modified regular expression to find the line that matches:
    #   "GPU Current Temp                  : 39 C" and extract the temperature value
    gpu_temp=$(echo "$nvidia_output" | grep -Eo "GPU Current Temp\s*:\s*([0-9]+(\.[0-9]+)?)" | sed -E "s/GPU Current Temp\s*:\s*//")

    # change to float with single decimal
    gpu_temp=$(printf "%2.1f" "$gpu_temp")

    # Get gpu utilisation percentage
    gpu_utilisation=$(nvidia-smi -q -d utilization | grep "Gpu" | awk '{print $3}')

    # Sanity check nvidia output
    if [ -z "$gpu_temp" ]
      then
        gpu_temp="--"
        gpu_na=1
    fi

    # Sanity check nvidia utilisation percentage
    if [ -z "$gpu_utilisation" ]
      then
        gpu_utilisation="--"
    fi
fi

## ================================
#  PRINT RESULTS
## ================================

# Print cpu temp and delta to local temp
if [ $cpu_na -eq 0 ] && [ $weather_na -eq 0 ]
  then
    cpu_delta=$(echo "$cpu_temp - $local_temp" | bc -l)
    printf "%s (%2.1f'C): cpu: %2.1f'C (delta: %+2.1f'C)\n" "$DATE" "$local_temp" "$cpu_temp" "$cpu_delta"

    # change to float with single decimal and +/-
    cpu_delta=$(printf "%+2.1f" "$cpu_delta")
  else
    cpu_delta="--"
    printf "%s (%s): cpu: %2.1f'C (delta: %s)\n" "$DATE" "$local_temp" "$cpu_temp" "$cpu_delta"
fi

# Print gpu temp and delta to local temp
if [ $gpu_na -eq 0 ] && [ $weather_na -eq 0 ]
  then
    gpu_delta=$(echo "$gpu_temp - $local_temp" | bc -l)
    printf "%s (%2.1f'C): gpu: %2.1f'C (delta: %+2.1f'C) (util: %s%%)\n" "$DATE" "$local_temp" "$gpu_temp" "$gpu_delta" "$gpu_utilisation"

    # change to float with single decimal and +/-
    gpu_delta=$(printf "%+2.1f" "$gpu_delta")
  else
    gpu_delta="--"
    printf "%s (%s): gpu: %2.1f'C (delta: %s) (util: %s%%)\n" "$DATE" "$local_temp" "$gpu_temp" "$gpu_delta" "$gpu_utilisation"
fi

# set local temp to NULL if empty
if [ $weather_na -eq 1 ]
  then
    local_temp=NULL
fi

# set cpu temp to NULL if empty
if [ $cpu_na -eq 1 ]
  then
    cpu_temp=NULL
fi

# set gpu temp to NULL if empty
if [ $gpu_na -eq 1 ]
  then
    gpu_temp=NULL
fi

## ======================================
##  Update SQLite database
## ======================================

# Set database file and table names
DATABASE_FILE=/home/sys_logs/logs/system.db
DATABASE_TABLE=temp_log

# Create the logs directory if it doesn't exist
mkdir -p /home/sys_logs/logs

# Create the database table if it doesn't exist
sqlite3 $DATABASE_FILE \
"CREATE TABLE IF NOT EXISTS $DATABASE_TABLE \
(datetime DATETIME, local_temp REAL, cpu_temp REAL, \
cpu_delta TEXT, gpu_temp REAL, gpu_delta TEXT, \
gpu_util_perc INTEGER);"

# Grab timestamp
timestamp=$(date +'%Y-%m-%d %T')

# Insert data into new row of database table
sqlite3 $DATABASE_FILE \
"INSERT INTO $DATABASE_TABLE \
(datetime, local_temp, cpu_temp, cpu_delta, gpu_temp, gpu_delta, gpu_util_perc) \
VALUES ('$timestamp', '$local_temp', '$cpu_temp', '$cpu_delta', '$gpu_temp', '$gpu_delta', '$gpu_utilisation');"
