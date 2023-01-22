#!/bin/bash

## ======================================
##  Run a network speed test
## ======================================

# Set the path to the speedtest command
SPEEDTEST_CMD="/usr/bin/speedtest"

# Set the maximum number of retries for the speedtest command
MAX_RETRIES=5

# Set the delay between retries (in seconds)
RETRY_DELAY=30
tries_count=0

output=

# Run the speedtest command and store the output in a variable
for i in $(seq 1 $MAX_RETRIES); do
  # Run the speedtest command
  output=$($SPEEDTEST_CMD --csv 2>/dev/null)

  # Check if OUTPUT is empty
  if [ -z "$output" ]
    then
      #echo "output is empty, retrying in $RETRY_DELAY seconds"
      #echo $output

      tries_count=$((tries_count+1))
      sleep $RETRY_DELAY
      continue
    else
      #echo "output not empty!"
      #echo $output
      break
  fi
done

#echo "tries_count" $tries_count
#echo "MAX_RETRIES" $MAX_RETRIES

# if all attempts failed, fall back to empty local_temp
if [ $tries_count -eq $MAX_RETRIES ]
  then
    output="n/a"
fi

# Print the output of the speedtest command to the console
echo "\"$(date '+%R %x')\"," $output


## ======================================
##  Update SQLite database
## ======================================

# Set database file and table names
DATABASE_FILE=/home/sys_logs/logs/system.db
DATABASE_TABLE=net_log

if [[ $output != "n/a" ]]; then
    # Create the logs directory if it doesn't exist
    mkdir -p /home/sys_logs/logs

    # Create net_log table
    sqlite3 $DATABASE_FILE \
    "CREATE TABLE IF NOT EXISTS $DATABASE_TABLE \
    (datetime DATETIME, server_id INTEGER, sponsor TEXT, \
    server_name TEXT, distance REAL, ping REAL, \
    download REAL, upload REAL, share REAL, ip_address TEXT);"

    # Initialize an empty variable called "array"
    array=

    # Store the speedtest output into an array
    IFS=',' read -a array <<< "$output"

    # change the timestamp
    array[3]=$(date +'%Y-%m-%d %T')

    # Reorder the values in the array
    output_array=("${array[3]}" "${array[0]}" "${array[1]}" "${array[2]}" "${array[4]}" "${array[5]}" "${array[6]}" "${array[7]}" "${array[8]}" "${array[9]}")

    # Initialize an empty variable called "values"
    values=

    # Loop through each element in the "output_array" array
    for value in "${output_array[@]}"; do
        # For each element, add it to the "values" variable with double quotes and a comma after it
        values+="\"$value\","
    done

    # Remove the last character (the trailing comma) from the "values" variable
    values="${values%?}"

    # Insert the output array into the SQLite file
    # table structure: Timestamp,Server ID,Sponsor,Server Name,Timestamp,Distance,Ping,Download,Upload,Share,IP Address
    sqlite3 $DATABASE_FILE \
    "INSERT INTO $DATABASE_TABLE \
    (datetime, server_id, sponsor, server_name, distance, ping, download, upload, share, ip_address) \
    VALUES ($values);"

    # Print SQLite table
    #sqlite3 $DATABASE_FILE "SELECT * FROM $DATABASE_TABLE ORDER BY datetime ASC;"
fi
