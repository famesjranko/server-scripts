#!/bin/bash

# set database details
DATABASE_FILE=/home/sys_logs/logs/system.db
DATABASE_TABLE=net_log

# query database min date for default start_date
result=$(sqlite3 $DATABASE_FILE \
"SELECT MIN(datetime) \
FROM $DATABASE_TABLE")

# tokenise query result
IFS=' ' tokens=( $result )

# Define default values for start_date and end_date
start_date="${tokens[0]}"  #"2022-01-18"
end_date="$(date +%F)"

# parse options
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -s|--startdate )
      start_date="$2"
      shift
      ;;
    -e|--enddate )
      end_date="$2"
      shift
      ;;
    -h|--help )
      echo "Usage: script_name.sh [-s/--startdate start_date] [-e/--enddate end_date] [-h/--help]"
      exit 0
      ;;
    * )
      echo "Invalid option: $key"
      echo "Usage: script_name.sh [-s/--startdate start_date] [-e/--enddate end_date] [-h/--help]"
      exit 1
      ;;
  esac
  shift
done

# Check if start date is earlier than end date
if [[ $(date -d "$start_date") < $(date -d "$end_date") ]]; then
  echo "Error: Start date must be earlier than end date"
  exit 1
fi

## net_log columns
# 0|datetime|DATETIME|0||0
# 1|server_id|INTEGER|0||0
# 2|sponsor|TEXT|0||0
# 3|server_name|TEXT|0||0
# 4|distance|REAL|0||0
# 5|ping|REAL|0||0
# 6|download|REAL|0||0
# 7|upload|REAL|0||0
# 8|share|REAL|0||0
# 9|ip_address|TEXT|0||0

# query average temp data from database
result=$(sqlite3 $DATABASE_FILE \
"SELECT MIN(datetime), \
MAX(datetime), \
AVG(download), \
AVG(upload), \
AVG(ping), \
COUNT(*) \
FROM $DATABASE_TABLE \
WHERE DATE(datetime) BETWEEN '$start_date' AND '$end_date' \
ORDER BY datetime")

# tokenise query result
IFS='|' tokens=( $result )

#cmd="SELECT * FROM $DATABASE_TABLE"
#IFS=$'\n'
#fqry=(`sqlite3 $DATABASE_FILE "$cmd"`)

#for f in "${fqry[@]}"; do
#    echo "$f"
#done

# check if min date was in query
if [[ ! -z "${tokens[0]}" ]];
  then
    # change to min date found
    start_date="${tokens[0]}"
  else
    # add source tag
    start_date=$(echo $start_date "(not found)")
fi

# make sure download avg is not empty
if [[ ! -z "${tokens[1]}" ]];
  then
    # change to max date found
    end_date="${tokens[1]}"
  else
    end_date=$(echo $end_date "(not found)")
fi

echo -e "AVERAGE DOWNLOAD/UPLOAD/PING SPEEDS:\n"

echo -e "records info:"
printf "%15s %s \n" "start date:" "$start_date"   #"${tokens[0]}"
printf "%15s %s \n" "end date:"  "$end_date"      #"${tokens[1]}"
printf "%15s %-4.0f \n" "rows:" ${tokens[5]}

# make sure download avg is not empty
if [[ ! -z "${tokens[2]}" ]]; then
  # convert bits to Mbps
  download=$(echo "${tokens[2]} / 1000000" | bc -l)
fi

# make sure upload avg is not empty
if [[ ! -z "${tokens[3]}" ]]; then
  # convert bits to Mbps
  upload=$(echo "${tokens[3]} / 1000000" | bc -l)
fi

echo -e "\naverage speeds:"
printf "%15s %-4.1f Mbps\n" "download:" $download
printf "%15s %-4.1f Mbps\n" "upload:" $upload
printf "%15s %-4.1f ms\n" "ping:" ${tokens[4]}
