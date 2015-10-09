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
MATLAB_CMD=$_CIOP_APPLICATION_PATH/s5_mcd_par_models/train_params

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
NMODELS="`ciop-getparam nmodels`"
TRNSAMPLES=`ciop-getparam trnsamples`
# Check parameters
[ -z "$NMODELS" ] && NMODELS=10
[ -z "$TRNSAMPLES" ] && TRNSAMPLES=1000

OUTPUT_FILE="$TMPDIR/training.txt"

# Inputs files are in the form
# hdfs://sb-10-15-22-20.sensyf.terradue.int:8020/tmp/sandbox/s5_mcd_par_models/prepare/data/output

# Read input files, copy and uncompress them to working dir
#while read dir_url
#do
#    ciop-log "INFO" "Getting and preparing $dir_url ..."
#    CIOPDIR=$(ciop-copy -o "$TMPDIR" "$dir_url")
#    # Save original dir URI
#    ORIGINAL_DIR=$dir_url
#done

# Instead of using ciop-copy (we don't need to write on input files), pass the
# directory where data is mounted / shared. This avoids copying files and is
# much faster. However, $dir_url MUST be a directory, not individual files.
read dir_url
INPUT_DIR="$_CIOP_SHARE_PATH/$(echo $dir_url | cut -d/ -f4-)"
ciop-log "DEBUG" "Local dir: $INPUT_DIR"

cmd="$MATLAB_LAUNCHER $MCR_PATH $MATLAB_CMD $INPUT_DIR $OUTPUT_FILE $TRNSAMPLES"
eval $cmd 1>&2
[ "$?" == "0" ] || exit $ERR_MCR

# Publish results
ciop-log "INFO" "Publishing ..."
#ciop-publish "$OUTDIR/*"
#while read line
#do
#    echo $line | ciop-publish -s
#done < $OUTPUT_FILE
i=1
read hyperparams < $OUTPUT_FILE
while [ $i -le $NMODELS ] ; do
    echo "$i $hyperparams $INPUT_DIR" | ciop-publish -s
    let i=$i+1
done

exit 0

