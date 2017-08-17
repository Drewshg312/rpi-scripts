#!/usr/bin/env bash
#==========================================================================
#                           MINIBIAN_START
#==========================================================================
source 'config.cfg'
source 'functions.sh'

set -o nounset

#----------SET LOGGING FORMAT-----------
declare NOW=$(date +"%b-%d-%y-%H%M%S")
declare LOGFILE="/tmp/install-${NOW}.log"
#---------------------------------------

if [[ ${serial_console} == 'on' ]]; then
	echo "Enabling serial console"
fi

if [[ ${serial_console} == 'off' ]]; then
	echo "updating distro"
fi

