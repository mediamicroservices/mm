#!/bin/bash
# microservice to extract in & out points of trimmed restored transcription disc recordings, after applying the silencedetect audio filter

# color codes for messages
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

_usage(){
    echo -e "${GREEN}\nThis script identifies the In & Out timestamp of restored transcription disc recordings and appends the timestamps into the cue chunk.\n${NC}"
}

# checks if bwf metaedit & ffmpeg is installed
if ! command -v ffmpeg &> /dev/null || ! command -v bwfmetaedit &> /dev/null ; then
    echo -e "${RED}Error: FFmpeg and/or bwfmetaedit is not installed. Aborting...${NC}"
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

# checks wav file's sample rate
get_sample_rate() {
    local wav_file="$1"
    local sample_rate=$(ffprobe -v error -select_streams a -of default=noprint_wrappers=1:nokey=1 -show_entries stream=sample_rate "$wav_file")
    echo "$sample_rate"
}

# get in & out timecode to trim transcription disc recordings using the silencedetect audio filter
get_silence_timecode() {
  local wav_file="$1"
  local sample_rate=$(get_sample_rate "$wav_file")

  # calculates silence start & end timestamps using the ffmpeg silencedetect audio filter
  silence_info=$(ffmpeg -i "$wav_file" -af silencedetect=n=-25dB:d=5 -f null - 2>&1)
  # echoes ffmpeg output and greps the first occurence of silence_end to get 'in' point (seconds)
  in_point=$(echo "$silence_info" | grep -oE 'silence_end: [0-9.]+' | grep -oE '[0-9.]+' | head -n 1)
  # converts 'in' point from seconds to samples
  in_point_sampled=$(echo "$in_point * $sample_rate" | bc | awk '{printf "%.0f\n", $1}')
  # echoes ffmpeg output and greps the last occurence of silence_end to get 'out' point (seconds)
  out_point=$(echo "$silence_info" | grep -oE 'silence_end: [0-9.]+' | grep -oE '[0-9.]+' | tail -n 1)
  # converts 'out' point from seconds to samples
  out_point_sampled=$(echo "$out_point * $sample_rate" | bc | awk '{printf "%.0f\n", $1}')

  echo -e "${GREEN}[$(basename "$wav_file")] Identifying 'in' & 'out' points...${NC}"
  echo -e "${GREEN}[$(basename "$wav_file") - IN] $in_point seconds (sample value: $in_point_sampled)${NC}"
  echo -e "${GREEN}[$(basename "$wav_file") - OUT] $out_point seconds (sample value: $out_point_sampled)${NC}"
}

# creates temporary XML file
generate_xml(){
	local INPOINT=$1
	local OUTPOINT=$2
	local SAMPLERATE=$3

	cat <<EOF
<Cues samplerate="$SAMPLERATE">
    <Cue>
        <ID>1</ID>
        <Position>$INPOINT</Position>
        <DataChunkID>0x64617461</DataChunkID>
        <ChunkStart>0</ChunkStart>
        <BlockStart>0</BlockStart>
        <SampleOffset>130242</SampleOffset>
        <Label>Presentation</Label>
        <Note></Note>
        <LabeledText>
            <SampleLength>$(($OUTPOINT - $INPOINT))</SampleLength>
            <PurposeID>0x72676E20</PurposeID>
            <Country>0</Country>
            <Language>0</Language>
            <Dialect>0</Dialect>
            <CodePage>0</CodePage>
            <Text></Text>
        </LabeledText>
    </Cue>
</Cues>
EOF
}

# import xml using bwf metaedit
create_cue() {
    local wav_file="$1"
    # bwf metaedit command to initiate xml file import
    xml_import=$(bwfmetaedit --in-cue-xml "$wav_file")
}

# provide script usage instruction if no input provided
if [[ $# -eq 0 ]]; then
    script_name=$(basename "$0")
    _usage
    echo -e "Usage: $script_name <file1> <file2> <file3> ... \n"
    exit 1
fi

# performs check_wav_header, creates xml file, import cue with bwf metaedit
for input_file in "$@"; do
    if check_wav_header "$input_file"; then
        # gets sample rate
        SAMPLERATE=$(get_sample_rate "$input_file")
        # gets in and out points in seconds
        get_silence_timecode "$input_file"
        
        # gets sampled inpoint and outpoint
        INPOINT="$in_point_sampled"
        OUTPOINT="$out_point_sampled"
        
        # creates temporary xml file that accompanies input file
        xml_file="$(dirname "$input_file")/$(basename "$input_file").cue.xml"
        generate_xml "$INPOINT" "$OUTPOINT" "$SAMPLERATE" > "$xml_file"

        # imports xml into wav file using bwf metaedit
        create_cue "$input_file"

        echo -e "${GREEN}[$(basename "$input_file")] Success!${NC}"
    fi
done

# dave's ffprobe command
# ffprobe -f lavfi -i amovie=/Users/MatthewYang/Desktop/SDA257/HBG00733_01_transcriptiondisc.wav,silencedetect=n=-10dB:d=0.1  -show_entries frame_tags=lavfi.silence_start,lavfi.silence_duration -of compact=nk=0  | grep -v "|$"