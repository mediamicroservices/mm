# required tools - bwfmetaedit

# required libraries
from pyAudioAnalysis import audioBasicIO as aIO
from pyAudioAnalysis import audioSegmentation as aS
import matplotlib.pyplot as plt 
import argparse
import os
import sys
import librosa
import logging
import wave 
import subprocess
import shutil

# escape codes for text color
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
RESET = '\033[0m'

# status messages
def print_green(message):
    print(GREEN + message + RESET)

def print_red(message):
    print(RED + message + RESET)

def print_yellow(message):
    print(YELLOW + message + RESET)

# checks validity of wav file
def check_wav_header(wav_file):
    # check if it's a file
    if not os.path.isfile(wav_file):
        print(f"Error: [{os.path.basename(wav_file)}] is not a file. Aborting...")
        sys.exit(1)

    try:
        # check if it's a wav file
        with wave.open(wav_file, 'rb') as wav_obj:
            # get the format information
            wave_format = wav_obj.getparams()

            # checks format
            if wave_format.nchannels > 0 and wave_format.sampwidth > 0 and wave_format.framerate > 0:
                print_green(f"[{os.path.basename(wav_file)}] Valid WAV file.")
                return True
            else:
                print_red(f"Error: [{os.path.basename(wav_file)}] has an invalid WAV header. Aborting...")
                sys.exit(1)

    except wave.Error as e:
        print_red(f"Error: [{os.path.basename(wav_file)}] is not a valid WAV file. Aborting...")
        print_red("=============END=============")
        sys.exit(1)

# retrieves info of wav file
def get_wav_info(wav_file):
    try:
        with wave.open(wav_file, 'rb') as wav_obj:
            sample_rate = wav_obj.getframerate()
            duration = wav_obj.getnframes() / float(sample_rate)
            return sample_rate, duration

    except Exception as e:
        print(f"Error getting information for {wav_file}: {str(e)}")
        return None, None

