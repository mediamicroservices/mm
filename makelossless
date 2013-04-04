#!/bin/sh

filename=`basename "$file"`
dirname=`dirname "$file"`

while [ "$*" != "" ] ; do
	file="$1"
	is2yuv=`ffmpeg 2>/dev/null -i "$file" 2>&1 | grep 2vuy | wc -l | sed 's/ //g'`
	echo is "$is2yuv"
	if [[ "$is2yuv" -eq 0 ]] ; then
		echo "$filename is not 2vuy, quitting"
		exit 1
	else
		echo "$filename is 2vuy, starting encode"
		export FFREPORT="file=${dirname}/%p_%t_convert-to-ffv1.log"
		ffmpeg -report -vsync 0 -i "$file" -map 0:v -map 0:a -c:v ffv1 -g 1 -c:a copy "${file%.*}_ffv1.mov" -f framemd5 -an "${file%.*}.framemd5"
		ffmpeg_ffv1_err="$?"
		[ "$ffmpeg_ffv1_err" -gt 0 ] && echo ffmpeg ended with error && exit 1
		ffmpeg -i "${file%.*}_ffv1.mov"  -f framemd5 -pix_fmt uyvy422 -an "${file%.*}_ffv1.framemd5"
		ffmpeg_md5_err="$?"
		[ "$ffmpeg_md5_err" -gt 0 ] && echo ffmpeg md5 ended with error && exit 1
		muxmovie "$file" -track "Timecode Track" -track "Closed Caption Track" -self-contained -o "${file%.*}_tc_e608.mov"
		muxmovie_err="$?"
		[ "$muxmovie_err" -gt 0 ] && echo muxmovie ended with error && exit 1
		if [ `md5 -q "${file%.*}.framemd5"` = `md5 -q "${file%.*}_ffv1.framemd5"` ] ; then
			echo Everything looks safe. Going to delete the original.
			mediainfo -f --language=raw --output=XML "$file" > "${file%.*}_mediainfo.xml"
			rm -f -v "$file"
		else
			echo Not looking safe. Going to keep the original.
		fi
		echo done with "$file"
	fi
	shift
done
