#!/bin/bash

# Script to rename log files by appending the current date to the end of the filename and keeping the file extension the same

# Find all log files in current directory and rename them
#find . -maxdepth 1 -type f -name "*.log" | while read -r filename; do

# Find all log files in specified directories and rename them
find logs/net logs/temp logs/boot -type f -name "*.log" | while read -r filename; do
  printf "Checking file: $filename\n"

  # Check if the file exists
  if [[ -f $filename ]]; then
    # Confirm filename ends with .log suffix
    if [[ $filename =~ \.log$ ]]; then
      printf "\tFilename ends with .log suffix\n"

      # Count the number of lines in the file
      line_count=$(wc -l < "$filename")
      printf "\tLine count: $line_count\n"

      # Check if the file has more than 1000 lines
      if [ $line_count -gt 1000 ]; then
        printf "\tFile has more than 1000 lines...\n"

        # Append the current date to the end of the filename and change extension to .old
        new_filename="$(basename "$filename" .log)_$(date +%Y%m%d-%H%M%S).old"
        printf "\tRenaming file to: $new_filename\n"
        mv "$filename" "$new_filename"

        # Create subdirectory for the file
        subdir_name="$(basename "$filename" .log)"
        mkdir -p "logs/$subdir_name"

        # Move the file to the new subdirectory
        mv "$new_filename" "logs/$subdir_name/$new_filename"

        # Create an empty file with the original filename
        touch "$filename"

        # Set permissions 664 for the new file
        chmod 664 "$filename"

        printf "\tCreated empty file with original filename: $filename\n"
      else
        printf "\tFile does not have more than 1000 lines, skipping\n"
      fi
    else
      printf "\tFilename does not end with .log suffix, skipping\n"
    fi
    #printf "\n"
  else
    printf "\tFile not found, skipping\n"
  fi
done

printf "Finished processing files\n"
