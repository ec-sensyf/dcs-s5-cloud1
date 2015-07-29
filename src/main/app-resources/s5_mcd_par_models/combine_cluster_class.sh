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
MATLAB_CMD=$_CIOP_APPLICATION_PATH/s5_mcd_par_models/combine_cluster_class

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

# Get parameters
TARGET_DATE=`ciop-getparam target_date`
SUBSAMP="`ciop-getparam subsamp`"
[ -z "$SUBSAMP" ] && SUBSAMP=1

# Create output directories
OUTDIR="$TMPDIR/combine_output"
mkdir -p "$OUTDIR"

# Process inputs

# Get input images (images should be a directory URL inside HFDS, that is, hdfs://...
read input_url
ciop-log "DEBUG" "Input images: $input_url ..."

# Get predicted images
read predictions
predictions=`dirname $predictions`

# Do not copy, use the shared dir
PREDDIR="$_CIOP_SHARE_PATH/$(echo $predictions | cut -d/ -f4-)"
ciop-log "DEBUG" "Input predictions: $PREDDIR ..."

# Launch processor
cmd="$MATLAB_LAUNCHER $MCR_PATH $MATLAB_CMD $input_url $PREDDIR $OUTDIR"
eval $cmd 1>&2
[ "$?" == "0" ] || exit $ERR_MCR

# Publish results
ciop-log "INFO" "Publishing ..."
ciop-publish -m "$OUTDIR/*"

exit 0

