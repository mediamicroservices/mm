#!/bin/bash
# microservice to move older transcription disc restorations into the restoration_old directory after a newer restoration is made using the mm/makederiv microservice

# color codes for messages
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

_usage(){
    echo -e ${GREEN}"\nThis script moves older transcription disc restorations into the restoration_old directory after a newer restoration is made using the mm/makederiv microservice.\n"${NC}
}

_usage

# asks for a directory and checks it

echo "Enter the directory path to begin:"
read -r -p "> " user_directory

if [[ ! -d "$user_directory" || -z "$(ls -A "$user_directory")" ]]; then
    echo -e ${RED}"Directory not found or empty: $user_directory"${NC}
    exit 1
fi

echo -e ${GREEN}"Selected directory: $user_directory"${NC}

# is there a restoration directory? if no, exit
restoration_directory="$user_directory/objects/restoration"

if [ ! -d "$restoration_directory" ]; then
    echo -e ${RED}"There is no 'restoration' directory in the objects directory. Aborting..."${NC}
    exit 1
fi

# does it have wav files? if no, exit
wav_files=$(find "$restoration_directory" -maxdepth 1 -type f -name "*.wav")

if [ -z "$wav_files" ]; then
    echo -e ${RED}"No WAV files found in the restoration directory. Aborting..."${NC}
    exit 1
fi

# create restoration_old directory
restoration_old_dir="$user_directory/objects/restoration/restoration_old"

# append to readme.txt log file
readme_file="$user_directory/metadata/oldrestoration_readme.txt"
user=$(whoami)
echo "Old transcription disc restoration file move log" > "$readme_file"
echo "Initiated by: $user" >> "$readme_file"
echo "==============================" >> "$readme_file"

# identify old & new wav file
for wav_file in $wav_files; do
    filename=$(basename "$wav_file")
    current_datetime=$(date +"%m-%d-%Y %H:%M:%S")

    # identifies the old restorations by checking filenames that are NOT _transcriptiondisc[0-9]*\.wav, _transcriptiondisc_
    if [[ ! "$filename" =~ _transcriptiondisc[0-9]*\.wav ]] && [[ "$filename" != *"_transcriptiondisc_"* ]]; then
        mkdir -p "$restoration_old_dir"
        mv "$wav_file" "$restoration_old_dir/"
  
      echo -e ${GREEN}"Moved $filename to $restoration_old_dir"${NC}
        echo "Transfer details:" >> "$readme_file"
        echo "   File: $filename" >> "$readme_file"
        echo "   Transfer Date & Time: $current_datetime" >> "$readme_file"
        echo "   From: $user_directory" >> "$readme_file"
        echo "   To:   $restoration_old_dir" >> "$readme_file"
        echo "------------------------------" >> "$readme_file"
    fi
done

echo -e ${GREEN}"Old restorations successfully moved to the restoration_old directory. See oldrestoration_readme.txt in the metadata directory for the transfer log."${NC}