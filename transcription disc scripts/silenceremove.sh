#!/bin/bash
# microservice to trim restored transcription disc recordings

# color codes for messages
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

_usage(){
    echo -e "${GREEN}\nThis script trims restored transcription disc recordings.\n${NC}"
}

# check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${RED}Error: FFmpeg is not installed. Aborting...${NC}"
    exit 1
fi

# checks for wav header in file
check_wav_header() {
    local wav_file="$1"

    # rejects if it's not a file
    if [[ ! -f "$wav_file" ]]; then
        echo -e "${RED}[$(basename "$wav_file")] Is not a file. Aborting...${NC}"
        return 1
    fi

    # reads 44 bytes of header
    header=$(xxd -l 44 -g 1 "$wav_file")
    riff_value="${header:9:12}"
    wavefmt_value="${header:33:12}"

    # if it's a file, checks for RIFF and WAV header
    if [[ "$riff_value" == " 52 49 46 46" && "$wavefmt_value" == " 57 41 56 45" ]]; then
        echo -e "${GREEN}[$(basename "$wav_file")] WAV header is valid.${NC}"
        return 0
    else
        echo -e "${RED}[$(basename "$wav_file")] Error: Invalid WAV header. Aborting...${NC}"
        return 1
    fi
}

# ffmpeg command to remove silence
remove_silence() {
    local wav_file="$1"
    local output_file="${wav_file}_trimmed.wav"

    echo -e "${GREEN}[$(basename "$wav_file")] Removing silence and trimming...${NC}"
    ffmpeg -i "$wav_file" \
       -af "silenceremove=start_periods=1:start_silence=5:start_threshold=-30dB:detection=peak, \
       areverse, silenceremove=start_periods=1:start_silence=5:start_threshold=-30dB:detection=peak, \
       areverse" "$output_file"
}

# provide script usage instruction if no input provided
if [[ $# -eq 0 ]]; then
    script_name=$(basename "$0")
    _usage
    echo -e "Usage: $script_name <file1> <file2> <file3> ... \n"
    exit 1
fi

# performs check_wav_header and executes remove_silence
for input_file in "$@"; do
    if check_wav_header "$input_file"; then
        remove_silence "$input_file"
    fi
done