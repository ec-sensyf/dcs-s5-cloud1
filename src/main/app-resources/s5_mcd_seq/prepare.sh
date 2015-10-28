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

# define the exit codes
SUCCESS=0
ERR_MCR=1
ERR_NOPARAMS=2
ERR_NOINPUTDATASET=3

# add a trap to exit gracefully
function cleanExit()
{
   local retval=$?
   local msg=""
   case "$retval" in
     $SUCCESS)       msg="Processing successfully concluded";;
     $ERR_MCR)       msg="Error executing MCR";;
     $ERR_NOPARAMS) msg="Some parameters undefined";;
     $ERR_NOINPUTDATASET) msg="No input dataset defined (or it does not exists";;
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

# Create output directory
OUTDIR="$TMPDIR/output"
mkdir -p "$OUTDIR"

# Read input files from catalog, copy and uncompress them to working dir
while read file_url
do
    ciop-log "INFO" "Getting and preparing $file_url ..."
    # Input files maybe compressed (.tgz), but ciop-copy uncompress them for us
    CIOPDIR=$(ciop-copy -o "$TMPDIR" "$file_url")
    # Create softlinks to files in $INPDIR
    softlink "$CIOPDIR" "$OUTDIR"
done

# Publish results
ciop-log "INFO" "Publishing ..."
ciop-publish "$OUTDIR/*"
# Pass whole $OUTDIR instead of individual files
#ciop-publish "$OUTDIR"

exit 0
