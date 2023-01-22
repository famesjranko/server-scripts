#!/bin/bash

# set database details
DATABASE_FILE=/home/sys_logs/logs/system.db
DATABASE_TABLE=temp_log

# query database min date for default start_date
result=$(sqlite3 $DATABASE_FILE \
"SELECT MIN(datetime) \
FROM $DATABASE_TABLE")

# tokenise query result
IFS=' ' tokens=( $result )

# Define default values for start_date and end_date
start_date="${tokens[0]}"  #"2022-01-18"
#end_date="$(date +%F)"  # todays date
end_date="$(date -d "$(date +%F) + 1 day" +%F)" #tomorrows date

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

## temp_log columns
# 0|datetime|DATETIME|0||0
# 1|local_temp|REAL|0||0
# 2|cpu_temp|REAL|0||0
# 3|cpu_delta|TEXT|0||0
# 4|gpu_temp|REAL|0||0
# 5|gpu_delta|TEXT|0||0
# 6|gpu_util_perc|INTEGER|0||0

# query average temp data from database
result=$(sqlite3 $DATABASE_FILE \
"SELECT MIN(datetime) AS min_date, \
MAX(datetime) AS max_date, \
AVG(local_temp) AS avg_local, \
AVG(cpu_temp) AS avg_cpu, \
AVG(cpu_delta) AS avg_cpu_delta, \
AVG(gpu_temp) AS avg_gpu, \
AVG(gpu_delta) AS avg_gpu_delta, \
COUNT(*) AS record_count \
FROM $DATABASE_TABLE \
WHERE date(datetime) BETWEEN '$start_date' AND '$end_date'")

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

echo -e "AVERAGE LOCAL/CPU/GPU TEMPERATURES:\n"

echo -e "records info:"
printf "%15s %s \n" "start date:" "$start_date"   #"${tokens[0]}"
printf "%15s %s \n" "end date:" "$end_date"       #"${tokens[1]}"
printf "%15s %-4.0f \n" "rows:" ${tokens[7]}

echo -e "\naverage temps:"
printf "%15s %-4.1f'C \n\n" "local:" ${tokens[2]}
printf "%15s %-4.1f'C \n" "cpu:" ${tokens[3]}
printf "%15s %-4.1f'C \n\n" "cpu delta:" ${tokens[4]}
printf "%15s %-4.1f'C \n" "gpu:" ${tokens[5]}
printf "%15s %-4.1f'C \n" "gpu delta:" ${tokens[6]}
