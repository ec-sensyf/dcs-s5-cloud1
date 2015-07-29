#!/bin/bash

# Project:       ${project.name}
# Author:        $Author: IPL-UV
# Last update:   ${doc.timestamp}:
# Element:       ${project.name}
# Context:       ${project.artifactId}
# Version:       ${project.version} (${implementation.build})
# Description:   ${project.description}
#
# Contact: ipl - uv.es

# source the ciop functions (e.g. ciop-log)
source ${ciop_job_include}

# If you want to have a complete debug information during implementation
ciop-enable-debug

# Where MCR is installed
MCR_PATH=$_CIOP_APPLICATION_PATH/MCR/v716
MATLAB_LAUNCHER=$_CIOP_APPLICATION_PATH/matlab/run_matlab_cmd.sh
MATLAB_CMD=$_CIOP_APPLICATION_PATH/s5_mcd_seq/s5_mcd_seq

# define the exit codes
SUCCESS=0
ERR_MCR=1
ERR_NOPARAMS=2

# add a trap to exit gracefully
function cleanExit()
{
   local retval=$?
   local msg=""
   case "$retval" in
     $SUCCESS)       msg="Processing successfully concluded";;
     $ERR_MCR)       msg="Error executing MCR";;
     $ERR_NOPARAMS) msg="Some parameters undefined";;
     *)               msg="Unknown error";;
   esac
   [ "$retval" != "0" ] && ciop-log "ERROR" "Error $retval - $msg, processing aborted" || ciop-log "INFO" "$msg"
   exit $retval
}
trap cleanExit EXIT

# retrieve the parameters value from workflow or job default value
blocks="`ciop-getparam blocks`"
subsampling="`ciop-getparam subsampling`"

# check parameters
# [ -z "$blocks" ] && blocks=500
[ -z "$subsampling" ] && subsampling=1

# Create output directory
OUTDIR="$TMPDIR/output"
mkdir -p "$OUTDIR"

# Instead of using ciop-copy (we don't need to write on input files), pass the
# directory where data is shared. This avoids copying files and is much faster.
# However, $dir_url MUST be a directory, not individual files.
read dir_url
INPDIR="$_CIOP_SHARE_PATH/$(echo $dir_url | cut -d/ -f4-)"
ciop-log "DEBUG" "Local dir: $INPDIR"

# Call matlab
cmd="$MATLAB_LAUNCHER $MCR_PATH $MATLAB_CMD $INPDIR $OUTDIR $subsampling"
eval $cmd 1>&2
[ "$?" == "0" ] || exit $ERR_MCR

# Publish results
ciop-log "INFO" "Publishing ..."
ciop-publish -m "$OUTDIR/*"

exit 0

