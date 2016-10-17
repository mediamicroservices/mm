#!/bin/bash
#this script performs a virus check on a file or set of files

SCRIPTDIR=$(dirname $(which "${0}"))
. "${SCRIPTDIR}/mmfunctions" || { echo "Missing '${SCRIPTDIR}/mmfunctions'. Exiting." ; exit 1 ;};
DEPENDENCIES=(clamav)


while [ "${*}" != "" ] ; do
    INPUT="${1}"
    shift
  
    _run_critical clamscan -rva --log="${INPUT}/metadata/logs/clamav_$(date +%Y%m%d-%H%M%S).txt" "${INPUT}/objects"
done
