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
    26. xdcamingest

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
in order for mediamicroservices to run, you must configure your variable settings. first, take a look at the list of variables below to get a sense of what each variable means. Then, create all of the delivery directories that you'll need, in the place you'd like them to be. you can name the directories themselves anything you'd like- the more important part is tying them to a variable in the configuration process. Not all variables are necessary for microservices to run, so look over which microservices you'd like to use to get a sense of whether or not you'll need to a specific variable. 

Type `$ mmconfig -a` to access the configuration GUI, which will take information input and save a file as mm.conf. This file will store your system variables. For example,  #example!

mmconfig only has to be run once to create the configuration file, and will rewrite over itself if run again. 

if you prefer to edit in the terminal, simply run `$ mmconfig` and follow the directions on screen. this option allows for you to also choose to edit the config file in nano or TextMate. 

#### variable explanations ####

1. edit config file in nano
choose this option to edit the config file using [nano](http://www.nano-editor.org/)

2. edit config file in TextMate 
choose this option to edit the config file using [TextMate](http://macromates.com/)

3. OUTDIR_INGESTFILE
this variable is the processing directory. it is directory where your package will be created, and if you do not choose to deliver the package to AIP_STORAGE, this is where the completed package will remain. #make sure this is true! 
  
4. OUTDIR_INGESTXDCAM
this variable is the processing directory for xdcam files that are processed using using the mediamicroservices xdcamingest. 

5. OUTDIR_PAPER
this variable is the processing directory when using the paperingest script. 

6. AIP_STORAGE
this variable is the directory where the archival information package is delivered. 

7. PODCASTDELIVER
this variable is the directory where your podcast access copy is delivered. 

8. YOUTUBEDELIVER
this variable is the directory where your youtube access copy is delivered. 

9. TMPDIR
this variable is a temporary directory. it is used in the uploadomneon microservice as a temporary place for a file to live before it is uploaded to the omneon server. 

10. REGEX4PODCAST
this varible holds regular expressions that are queried when makepodcast is run, in order to determine if a file qualifies for podcast creation. If you want all of your files to qualify for podcast creation, enter a "." which matches (almost) any character. Learn more about [regex](https://en.wikipedia.org/wiki/Regular_expression).

11. DVDLABELPREFIX
this variable is for adding a set prefix to the filename for DVDs in makedvd. You may leave this variable blank if you do not want to have a prefix uniformly assigned. #is this right?

12. OMNEONIP   
this variable sets the IP address for delivery of files to the omneon server in uploadomneon and ingestfile. this variable can be set to the IP address of any server that you'd like to have the broadcast copy of your files delivered to. 

13. OMNEONPATH
this variable is the file path to the specific directory you'd like assets to be delivered to on the omneon server. 

14. CUSTOM_LOG_DIR
this variable is the directory that stores processing logs for all of the media microservices, and is used when the _log function is called. Consider creating a directory called mmlogs in your documents directory, and assigning it to this variable. 

15. LTO_INDEX_DIR
this variable is the directory that stores the .schema files created when LTOs are mounted and written to. If you are not using LTO in your workflow, you do not need to create this variable. If you do use LTO in your workflow, consider creating a directory called LTO Indexes, to be housed in your documents directory, and assigning it to this variable. 

16. LOCAL_MM_DIR
this variable is the directory that stores mediamicroservices scripts locally. 

17. EMAIL_FROM
this variable is the email address that notifications will be sent from, once processes have been completed. You may leave this variable blank if you do not want any notification emails sent once actions have been performed on files. 

18. MAKEYOUTUBE_DELIVERY_EMAIL_TO
this variable is the email address (or addresses) that notifications will be sent to once makeyoutube has been run on a file. 

19. MAKEBROADCAST_DELIVERY_EMAIL_TO
this variable is the email address (or addresses) that notifications will be sent to once makebroadcast has been run on a file. 

20. FILEMAKER_DB
this variable stores the name of the FileMaker database that is used in checksum2filemaker to upload metadata from processed files to a FileMaker database. You may leave this variable blank if you do not use FileMaker.

21. FILEMAKER_XML_URL
this variable stores the API address where metadata is delivered to in FileMaker. 

22. VOLADJUST
This variable must be set to yes (Y) or no (N). If set to yes, volume will be run through a volume adjustment filter and adjusted accordingly during transcoding. 

23. Quit
if editing in the terminal, use this option to leave the configuration file editor.

## mediamicroservices functions and step by step instructions for use ##


barcodeinterpret
blackatends
checksum2filemaker
checksumpackage
finishpackage
fix_left2stereo
fix_rewrite
fix_volume
ingestfile
makebroadcast
makedvd
makeflv
makeframes
makelossless
makemetadata
makemp3
makepdf
makepodcast
makeprores
makeqctoolsreport
makeresourcespace
maketree
makeyoutube
paperingest
quickcompare 
uploadomneon
verifytree






