# converts 'in' and 'out' points into timecode (hh:mm:ss) format
def get_timecode(input_seconds):
    hours = int(input_seconds // 3600)
    minutes = int((input_seconds % 3600) // 60)
    seconds = input_seconds % 60

    # format the result
    return f"{hours:02d}:{minutes:02d}:{seconds:05.2f}"

# converts the non-silent parts to silent parts
def update_segments(filename, segments, sil_time):
    ans = []
    tmp = 0
    n = len(segments)
    for idx, t in enumerate(segments):
        if t[0] - tmp >= sil_time:
            ans.append((tmp, t[0]))
        tmp = t[1]
        if idx == n-1:
            fn = librosa.get_duration(path=filename)
            if fn - tmp >= sil_time:
                ans.append((tmp, fn))
    return ans

# text output of the silence portions with start and end points in seconds
def write_silence_to_txt(filename, silence_portions, silencedetect_dir):
    output_file = os.path.join(silencedetect_dir, f"{filename}_silence_portions.txt")
    with open(output_file, 'w') as file:
        file.write(f"Silence breakdown for {filename}:\n")
        for idx, portion in enumerate(silence_portions, start=1):
            file.write(f"Silence Portion {idx}: Start: {portion[0]}, End: {portion[1]}\n")
    print_green(f"[{filename}] Silence portions saved to {output_file}")

# saves xml file with cue chunk information
def save_xml_file(filename, xml_content):
    xml_filename = f"{filename}.cue.xml"
    with open(xml_filename, 'w') as xml_file:
        xml_file.write(xml_content)
    print_green(f"[{filename}] XML file generated and saved as {xml_filename}")

# generates xml file with cue chunk information
def generate_xml_file_function(filename, generate_xml_file, sample_rate, end_of_first_silence_sample, start_of_last_silence_sample):
    if generate_xml_file:
        in_point = end_of_first_silence_sample
        out_point = start_of_last_silence_sample
        xml_content = f"""<Cues samplerate="{sample_rate}">
    <Cue>
        <ID>1</ID>
        <Position>{in_point}</Position>
        <DataChunkID>0x64617461</DataChunkID>
        <ChunkStart>0</ChunkStart>
        <BlockStart>0</BlockStart>
        <SampleOffset>130242</SampleOffset>
        <Label>Presentation</Label>
        <Note></Note>
        <LabeledText>
            <SampleLength>{out_point - in_point}</SampleLength>
            <PurposeID>0x72676E20</PurposeID>
            <Country>0</Country>
            <Language>0</Language>
            <Dialect>0</Dialect>
            <CodePage>0</CodePage>
            <Text></Text>
        </LabeledText>
    </Cue>
</Cues>
"""
        save_xml_file(filename, xml_content)

# detects silence and non silence
# finds 'in' & 'out' points in seconds, hh:mm:ss, and sampled time
# plots graph with non-silent and silent parts
def process_audio_file(file_path, sil_time=0.020, generate_xml_file=True):
    try:
        filename = os.path.basename(file_path)
        sample_rate, duration = get_wav_info(file_path)

        if sample_rate is None:
            print_red(f"Error processing {filename}: Sample rate could not be determined.")
            return

        Fs, x = aIO.read_audio_file(file_path)
        segments = aS.silence_removal(x,
                                      Fs,
                                      sil_time,
                                      sil_time,
                                      smooth_window=1.0,
                                      weight=0.3,
                                      plot=False)

        updated_segments = update_segments(file_path, segments, sil_time)

        print(f"Silence breakdown for {filename}:")
        for idx, segment in enumerate(updated_segments, start=1):
            print(f"Silence Portion {idx}: Start: {segment[0]}, End: {segment[1]}")

        if len(updated_segments) > 0:
            end_of_first_silence = updated_segments[0][1]
            end_of_first_silence_timecode = get_timecode(end_of_first_silence)
            end_of_first_silence_sample = int(end_of_first_silence * sample_rate)
            print_green(f"[IN] {end_of_first_silence_timecode} ({end_of_first_silence_sample})")

        if len(updated_segments) > 1:
            start_of_last_silence = updated_segments[-1][0]
            start_of_last_silence_timecode = get_timecode(start_of_last_silence)
            start_of_last_silence_sample = int(start_of_last_silence * sample_rate)
            print_green(f"[OUT] {start_of_last_silence_timecode} ({start_of_last_silence_sample})")

        duration_timecode = get_timecode(duration)
        duration_timecode_sample = int(duration * sample_rate)

        trim_duration = (end_of_first_silence - start_of_last_silence)
        trim_duration_sample = int(trim_duration * sample_rate)
        trim_duration = abs(trim_duration)
        trim_duration_sample = abs(trim_duration_sample)

        print_green(f"[ORIGINAL DURATION] {duration_timecode} ({duration_timecode_sample})")
        print_green(f"[TRIMMED DURATION] {get_timecode(trim_duration)} ({trim_duration_sample})")
        
        # create /metadata/silencedetect directory
        # root_parent_directory = os.path.dirname(os.path.dirname(os.path.dirname(file_path)))
        # silencedetect_dir = os.path.join(root_parent_directory, "metadata", "silencedetect")
        # if not os.path.exists(silencedetect_dir):
        #     os.makedirs(silencedetect_dir)

        # conditions to determine where to save the /metadata/silencedetect directory with sidecar files
        if "/objects/restoration" in file_path:
            levels_up = 3
        elif "/objects" in file_path:
            levels_up = 2
        else:
            levels_up = 1

        root_parent_directory = file_path
        for _ in range(levels_up):
            root_parent_directory = os.path.dirname(root_parent_directory)

        silencedetect_dir = os.path.join(root_parent_directory, "metadata", "silencedetect", filename)
        if not os.path.exists(silencedetect_dir):
            os.makedirs(silencedetect_dir)

        write_silence_to_txt(filename, updated_segments, silencedetect_dir)

        generate_xml_file_function(filename, generate_xml_file, sample_rate, end_of_first_silence_sample, start_of_last_silence_sample)

        xml_file = f"{filename}.cue.xml"
        import_xml(file_path, xml_file)
        export_new_xml(file_path, xml_file, filename, silencedetect_dir)

        # output new duration information into silencedetect directory
        output_file_path = os.path.join(silencedetect_dir, f"{filename}_new_duration.txt")
        with open(output_file_path, 'w') as f:
            f.write(f" {filename}\n")
            f.write(f"[ORIGINAL DURATION]{duration_timecode} ({duration_timecode_sample})\n")
            f.write(f"[TRIMMED DURATION]{get_timecode(trim_duration)} ({trim_duration_sample})\n")
            f.write(f"[IN]{end_of_first_silence_timecode} ({end_of_first_silence_sample})\n")
            f.write(f"[OUT]{start_of_last_silence_timecode} ({start_of_last_silence_sample})\n")

        # output chapter information into silencedetect directory
        output_file_path = os.path.join(silencedetect_dir, f"{filename}_chapterinfo.txt")
        with open(output_file_path, 'w') as f:
            f.write(f"CHAPTER01={end_of_first_silence_timecode} START\n")
            f.write(f"CHAPTER01NAME=START\n")
            f.write(f"CHAPTER02={start_of_last_silence_timecode} END\n")
            f.write(f"CHAPTER02NAME=END\n")

        plt.figure(figsize=(30, 10))
        plt.plot(x)
        plt.title(f"Audio File with Silence Removal ({filename})")

        for segment in updated_segments:
            plt.axvspan(segment[0] * Fs, segment[1] * Fs, color='red', alpha=0.3)

        plt.xlabel("Time (s)")
        plt.ylabel("Amplitude")
        output_file = f"{filename}_plot_with_silence.png"
        plt.savefig(output_file)
        plt.close()
        shutil.move(output_file, os.path.join(silencedetect_dir, output_file))
        print_green(f"[{filename}] Graph saved as {output_file} in {silencedetect_dir}.")

        shutil.move(xml_file, os.path.join(silencedetect_dir, os.path.basename(xml_file)))

    except Exception as e:
        print_red(f"Error processing {filename}: {str(e)}")

# import xml
def import_xml(wav_file, xml_file):
    if os.path.isfile(xml_file) and os.path.getsize(xml_file) > 0:
        # bwf metaedit command to initiate xml file import
        xml_import = subprocess.run(['bwfmetaedit', '--in-cue-xml', wav_file], capture_output=True, text=True)

        if xml_import.returncode == 0:
            print(f"{GREEN}[{os.path.basename(wav_file)}] BWFmetaedit import successful")
        else:
            print(f"{RED}[{os.path.basename(wav_file)}] Error: BWFmetaedit command failed. Aborting...")
            exit(1)
    else:
        print(f"{RED}[{os.path.basename(wav_file)}] Error: XML file not present or empty. Aborting...")
        exit(1)

# exports xml file that contains updated chunk information
def export_new_xml(wav_file, xml_file, filename, silencedetect_dir):
    try:
        # execute the bwfmetaedit command and redirect the output to the specified XML file
        command = ['bwfmetaedit', '--out-xml', wav_file]
        result = subprocess.run(command, capture_output=True, text=True, check=True)

        # save the output to the filename_xml.txt file
        output_text_file = os.path.join(silencedetect_dir, f"{filename}_xml.txt")
        with open(output_text_file, 'w') as text_file:
            text_file.write(result.stdout)

        print_green(f"[{filename}] Exported XML with chunk information. Saved as {os.path.basename(xml_file)}.")
    
    except subprocess.CalledProcessError as e:
        print_red(f"[{filename}] Error executing bwfmetaedit: {e}")
        print(result.stderr)  # print the error output from the command
    
    except Exception as e:
        print_red(f"[{filename}] Error: {e}")

# main program
if __name__ == "__main__":
    # check if file paths are provided as command-line arguments
    if len(sys.argv) < 2:
        print_yellow("Usage: python3 script.py [file1.wav] [file2.wav] [file3.wav] ...")
        sys.exit(1)

    # iterate through provided file paths and process each audio file
    for file_path in sys.argv[1:]:
        # change directory to the directory of the file
        file_directory = os.path.dirname(file_path)
        os.chdir(file_directory)
        filename = os.path.basename(file_path)
        
        print_green(f"============{filename}============")
        check_wav_header(file_path)
        process_audio_file(file_path)
        print_green("=============END=============")