#!/bin/sh
# script for execution of deployed applications
#
# Sets up the MCR environment for the current $ARCH and executes
# the specified command.
#

#exe_name=$0
#exe_dir=`dirname "$0"`

DEBUG=1

# A function to send echo's to stderr for debug, or does nothing
if [ $DEBUG -eq 1 ] ; then
    echr() { echo "  rmc $@" 1>&2; }
else
    echr () { : ; }
fi

#echo "------------------------------------------"
if [ "x$1" = "x" ]; then
  echo Usage:
  #echo $0 \<deployedMCRroot\> matlab_cmd args
  echo $0 matlab_cmd args
else

  # I use echr instead of ciop-log because the second loses parameters :-(
  echr "Parameters received: $@"

  # This is needed if the generated MCR has CTR embedded
  MCR_CACHE_ROOT=$TMPDIR;
  export MCR_CACHE_ROOT;
  #echr "MCR_CACHE_ROOT set to ${MCR_CACHE_ROOT}"

  #echo Setting up environment variables
  #MCRROOT="$1"
  #shift
  MCRROOT=/usr/local/MATLAB/MATLAB_Compiler_Runtime/v716

  #echo ---
  LD_LIBRARY_PATH=.:${MCRROOT}/runtime/glnxa64;
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnxa64;
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnxa64;
	MCRJRE=${MCRROOT}/sys/java/jre/glnxa64/jre/lib/amd64;
	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/native_threads;
	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/server;
	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/client;
	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE};
  XAPPLRESDIR=${MCRROOT}/X11/app-defaults;
  export LD_LIBRARY_PATH;
  export XAPPLRESDIR;
  #echr "LD_LIBRARY_PATH is ${LD_LIBRARY_PATH}"

  # Get matlab function to execute
  matlab_cmd="$1"
  shift

  # Get function arguments
  args=
  while [ $# -gt 0 ]; do
      token=`echo "$1" | sed 's/ /\\\\ /g'`   # Add blackslash before each blank
      args="${args} ${token}"
      shift
  done

  # For not embedded files, we need to copy the file and its CTF to a directory where
  # hadoop can decompress it
  if [ -f "$matlab_cmd.ctf" ] ; then
      echr "Copying $matlab_cmd to $TMPDIR ..."
      cp "${matlab_cmd}" "${TMPDIR}/"
      cp "${matlab_cmd}.ctf" "${TMPDIR}/"
      matlab_cmd="${TMPDIR}/$(basename ${matlab_cmd})"
  fi

  #eval "${exe_dir}/$matlab_cmd" $args
  echr "run_matlab_cmd: launching $matlab_cmd $args"
  eval "$matlab_cmd" $args
fi
exit
