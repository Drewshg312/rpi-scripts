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

check_root

print_status "THE LOG FILE: ${LOGFILE}"

# Set correct Time Zone:
ex=0
sh -c "echo ${timezone} > /etc/timezone"  2>> ${LOGFILE} 1> /dev/null
ex=+`check_exit "/etc/timezone modified with timezone: ${timezone}" "Failed to modify /etc/timezone by adding ${timezone}"`
dpkg-reconfigure -f noninteractive tzdata  2>> ${LOGFILE} 1> /dev/null
ex=+$?
if [[ ex -eq 0 ]]; then
>...print_good ""
else
>...print_error ""
fi
ex=+`check_exit "Successfully changed timezone to ${timezone}" "Failed to setup timezone to ${timezone}"`

