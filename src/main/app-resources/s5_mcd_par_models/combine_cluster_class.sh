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
MCR_PATH=/usr/local/MATLAB/MATLAB_Compiler_Runtime/v716
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

if false ; then
    # Use ciop-log to log message at different level : INFO, WARN, DEBUG
    ciop-log "DEBUG" '##########################################################'
    ciop-log "DEBUG" '# Set of useful environment variables                    #'
    ciop-log "DEBUG" '##########################################################'
    ciop-log "DEBUG" "TMPDIR           = $TMPDIR"                  # The temporary directory for the task.
    ciop-log "DEBUG" "_JOB_ID          = ${_JOB_ID}"               # The job id
    ciop-log "DEBUG" "_JOB_LOCAL_DIR   = ${_JOB_LOCAL_DIR}"        # The job specific shared scratch space 
    ciop-log "DEBUG" "_TASK_ID         = ${_TASK_ID}"              # The task id
    ciop-log "DEBUG" "_TASK_LOCAL_DIR  = ${_TASK_LOCAL_DIR}"       # The task specific scratch space
    ciop-log "DEBUG" "_TASK_NUM        = ${_TASK_NUM}"             # The number of tasks
    ciop-log "DEBUG" "_TASK_INDEX      = ${_TASK_INDEX}"           # The id of the task within the job
    ciop-log "DEBUG" "_CIOP_SHARE_PATH = ${_CIOP_SHARE_PATH}"
fi

# Get parameters
TARGET_DATE=`ciop-getparam target_date`
SUBSAMP="`ciop-getparam subsamp`"
[ -z "$SUBSAMP" ] && SUBSAMP=1

# Create output directories
OUTDIR="$TMPDIR/combine_output"
mkdir -p "$OUTDIR"

# Process inputs

# Get input images (actually, images must be a directory URL inside HFDS, that is, hdfs://...
read input_url
ciop-log "DEBUG" "Input images: $input_url ..."
#IMGDIR=`ciop-copy -c -o $TMPDIR/images $input_url`
# And again, same 'trick' as in previous nodes
#IMGDIR="$_CIOP_SHARE_PATH/$(echo $input_url | cut -d/ -f4-)"
#ciop-log "DEBUG" "Local dir: $IMGDIR"

# Get predicted images
read predictions
predictions=`dirname $predictions`
#ciop-log "DEBUG" "Getting predictions: $predictions ..."
#PREDDIR=`ciop-copy -c -o $TMPDIR/predictions $predictions`
# Once again, do not copy, use the shared dir
PREDDIR="$_CIOP_SHARE_PATH/$(echo $predictions | cut -d/ -f4-)"
ciop-log "DEBUG" "Input predictions: $PREDDIR ..."


cmd="$MATLAB_LAUNCHER $MCR_PATH $MATLAB_CMD $input_url $PREDDIR $OUTDIR"
eval $cmd 1>&2
[ "$?" == "0" ] || exit $ERR_MCR

# Publish results
ciop-log "INFO" "Publishing ..."
ciop-publish -m "$OUTDIR/*"

exit 0

