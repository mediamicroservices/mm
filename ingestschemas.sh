#!/bin/bash

if [ -d "${1}" ] ; then
    cd "${1}"
else
    Echo "Please use a valid directory for input - Exiting" && exit 0
fi

for i in *.schema ; do

done