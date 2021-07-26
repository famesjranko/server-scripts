## this script gets takes network internet speeds
## from a log file and returns the average speeds
## of download, upload and latency.

#!/bin/bash

# get log file
INPUT="/home/dorothy/net-speed_readable.log"

# set wanted log variable value
declare -a WANTED=("Download" "Upload" "Latency")

# get number of logs associated with wanted variable
COUNT=$(cat net-speed_readable.log | grep -c ${WANTED[0]})

# loop through WANTED array
for i in "${WANTED[@]}"
do
  # set total, high and low vars
  TOTAL=0
  HIGH=0
  LOW=0
  METRIC=""

  # loop through each line of log file, find wanted value and add to total
  while IFS= read -r LINE
  do
    # get wanted value
    NUMBER=$(echo $LINE | grep $i | awk '{print $2}')

    if [ ! -z "$NUMBER" ]; then
      # get the metric for wanted
      if [ -z "$METRIC" ]; then
        METRIC=$(echo $LINE | grep $i | awk '{print $3}')
      fi

      # add wanted to total
      TOTAL=$(echo $TOTAL $NUMBER | awk '{print $1 + $2}')

      # compare for highest wanted
      if (( $(echo "$NUMBER > $HIGH" | bc -l) )); then
        HIGH=$NUMBER
      fi

      # compare for lowest wanted
      if (( $(echo "$LOW < 1" | bc -l) )); then
        LOW=$NUMBER
      elif (( $(echo "$NUMBER < $LOW" | bc -l) )); then
        LOW=$NUMBER
      fi
    fi
  done < "$INPUT"

  # calculate average, divide total by the number of cases
  AVG=$(echo "scale=2; $TOTAL / $COUNT" | bc)

  # print info
  if [ "$i" == "Download" ]; then
    echo "Downloads:"
  elif [ "$i" == "Upload" ]; then
    echo "Uploads:"
  elif [ "$i" == "Latency" ]; then
    echo "Latency:"
  fi
  printf "%12s %5s %s\n" "highest:" "$HIGH" "($METRIC)"
  printf "%12s %5s %s\n"  "lowest:" "$LOW" "($METRIC)"
  printf "%12s %5s %s\n" "average:" "$AVG" "($METRIC)"
  echo
done

# print number of cases
printf "%12s %5s %s\n" "Across:" "$COUNT" "(cases)"
