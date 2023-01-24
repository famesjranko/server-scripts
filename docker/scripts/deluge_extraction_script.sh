#!/bin/bash

## ====================================================================================
## This is a Deluge script for extracting archive torrent files after downloading
## has completed.  It supports the following archive formats: zip and rar.
## It also has the option to delete the archive files following extraction by setting
## the delete flag true
##
## It takes 3 arguments:
##   torrentid: the id of the torrent
##   torrentname: the name of the torrent
##   torrentpath: the path to the torrent directory
##
## The extracted files will be in the same directory as the archive files.
##
## Usage: ./script.sh <torrentid> <torrentname> <torrentpath>
##
## To use with Deluge, simply put the script where deluge service has access to it,
##
## install the Execute plugin, and set the script to be run after the desired event:
##   Possible vents
##     1. completed <--- this
##     2. added
##     3. removed
## ====================================================================================

formats=(zip rar)
commands=([zip]="unzip -u" [rar]="unrar -o- e")

# Arguments passed to the script
torrentid=$1
torrentname=$2
torrentpath=$3

# Set whether to delete archive files after extraction
delete=false

# Init extracted bool as false (empty)
extracted=

log()
{
    logger -t deluge-extractarchives "$@"
}

log "Torrent complete: $@"

# change to the torrent directory
cd "${torrentpath}"

# loop through supported archive formats
for format in "${formats[@]}"; do
    # loop through files with the current archive format
    while read file; do
        log "Extracting \"$file\""
        # change to the directory where the archive file is located
        cd "$(dirname "$file")"
        file=$(basename "$file")
        extracted_file=$(basename ${file%.*})
        # extract the archive file
        if ${commands[$format]} "$file";
            then
                extracted=true
            else
                log "Extraction failed for file $file"
                extracted=
                continue
        fi
    done < <(find "$torrentpath/$torrentname" -iname "*.${format}" )
done

if [[ "$extracted" && "$delete" == "true" ]] ; then
    # Iterate through the directory and delete all files except the extracted file
    log "Deleting all files except for $extracted_file"
    find "$torrentpath/$torrentname" -type f ! -name "$extracted_file*" -exec sh -c '
    for file do
        log "Deleting file $file"
        rm -v "$file"
    done
    ' sh {} +
fi
