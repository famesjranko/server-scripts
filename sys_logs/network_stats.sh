#!/bin/bash

# Initialize variables to store the total sum
total_download=0
total_upload=0
total_ping=0
line_count=0

# Initialize line count variables
line_count_download=0
line_count_upload=0
line_count_ping=0
line_count_total=0

# Initialize empty count variables
empty_ping_count=0
empty_download_count=0
empty_upload_count=0

# Define the date range
#start_date="12/01/23"
#end_date="20/01/23"

if [[ "$1" == "--help" ]]; then
  echo -e "To set a search for a given date range, please provide\nthe date range in the following format: DD/MM/YY"
  echo -e "\nNote: the start date must be less than the end date"
  echo -e "example: ./network_stat.sh 12/01/23 13/01/23"
  exit 0
fi

if [[ "$1" > "$2" ]]; then
  echo "Error: Start date must be less than end date"
  exit 1
fi

start_date="${1:-""}"
end_date="${2:-""}"

# Date,Server ID,Sponsor,Server Name,Timestamp,Distance,Ping,Download,Upload,Share,IP Address

# convert dates
#start_date=$(echo $start_date | awk -F '/' '{print "20"$3"-"$2"-"$1}')
#end_date=$(echo $end_date | awk -F '/' '{print "20"$3"-"$2"-"$1}')

#max_date=$start_date
#min_date=$end_date

if [[ -n "$start_date" && -n "$end_date" ]];
    then
        start_date=$(echo $start_date | awk -F '/' '{print "20"$3"-"$2"-"$1}')
        end_date=$(echo $end_date | awk -F '/' '{print "20"$3"-"$2"-"$1}')
    else
        start_date="01/01/23"
        end_date="01/01/40"
fi

max_date=$start_date
min_date=$end_date

# set the working dir
cd /home/sys_logs

# Process the first file
while IFS=',' read -r date _ _ _ _ _ ping download upload _ _; do
    # grab and convert date
    date_value=$(echo $date | awk '{gsub(/"$/,"",$2);print $2}')
    date_value=$(echo $date_value | awk -F '/' '{print "20"$3"-"$2"-"$1}')

    # Check if the date is within the specified range
    # If a date range is not specified, add all values to the total sum
    if [[ -z $start_date || -z $end_date || ( $(date -d $date_value +%s) -ge $(date -d $start_date +%s) && $(date -d $date_value +%s) -le $(date -d $end_date +%s) ) ]]; then
        #echo $date_value
        if [[ -n $ping ]];
            then
                total_ping=$(echo "scale=2; $total_ping + $ping" | bc -l)
                line_count_ping=$((line_count_ping+1))
            else
                empty_ping_count=$((empty_ping_count+1))
        fi
        if [[ -n $upload ]];
            then
                upload=$(echo "$upload / 1048576" | bc -l)
                total_upload=$(echo "scale=2; $total_upload + $upload" | bc -l)
                line_count_upload=$((line_count_upload+1))
            else
                empty_upload_count=$((empty_upload_count+1))
        fi
        if [[ -n $download ]];
            then
                download=$(echo "$download / 1048576" | bc -l)
                total_download=$(echo "scale=2; $total_download + $download" | bc -l)
                line_count_download=$((line_count_download+1))
            else
                empty_download_count=$((empty_download_count+1))
        fi

        # Compare and update the minimum and maximum date found
        if [[ $(date -d $date_value +%s) -ge $(date -d $max_date +%s) ]]; then
            max_date=$date_value
        fi
        if [[ $(date -d $date_value +%s) -le $(date -d $min_date +%s) ]]; then
            min_date=$date_value
        fi

        # increment line count
        line_count_total=$((line_count_total+1))
    fi
done < logs/net/net.log

# Process the remaining files
for file in logs/net/net_*.old; do
  if [ -f "$file" ]; then
    while IFS=',' read -r date _ _ _ _ _ ping download upload _ _; do
        # grab and convert date
        date_value=$(echo $date | awk '{gsub(/"$/,"",$2);print $2}')
        date_value=$(echo $date_value | awk -F '/' '{print "20"$3"-"$2"-"$1}')

        # If a date range is not specified, add all values to the total sum
        if [[ -z $start_date || -z $end_date || ( $(date -d $date_value +%s) -ge $(date -d $start_date +%s) && $(date -d $date_value +%s) -le $(date -d $end_date +%s) ) ]]; then
           if [[ -n $ping ]];
               then
                   total_ping=$(echo "scale=2; $total_ping + $ping" | bc -l)
                   line_count_ping=$((line_count_ping+1))
               else
                   empty_ping_count=$((empty_ping_count+1))
           fi
           if [[ -n $upload ]];
               then
                   upload=$(echo "$upload / 1048576" | bc -l)
                   total_upload=$(echo "scale=2; $total_upload + $upload" | bc -l)
                   line_count_upload=$((line_count_upload+1))
               else
                   empty_upload_count=$((empty_upload_count+1))
           fi
           if [[ -n $download ]];
               then
                   download=$(echo "$download / 1048576" | bc -l)
                   total_download=$(echo "scale=2; $total_download + $download" | bc -l)
                   line_count_download=$((line_count_download+1))
               else
                   empty_download_count=$((empty_download_count+1))
           fi

           # Compare and update the minimum and maximum date found
           if [[ $(date -d $date_value +%s) -ge $(date -d $max_date +%s) ]]; then
               max_date=$date_value
           fi
           if [[ $(date -d $date_value +%s) -le $(date -d $min_date +%s) ]]; then
               min_date=$date_value
           fi

           # increment line count
           line_count_total=$((line_count_total+1))
        fi
    done < $file
  #else
    #echo "No files found in logs/net"
  fi
done

# Print header
echo -e "Average download/upload/ping:\n"

# Print download, upload and ping averages
if [[ $line_count_download -gt 0 ]]; then
    average_download=$(echo "scale=2; $total_download / $line_count_download" | bc -l)
    percent_found_download=$(echo "scale=2; ($line_count_download / $line_count_total) * 100" | bc -l)
    #echo "Average download: $average_download Mbps ($percent_found_download%)"
    printf "%20s %8.2f Mbps %8.2f%%\n" "Average download:" $average_download $percent_found_download
else
    echo -e "\tNot enough data to calculate average for download"
fi

if [[ $line_count_upload -gt 0 ]]; then
    average_upload=$(echo "scale=2; $total_upload / $line_count_upload" | bc -l)
    percent_found_upload=$(echo "scale=2; ($line_count_upload / $line_count_total) * 100" | bc -l)
    #echo "Average upload: $average_upload Mbps ($percent_found_upload%)"
    printf "%20s %8.2f Mbps %8.2f%%\n" "Average upload:" $average_upload $percent_found_upload
else
    echo -e "\tNot enough data to calculate average for upload"
fi

if [[ $line_count_ping -gt 0 ]]; then
    average_ping=$(echo "scale=2; $total_ping / $line_count_ping" | bc -l)
    percent_found_ping=$(echo "scale=2; ($line_count_ping / $line_count_total) * 100" | bc -l)
    #echo "Average ping: $average_ping ms ($percent_found_ping%)"
    printf "%20s %8.2f ms %10.2f%%\n" "Average ping:" $average_ping $percent_found_ping
else
    echo -e "\tNot enough data to calculate average for ping"
fi

# Print the minimum and maximum date found
echo -e "\nDate range found: $min_date to $max_date"

# Print the totals
#echo "Total download: $total_download Mbps"
#echo "Total upload: $total_upload Mbps"
#echo "Total ping: $total_ping"
#echo "Total lines: " $line_count_total
