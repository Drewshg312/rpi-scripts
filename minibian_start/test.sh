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
declare -a cmds=(
	'sh -c "echo ${timezone}" > /etc/timezone'
	"dpkg-reconfigure -f noninteractive tzdata"
)

task cmds[@] \
	"Timezone ${timezone} is configured" \
	"Failed to configre timezone ${timezone}" \
	"${LOGFILE}"

