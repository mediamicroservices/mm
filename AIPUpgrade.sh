#!/bin/bash
while [ "${*}" != "" ] ; do
    # get context about the input
    INPUT="${1}"
    SUBDOC="${INPUT}/metadata/submissionDocumentation/"
    METADOC="${INPUT}/metadata/"
    shift
    if [ -d "${SUBDOC}" ] ; then 
        mv -v -n "${SUBDOC}"* "${METADOC}"
        rmdir "${SUBDOC}"
    fi
done

