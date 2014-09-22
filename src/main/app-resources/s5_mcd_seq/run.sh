#!/bin/bash

# Project:       ${project.name}
# Author:        $Author: IPL-UV
# Last update:   ${doc.timestamp}:
# Element:       ${project.name}
# Context:       ${project.artifactId}
# Version:       ${project.version} (${implementation.build})
# Description:   ${project.description}
#
# Contact: jordi - uv.es

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

function softlink()
{
    # Input arguments: source dir $1, target dir $2
    ciop-log "DEBUG" "Source: $1"
    ciop-log "DEBUG" "Target: $2"
    
    # Go to target dir
    cd "$2"
    if [ -d "$1" ] ; then
        # Link .tif/.TIF file in source dir
        file=$(dir "$1"/*.{tif,TIF} 2>/dev/null)
        if [ -n "$file" ] ; then
            ln -s "$file" .
        else
            ciop-log "DEBUG" "No files found in source dir"
        fi
    elif [ -f "$1" ] ; then
        # Link file
        ln -s "$1" .
    else
        ciop-log "DEBUG" "Unknown source file type: $1"
    fi
    
    # Go back to initial directory
    cd - >/dev/null
}

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

# retrieve the parameters value from workflow or job default value
clus_fname="`ciop-getparam clus_fname`"
pred_fname="`ciop-getparam pred_fname`"

# check parameters
[ -z "$clus_fname" ] && exit $ERR_NOPARAMS
[ -z "$pred_fname" ] && exit $ERR_NOPARAMS

# Create output directory
INPDIR="$TMPDIR/input"
OUTDIR="$TMPDIR/output"
mkdir -p "$INPDIR"
mkdir -p "$OUTDIR"

# Read input files from catalog, copy and uncompress them to working dir
while read file_url
do
    ciop-log "INFO" "Getting and preparing $file_url ..."
    # Input files maybe compressed (.tgz), but ciop-copy uncompress them for us
    CIOPDIR=$(ciop-copy -o "$TMPDIR" "$file_url")
    # Create softlinks to files in $INPDIR
    softlink "$CIOPDIR" "$INPDIR"
done

# Call matlab
cmd="$MATLAB_LAUNCHER $MCR_PATH $MATLAB_CMD $INPDIR $OUTDIR/$clus_fname $OUTDIR/$pred_fname"
eval $cmd 1>&2
[ "$?" == "0" ] || exit $ERR_MCR

# Publish results
ciop-log "INFO" "Publishing ..."
ciop-publish -m "$OUTDIR/*"

exit 0

