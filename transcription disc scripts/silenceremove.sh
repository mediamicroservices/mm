#!/bin/bash
# 1) identifies and extract 'in' & 'out' points to trim restored transcription disc recordings (wav) using the silencedetect audio filter
# 2) inputs the 'in' & 'out' points into a temp. xml document as wav cue information
# 3) uses bwf metaedit to import the 'in' & 'out' points through the xml into the desired wav file

# color codes for messages
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

_usage(){
    echo -e "${GREEN}\nThis script identifies the 'in' & 'out' points to trim restored transcription disc recordings and appends the timestamps into the cue chunk.\n${NC}"
}

# checks for wav header in file
check_wav_header() {
  local wav_file="$1"

  # rejects if it's not a file
  if [[ ! -f "$wav_file" ]]; then
      echo -e "${RED}[$(basename "$wav_file")]Error: Is not a file. Aborting...${NC}"
      return 1
  fi

  # reads 44 bytes of header
  header=$(xxd -l 44 -g 1 "$wav_file")
  riff_value="${header:9:12}"
  wavefmt_value="${header:33:12}"

  # if it's a file, checks for RIFF and WAV header
  if [[ "$riff_value" == " 52 49 46 46" && "$wavefmt_value" == " 57 41 56 45" ]]; then
      echo -e "${GREEN}[$(basename "$wav_file")]WAV header is valid.${NC}"
      return 0
  else
      echo -e "${RED}[$(basename "$wav_file")]Error: Invalid WAV header. Aborting...${NC}"
      return 1
  fi
}

# checks wav file's sample rate
get_sample_rate() {
    local wav_file="$1"
    local sample_rate=$(ffprobe -v error -select_streams a -of default=noprint_wrappers=1:nokey=1 -show_entries stream=sample_rate "$wav_file")
    echo "$sample_rate"
}

# identifies in & out timecode to trim transcription disc recordings using the silencedetect audio filter and samples it from seconds
get_silence_timecode() {
  local wav_file="$1"
  local sample_rate=$(get_sample_rate "$wav_file")
  # calculates silence start & end timestamps using the ffmpeg adeclick & silencedetect audio filter
  # ffmpeg script by sarah wardrop
  echo -e "${GREEN}[$(basename "$wav_file")]Identifying 'in' & 'out' points...${NC}"
  silence_info=$(ffmpeg -hide_banner -i "$wav_file" -ac 1 -filter_complex "\
      adeclick=window=55:overlap=75[DC1]; \
      [DC1]acrossover=split=1500 8000:order=20th[LOW][MID][HIGH]; \
      [LOW]adeclick=window=55:overlap=75[LOW1]; \
      [MID]adeclick=window=55:overlap=75:t=1[MID1]; \
      [HIGH]adeclick=window=55:overlap=75[HIGH1]; \
      [LOW1][MID1][HIGH1]amix=inputs=3[DCMIX]; \
      [DCMIX]highpass=f=60:t=s,lowpass=f=10000:t=s[silence]; \
      [silence]silencedetect=n=-25dB:d=5" -f null - 2>&1 | tee /dev/tty)

  # echoes ffmpeg output and greps the first occurence of silence_end to get the 'in' point (seconds)
  in_point=$(echo "$silence_info" | grep -oE 'silence_end: [0-9.]+' | grep -oE '[0-9.]+' | head -n 1)

  # echoes ffmpeg output and greps the last occurence of silence_end to get the 'out' point (seconds)
  out_point=$(echo "$silence_info" | grep -oE 'silence_end: [0-9.]+' | grep -oE '[0-9.]+' | tail -n 1)

  # check if in_point and out_point are empty
  if [[ -z "$in_point" || -z "$out_point" ]]; then
    echo -e "${RED}Error: No valid 'in' and 'out' points found. Aborting...${NC}"
    echo -e "${RED}Debug: in_point=$in_point, out_point=$out_point${NC}"
    exit 1
  fi

  # check if there is output to grep
  if ! echo "$silence_info" | grep -oE 'silence_end: [0-9.]+' | grep -oE '[0-9.]+' | head -n 1 > /dev/null; then
    echo -e "${RED}Error: No silence information found. Aborting...${NC}"
    exit 1
  fi

  # converts the 'in' point from seconds to samples
  in_point_sampled=$(echo "$in_point * $sample_rate" | bc | awk '{printf "%.0f\n", $1}')

  # converts the 'out' point from seconds to samples
  out_point_sampled=$(echo "$out_point * $sample_rate" | bc | awk '{printf "%.0f\n", $1}')

  echo -e "${GREEN}[$(basename "$wav_file") - IN] $in_point seconds (sample value: $in_point_sampled)${NC}"
  echo -e "${GREEN}[$(basename "$wav_file") - OUT] $out_point seconds (sample value: $out_point_sampled)${NC}"
}

# creates temporary XML file with cue information
generate_xml() {
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
    local xml_file="$(dirname "$wav_file")/$(basename "$wav_file").cue.xml"

   	if [[ -s "$xml_file" ]]; then
  		 # bwf metaedit command to initiate xml file import
      	xml_import=$(bwfmetaedit --in-cue-xml "$wav_file")
      	echo -e "${GREEN}[$(basename "$wav_file")]XML imported successfully.${NC}"
  	else
  		echo -e "${RED}[$(basename "$wav_file")]Error: XML file not present or empty. Aborting...${NC}"
  		exit 1
    fi
}

# removes temp. xml file
remove_xml() {
    local xml_file="$(dirname "$input_file")/$(basename "$input_file").cue.xml"

    if [[ -f "$xml_file" ]]; then
        rm -f "$xml_file"
        echo -e "${GREEN}[$(basename "$wav_file")]Removed temporary XML file: $(basename "$xml_file").${NC}"
    else
        echo -e "${RED}Error: Temporary XML file not found: $(basename "$xml_file").${NC}"
    fi
}

# checks if bwf metaedit & ffmpeg & ffprobe is installed
if ! command -v bwfmetaedit &> /dev/null || ! command -v ffmpeg &> /dev/null || ! command -v ffprobe &> /dev/null ; then
    echo -e "${RED}Error: bwfmetaedit/ffmpeg/ffprobe is not installed. Aborting...${NC}"
    exit 1
fi

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
        # gets wav file sample rate
        SAMPLERATE=$(get_sample_rate "$input_file")
        # gets 'in' and 'out' points
        get_silence_timecode "$input_file"
        
        # declare sampled 'in' and 'out' point
        INPOINT="$in_point_sampled"
        OUTPOINT="$out_point_sampled"
        
        # creates temporary xml file that accompanies input file
        xml_file="$(dirname "$input_file")/$(basename "$input_file").cue.xml"
        generate_xml "$INPOINT" "$OUTPOINT" "$SAMPLERATE" > "$xml_file"

        # imports cue information (temp. xml) into the wav file using bwf metaedit
        create_cue "$input_file"

        # removes temp. xml file after succesful import
        remove_xml "$xml_file"

        echo -e "${GREEN}[$(basename "$input_file")]Success! 'in' & 'out' points added in cue chunk.${NC}"
    fi
done

# dave's ffprobe command
# ffprobe -f lavfi -i amovie=/Users/MatthewYang/Desktop/SDA257/HBG00733_01_transcriptiondisc.wav,silencedetect=n=-10dB:d=0.1  -show_entries frame_tags=lavfi.silence_start,lavfi.silence_duration -of compact=nk=0  | grep -v "|$"