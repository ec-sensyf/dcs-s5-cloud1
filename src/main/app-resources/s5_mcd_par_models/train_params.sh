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

# Get parameters
NMODELS="`ciop-getparam nmodels`"
TRNSAMPLES=`ciop-getparam trnsamples`
# Check parameters
[ -z "$NMODELS" ] && NMODELS=10
[ -z "$TRNSAMPLES" ] && TRNSAMPLES=1000

OUTPUT_FILE="$TMPDIR/training.txt"

# Inputs files are like
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
# directory where data is shared. This avoids copying files and is much faster.
#read file_url
#file_url="$(echo $file_url | cut -d/ -f4-)"
#INPUT_DIR="$_CIOP_SHARE_PATH/$(dirname $file_url)"
#ciop-log "DEBUG" "Local dir: $INPUT_DIR"

# Back to ciop-copy, the $_CIOP_SHARE_PATH is not available in slave nodes :-(
read dir_url
dir_url=$(dirname "$dir_url")
INPUT_DIR=$(ciop-copy -o "$TMPDIR" "$dir_url")

cmd="$MATLAB_LAUNCHER $MATLAB_CMD $INPUT_DIR $OUTPUT_FILE $TRNSAMPLES"
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
    #echo "$i $hyperparams $INPUT_DIR" | ciop-publish -s
    echo "$i $hyperparams $dir_url" | ciop-publish -s
    let i=$i+1
done

exit 0
