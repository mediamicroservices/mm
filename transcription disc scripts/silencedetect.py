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
                print_green(f"[{os.path.basename(wav_file)}]: WAV header is valid.")
                return True
            else:
                print_red(f"Error: [{os.path.basename(wav_file)}] has an invalid WAV header. Aborting...")
                sys.exit(1)

    except wave.Error as e:
        print_red(f"Error: [{os.path.basename(wav_file)}] is not a valid WAV file. Aborting...")
        print_red("=============END=============")
        sys.exit(1)

def get_wav_info(wav_file):
    try:
        with wave.open(wav_file, 'rb') as wav_obj:
            sample_rate = wav_obj.getframerate()
            duration = wav_obj.getnframes() / float(sample_rate)
            return sample_rate, duration

    except Exception as e:
        print(f"Error getting information for {wav_file}: {str(e)}")
        return None, None

def process_audio_file(file_path, sil_time=0.020, generate_xml_file=True):
    try:
        # extract the filename using os.path.basename()
        filename = os.path.basename(file_path)

        # get the sample rate using the get_sample_rate function
        sample_rate, duration = get_wav_info(file_path)

        if sample_rate is None:
            # prints error if sample rate cannot be determined
            print_red(f"Error processing {filename}: Sample rate could not be determined.")
            return

        # reads audio file and get active segments
        [Fs, x] = aIO.read_audio_file(file_path)
        segments = aS.silence_removal(x,
                                     Fs,
                                     0.020,
                                     0.020,
                                     smooth_window=1.0,
                                     weight=0.3,
                                     plot=False)  # set plot to false to prevent double plotting

        # update segments with additional silence information
        updated_segments = update_segments(file_path, segments, sil_time)

        # output the breakdown of silence portions
        print(f"Silence breakdown for {filename}:")
        for idx, segment in enumerate(updated_segments, start=1):
            print(f"Silence Portion {idx}: Start: {segment[0]}, End: {segment[1]}")

        # extract information about the end of the first silence portion (in point)
        if len(updated_segments) > 0:
            end_of_first_silence = updated_segments[0][1]
            end_of_first_silence_timecode = get_timecode(end_of_first_silence)
            end_of_first_silence_sample = int(end_of_first_silence * sample_rate)
            print_green(f"[IN] {end_of_first_silence_timecode} ({end_of_first_silence_sample})")

        # extract information about the start of the last silence portion (out point)
        if len(updated_segments) > 1:
            start_of_last_silence = updated_segments[-1][0]
            start_of_last_silence_timecode = get_timecode(start_of_last_silence)
            start_of_last_silence_sample = int(start_of_last_silence * sample_rate)
            print_green(f"[OUT] {start_of_last_silence_timecode} ({start_of_last_silence_sample})")

        # get original duration
            duration_timecode = get_timecode(duration)
            duration_timecode_sample = int(duration * sample_rate)

        # get trimmed duration
        trim_duration = (end_of_first_silence - start_of_last_silence)
        trim_duration_sample = int(trim_duration * sample_rate)

        # take the absolute value to make sure it's non-negative
        trim_duration = abs(trim_duration)
        trim_duration_sample = abs(trim_duration_sample)
        print_green(f"[ORIGINAL DURATION] {duration_timecode} ({duration_timecode_sample})")
        print_green(f"[TRIMMED DURATION] {get_timecode(trim_duration)} ({trim_duration_sample})")

        # write silence portions to a text file
        write_silence_to_txt(filename, updated_segments)

        # generate and write XML file
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
        xml_filename = f"{filename}.cue.xml"
        with open(xml_filename, 'w') as xml_file:
            xml_file.write(xml_content)
        print_green(f"[{filename}] XML file generated and saved as {xml_filename}")

        # import cue information into the wav file
        xml_file = f"{filename}.cue.xml"
        import_xml(file_path, xml_file)

        # export new cue information from the wav file
        export_new_xml(file_path, xml_file, filename) 

        # set figure size to make the graph bigger on the x-axis
        plt.figure(figsize=(30, 10))

        # plot the audio file with the updated segments
        plt.plot(x)
        plt.title(f"Audio File with Silence Removal ({filename})")

        # mark the silent segments on the plot
        for segment in updated_segments:
            plt.axvspan(segment[0] * Fs, segment[1] * Fs, color='red', alpha=0.3)

        plt.xlabel("Time (s)")
        plt.ylabel("Amplitude")
        output_file = f"{filename}_plot_with_silence.png"
        plt.savefig(output_file)
        plt.close()
        print_green(f"[{filename}] Plot saved as {output_file}")

    except Exception as e:
        print_red(f"Error processing {filename}: {str(e)}")

# converts 'in' and 'out' points into timecode (hh:mm:ss) format
def get_timecode(input_seconds):
    hours = int(input_seconds // 3600)
    minutes = int((input_seconds % 3600) // 60)
    seconds = input_seconds % 60

    # format the result
    return f"{hours:02d}:{minutes:02d}:{seconds:05.2f}"

# figure out what this segment means
def update_segments(filename, segments, sil_time):
    ans = []
    tmp = 0
    n = len(segments)
    for idx, t in enumerate(segments):
        if t[0] - tmp >= sil_time:
            ans.append((tmp, t[0]))
        tmp = t[1]
        if idx == n-1:
            fn = librosa.get_duration(path=filename)  # use 'path' instead of 'filename'
            if fn - tmp >= sil_time:
                ans.append((tmp, fn))
    return ans

# text output of the silence portions with start and end points in seconds
def write_silence_to_txt(filename, silence_portions):
    output_file = f"{filename}_silence_portions.txt"
    with open(output_file, 'w') as file:
        file.write(f"Silence breakdown for {filename}:\n")
        for idx, portion in enumerate(silence_portions, start=1):
            file.write(f"Silence Portion {idx}: Start: {portion[0]}, End: {portion[1]}\n")
    print_green(f"[{filename}] Silence portions saved to {output_file}")

# import xml
def import_xml(wav_file, xml_file):
    if os.path.isfile(xml_file) and os.path.getsize(xml_file) > 0:
        # bwf metaedit command to initiate xml file import
        xml_import = subprocess.run(['bwfmetaedit', '--in-cue-xml', wav_file], capture_output=True, text=True)

        if xml_import.returncode == 0:
            print(f"{GREEN}[{os.path.basename(wav_file)}] bwfmetaedit import successful")
        else:
            print(f"{RED}[{os.path.basename(wav_file)}] Error: bwfmetaedit command failed. Aborting...")
            exit(1)
    else:
        print(f"{RED}[{os.path.basename(wav_file)}] Error: XML file not present or empty. Aborting...")
        exit(1)

# exports xml file that contains updated chunk information
def export_new_xml(wav_file, xml_file, filename):
    try:
        # execute the bwfmetaedit command and redirect the output to the specified XML file
        command = ['bwfmetaedit', '--out-xml', wav_file]
        result = subprocess.run(command, capture_output=True, text=True, check=True)


        # save the output to the filename_xml.txt file
        output_text_file = f"{filename}_xml.txt"
        with open(output_text_file, 'w') as text_file:
            text_file.write(result.stdout)

        print_green(f"[{filename}] Updated cue info XML generated and saved as {os.path.basename(xml_file)}")
    
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
        filename = os.path.basename(file_path)
        print_green(f"============{filename}============")
        check_wav_header(file_path)
        process_audio_file(file_path)
        print_green("=============END=============")
