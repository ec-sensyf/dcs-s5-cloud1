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
MATLAB_LAUNCHER=$_CIOP_APPLICATION_PATH/matlab/run_matlab_cmd.sh
MATLAB_CMD=$_CIOP_APPLICATION_PATH/s5_mcd_par_models/train_predict

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
TRNSAMPLES=`ciop-getparam trnsamples`
SUBSAMP=`ciop-getparam subsamp`
#BLOCKS=`ciop-getparam blocks`
[ -z "$TRNSAMPLES" ] && TRNSAMPLES=1000
[ -z "$SUBSAMP" ] && SUBSAMP=1
#[ -z "$BLOCKS" ] && BLOCKS=250

# Create output directories
OUTDIR="$TMPDIR/train_predict_output"
mkdir -p "$OUTDIR"

# Process inputs
INPUT_DIR=""
while read line
do
    nmodel=$(echo $line | awk '{print $1}')
    gamma=$(echo $line | awk '{print $2}')
    sigma=$(echo $line | awk '{print $3}')
    input_url=$(echo $line | awk '{print $4}')
    
    ciop-log "DEBUG" "Line: $line"
    ciop-log "DEBUG" "Parsed as n: $nmodel, g: $gamma, s: $sigma, url: $input_url"
    
    # Publish input_url only once
    if [ $nmodel -eq 1 ] ; then
        ciop-log "DEBUG" "Publishing input URL: $input_url"
        echo $input_url | ciop-publish -s
    fi

    # Copy files only once
    if [ ! -d "$INPUT_DIR" ] ; then
        INPUT_DIR=$(ciop-copy -o "$TMPDIR" "$input_url")
    fi
    
    ciop-log "INFO" "Predicting with model $nmodel ..."
    # Call MATLAB
    #cmd="$MATLAB_LAUNCHER $MATLAB_CMD $nmodel $TRNSAMPLES $gamma $sigma $input_url $OUTDIR $SUBSAMP $BLOCKS"
    cmd="$MATLAB_LAUNCHER $MATLAB_CMD $nmodel $TRNSAMPLES $gamma $sigma $INPUT_DIR $OUTDIR $SUBSAMP"
    eval $cmd 1>&2
    [ "$?" == "0" ] || exit $ERR_MCR
done

# Publish results
# If INPUT_DIR is not defined then this task did not receive inputs, so it did nothing
if [ -n "$INPUT_DIR" ] ; then
    # Publish results (all tasks)
    ciop-log "INFO" "Publishing ..."
    ciop-publish "$OUTDIR/*"
fi

exit 0
