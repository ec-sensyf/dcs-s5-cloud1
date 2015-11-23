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
ERR_INVALID_DATASET=3

# add a trap to exit gracefully
function cleanExit()
{
   local retval=$?
   local msg=""
   case "$retval" in
     $SUCCESS)               msg="Processing successfully concluded";;
     $ERR_MCR)               msg="Error executing MCR";;
     $ERR_NOPARAMS)         msg="Some parameters undefined";;
     $ERR_INVALID_DATASET) msg="Invalid dataset";;
     *)                       msg="Unknown error";;
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

# Get parameters
dataset=$(ciop-getparam dataset)
ts=$(ciop-getparam ts)

ciop-log "DEBUG" "Dataset: $dataset, time series: $ts"

# Create output directory
OUTDIR="$TMPDIR/output"
mkdir -p "$OUTDIR"

# Read input files from catalog, copy and uncompress them to working dir
while read file_url
do
    ciop-log "INFO" "Getting and preparing $file_url ..."

    case "$dataset" in
        Argentina|argentina)
            if [ "$ts" -eq 1 ] ; then
                case "$file_url" in
                    *"20130228"* | *"20130305"* | *"20130310"* | *"20130315"* ) ;;
                    *"82260842013261"* | *"82260842013309"* | *"82260842013341"* | *"82260842013357"* | *"82260842014008"* ) ;;
                    *) continue ;;
                esac
            else
                case "$file_url" in
                    *"20130409"* | *"20130414"* | *"20130419"* | *"20130504"* ) ;;
                    *"82260842013261"* | *"82260842013309"* | *"82260842013341"* | *"82260842013357"* | *"82260842014008"* ) ;;
                    *) continue ;;
                esac
            fi ;;
        Morocco|morocco)
            case "$file_url" in
                *"20130411"* | *"20130416"* | *"20130421"* | *"20130426"* | *"20130501"* ) ;;
                *) continue ;;
            esac ;;
        China|china)
            case "$file_url" in
                *"20130410"* | *"20130415"* | *"20130425"* | *"20130430"* | *"20130505"* ) ;;
                *) continue ;;
            esac ;;
        Jordan|jordan)
            if [ "$ts" -eq 1 ] ; then
                case "$file_url" in
                    *"20130311"* | *"20130321"* | *"20130326"* | *"20130331"* ) ;;
                    *) continue ;;
                esac
            else
                case "$file_url" in *"20130425"* | *"20130430"* | *"20130505"* | *"20130510"* | *"20130515"* ) ;;
                    *) continue ;;
                esac
            fi ;;
        Spain|spain|Barrax|barrax)
            case "$file_url" in
                *"81990332013152"* | *"81990332013184"* | *"81990332013200"* | *"81990332013216"* | *"81990332013248"* ) ;;
                *) continue ;;
            esac ;;
        *)
            exit $ERR_INVALID_DATASET ;;
    esac

    # Input files maybe compressed (.tgz), but ciop-copy uncompress them for us
    CIOPDIR=$(ciop-copy -o "$TMPDIR" "$file_url")
    # Create softlinks to files in $OUTDIR
    softlink "$CIOPDIR" "$OUTDIR"
done

# Publish results
ciop-log "INFO" "Publishing ..."
ciop-publish "$OUTDIR/*"
# Pass whole $OUTDIR instead of individual files
#ciop-publish "$OUTDIR"

exit 0

