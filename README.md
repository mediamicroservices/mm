mediamicroservices documentation (under construction!)
==================

table of contents
-------------------

1. [summary](https://github.com/mediamicroservices/mm#summary)
2. [installing and configuring mediamicroservices](https://github.com/mediamicroservices/mm#installing-and-configuring-mediamicroservices)
    1. installing homebrew
    2. installing mediamicroservices
    3. configuring mediamicroservices
        1. variable explanations
3. [mediamicroservices functions and step by step instructions for use](https://github.com/mediamicroservices/mm#mediamicroservices-functions-and step-by-step-instructions-for-use)
    1. barcodeinterpret
    2. blackatends
    3. checksum2filemaker
    4. checksumpackage
    5. finishpackage
    6. fix_left2stereo
    7. fix_rewrap
    8. fix_volume
    9. ingestfile
    10. makebroadcast
    11. makedvd
    12. makeflv
    13. makeframes
    14. makelossless
    15. makemetadata
    16. makemp3
    17. makepdf
    18. makepodcast
    19. makeprores
    20. makeqctoolsreport
    21. makeresourcespace
    22. makeyoutube
    23. paperingest
    24. quickcompare
    25. uploadomneon
    26. verifypackage
    27. xdcamingest

## summary ##

mediamicroservices has been developed for the purpose of processing audiovisual collections at [CUNY Television](http://cuny.tv). This repository includes scripts to run ffmpeg to create access and service copies of audio visual assets, as well as to analyze, report, and deliver media as individual files or as Archive Information Packages. Mediamicroservices are developed and tested for a Mac OS X environment. 

Mediamicroservices are installed and run using the terminal application, so knowledge of the command line is useful, but not required. For information on the command line, please see [The Command Line Crash Course](http://cli.learncodethehardway.org/book/). Documentation is intended to assist individuals of all technical levels in installing and using mediamicroservices. 

Please use the [issue tracker](https://github.com/mediamicroservices/mm/issues) to report any issues with installation and usage of mediamicroservices. 

## installing and configuring mediamicroservices ##

### installing homebrew ###
before installing mediamicroservices, install homebrew to your computer. [here are directions for downloading homebrew](http://brew.sh/).
homebrew is a package manager that assists in managing all of the necessary components of mediamicroservices. 

be sure to update/upgrade homebrew regularly. 

to update the packages in homebrew, type: `$ brew update` into the command line. This command will tell you which packages need to be updated.
photo to come 

to upgrade the packages in homebrew, type: `$ brew upgrade` into the command line. This command will update all packages to their most recent version.
photo to come 

### installing mediamicroservices ###
once homebrew has been installed, you can install mediamicroservices. 

Type `$ brew tap mediamicroservices/mm` into the command line. This command will #what exactly does this do?
photo to come

Then, type `$ brew install mm` into the command line. This command will install mediamicroservices to your computer. Because mediamicroservices are packaged in homebrew, they are installed to your usr/local. #do I need to explain why this is important?
photo to come

hooray, you've installed mediamicroservices! 

### configuring mediamicroservices ###
in order for mediamicroservices to run, you must configure your delivery settings. 

Type `$ mmconfig ` to access the configuration file. This file will store your system variables. For example,  #example!

photo: your terminal should look something like this

If you are familiar with using nano, which opens and edits the file within terminal, choose option 1. Similarly, if you use the text editor TextMate, choose option 2. Either of these options allow for you to edit multiple variables at once. 

If you simply want to edit one variable at a time, then choose the corresponding number. You will be prompted to enter the value, which will be a directory, email address, filemaker url, or server path. For a directory path, create a directory first, and then drag and drop the directory into the terminal. This saves you time and potential errors in mistyping directory paths. Some variables you may never use, for example if you only use makelossless, you won't need to set the PODCASTDELIVER directory. At a minimum for the scripts to run, you must set the following directories: #which ones? Once you've completed your editing of the config file, 

#### variable explanations ####

1. edit config file in nano
choose this option to edit the config file using [nano](http://www.nano-editor.org/)

2. edit config file in TextMate 
choose this option to edit the config file using [TextMate](http://macromates.com/)
3. OUTDIR_INGESTFILE  
4. OUTDIR_INGESTXDCAM
5. OUTDIR_PAPER
6. AIP_STORAGE
7. PODCASTDELIVER
8. YOUTUBEDELIVER
9. TMPDIR
10. REGEX4PODCAST
11. DVDLABELPREFIX
12. OMNEONIP   
13. OMNEONPATH
14. CUSTOM_LOG_DIR
15. LTO_INDEX_DIR
16. LOCAL_MM_DIR
17. EMAIL_FROM
18. MAKEYOUTUBE_DELIVERY_EMAIL_TO
19. MAKEBROADCAST_DELIVERY_EMAIL_TO
20. FILEMAKER_DB
21. FILEMAKER_XML_URL
22. VOLADJUST
23. Quit



























