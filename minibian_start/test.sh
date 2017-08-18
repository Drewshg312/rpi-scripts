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

print_status "ENABLING SERIAL CONSOLE (ONLY FOR RASBERRY PI 3)"
# This actually disables serial,
# (enabling it breaks serial connection on Raspberry Pi 3)
raspi-config nonint do_serial 1  2>> ${LOGFILE} 1> /dev/null
check_exit "Switched UART to 1" "Failed to switch UART to 1"

if [[ ${serial_console} == 'on' ]]; then
	search_add 'dtoverlay=' 'dtoverlay=pi3-disable-bt' '/boot/config.txt'
	check_exit "Disabled Bluetooth on the UART" "Failed to Disable  Bluetooth on the UART"
	check_exit "Serial Console access for RPI3 is enabled" "Failed to Enable Serial Console"
fi

#declare cmds=(
#	'raspi-config nonint do_serial 1'
#	"search_add 'dtoverlay=' 'dtoverlay=pi3-disable-bt' '/boot/config.txt'"
#)
#
#task cmds[@] \
#	"Timezone ${timezone} is configured" \
#	"Failed to configre timezone ${timezone}" \
#	"${LOGFILE}"

