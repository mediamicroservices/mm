#!/bin/bash
# microservice to move older transcription disc restorations into the restoration_old directory after a newer restoration is made using the mm/makederiv microservice

# color codes for messages
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

_usage(){
    echo -e "${GREEN}\nThis script moves older transcription disc restorations into the restoration_old directory after a newer restoration is made using the mm/makederiv microservice.\n${NC}"
}

# provide script usage instruction if no input provided
if [[ $# -eq 0 ]]; then
    script_name=$(basename "$0")
    _usage
    echo -e "Usage: $script_name <directory_path1> <directory_path2> <directory_path3> ... \n"
    exit 1
fi

# loop through input directories
for user_directory in $@; do
    directory_name=$(basename "$user_directory")

# checks whether input is a directory and whether it is empty
    if [[ ! -d "$user_directory" || -z "$(ls -A "$user_directory")" ]]; then
        echo -e "${RED}[$directory_name] Directory not found or empty. Aborting...${NC}"
        continue
    fi

    # is there a restoration directory? if no, exit
    restoration_directory="$user_directory/objects/restoration"

    if [ ! -d "$restoration_directory" ]; then
        echo -e "${RED}[$directory_name] There is no 'restoration' directory in the objects directory. Aborting...${NC}"
        continue
    fi

    # does it have wav files? if no, exit
    wav_files=$(find "$restoration_directory" -maxdepth 1 -type f -name "*.wav")

    if [ -z "$wav_files" ]; then
        echo -e "${RED}[$directory_name] No WAV files found in the restoration directory. Aborting...${NC}"
        continue
    fi

    # does it already have an existing restoration_old directory or oldrestoration_readme.txt?
    restorationold_directory="$user_directory/objects/restoration/restoration_old"
    readme_text="$user_directory/metadata/oldrestoration_readme.txt"

    if [ -d "$restorationold_directory" ] || [ -f "$readme_text" ] ; then
        echo -e "${RED}[$directory_name] There is an existing restoration_old directory or old_restoration_readme.txt file. Aborting...${NC}"
        continue
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
            mv -n "$wav_file" "$restoration_old_dir/"
            echo -e "${GREEN}Moved $filename to $restoration_old_dir${NC}"
            echo "Transfer details:" >> "$readme_file"
            echo "   File: $filename" >> "$readme_file"
            echo "   Transfer Date & Time: $current_datetime" >> "$readme_file"
            echo "   From: $user_directory" >> "$readme_file"
            echo "   To:   $restoration_old_dir" >> "$readme_file"
            echo "------------------------------" >> "$readme_file"
        fi
    done
echo -e "${GREEN}[$directory_name] Old restorations successfully moved to the restoration_old directory. See oldrestoration_readme.txt in the metadata directory for the transfer log.${NC}"
done       