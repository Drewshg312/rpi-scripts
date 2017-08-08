#!/usr/bin/env bash

#-----------------COLORIZE OUTPUT-------------------
function print_good() {
    echo -e "\x1B[01;32m[*]\x1B[0m $1"
}

function print_error() {
    echo -e "\x1B[01;31m[*]\x1B[0m $1"
}

function print_status() {
    echo -e "\x1B[01;34m[*]\x1B[0m $1"
}
#---------------------------------------------------

#--------------------CHECK ROOT---------------------
function check_root() {
    if [ "$(id -u)" != "0" ]; then
        print_error "This script must be ran as root"
        exit 1
    fi
}
#---------------------------------------------------

#-------------------SEARCH AND ADD------------------
# Find text pattern (first argument) in the specified file (third argument)
# and if the pattern is found then substitute it to another pattern (second argument)
# otherwise - append the pattern (second argument) to the end of the file
#
# call example:
#   search_add '^[ \t\s]*net.ipv4.ip_forward=[0-1]' 'net.ipv4.ip_forward=1' '/etc/sysctl.conf'
#
function search_add() {
	search_pattern=$1
	add_pattern=$2
	file=$3

	grep -q "${search_pattern}" ${file} && \
	sed -i "s/${search_pattern}/${add_pattern}/" ${file} \
	|| echo "${add_pattern}" >> ${file}
}
#---------------------------------------------------

#-------------------CHECK EXITCODE------------------
# Check Exit Code.
# And print out the Success Message (first argumment)
# or Error message (second argument)
#
function check_exit() {
	if [[ $? -eq 0 ]]; then
		print_good "$1"
		return 0
	else
		print_error "$2"
		print_error "Please check the log (${LOGFILE})"
		return 1
	fi
}
#---------------------------------------------------

#---------------------CP FILE-----------------------
# Copy file.
# If the file already exists
# then back it up by appending '_orig' postfix
# (if 0 is specified as a third argument)
#
# Or remove the original one
# (if 1 specified as a third argument)
#
# call example:
#   cp_file 'src/etc/nsd/nsd.conf' '/etc/nsd/nsd.conf' 0
#   cp_file 'src/etc/net/ifcfg-eth0' '/etc/sysconfig/network-scripts/ifcfg-eth0' 1
#
function cp_file() {
	new_file=$1
	sys_file=$2
	rm_file=$3

	if [[ -f $sys_file ]]; then
		if [[ $rm_file -eq 0 ]]; then
			mv ${sys_file} "${sys_file}_orig"
		fi
		if [[ $rm_file -eq 1 ]]; then
			rm -rf ${sys_file}
		fi
	fi
cp ${new_file} ${sys_file}
}
#---------------------------------------------------

#----------------------MV FILE----------------------
# Move File.
# If the destination file exists
# then back it up by appending '_orig' postfix
# (if 0 is specified as a third argument)
#
## Or remove the original one
# (if 1 specified as a third argument)
#
# And rename(move) the specified file (first argument)
# to a new file (second argument)
#
# call example:
#   mv_file '/etc/nsd/nsd.config' '/etc/nsd/nsd.conf' 0
#   mv_file '/etc/sysconfig/network-scripts/ifcfg-WAN' '/etc/sysconfig/network-scripts/ifcfg-eth0' 1
#
function mv_file() {
	sys_file=$1
	new_filename=$2
	rm_file=$3

	if [[ -f $new_filename ]]; then
		if [[ $rm_file -eq 1 ]]; then
			rm -rf ${new_filename}
		elif [[ $rm_file -eq 0 ]]; then
			mv  ${new_filename} "${new_filename}_orig"
		else
			echo "cp_file func: Please specify the third argument (0 | 1)"
			return 1
		fi
	fi
mv ${sys_file} ${new_filename}
}
#---------------------------------------------------

#------------------CHECK DIRECTORY------------------
# Copy all files from specified directory (first argument)
# to equivalent system directory (for example: from ./src/etc/nsd to /etc/nsd)
# It uses check_file function and behavies in accordance with second argument:
# 0 -- backup original files in system dir
# 1 -- remove original files from system dir
#
# call example:
#  check_dir 'src/etc/nsd' 0                        # copy all dir content and backup all original files if they exist
#  check_dir 'src/etc/sysconfig/network-scripts' 1  # copy all dir content and remove original files if they exist
#
function check_dir() {
	dir=$1
	sys_dir=`echo $dir | sed -r 's/src|\.\/src//'`
	rm_files=$2
	files=`ls $dir`
	
	if [[ ! -d $sys_dir ]]; then
		mkdir $sys_dir
	fi
	for i in ${files}
	do
		cp_file "${dir}/${i}" "${sys_dir}/${i}" "${rm_files}"
	done
}
#---------------------------------------------------

#-----------------SERVICE RESTART-------------------
# Some services like nsd or unbound return 0 exitcode,
# but staying in the failed state, as systemctl status showing.
# This function shows the truth regarding the service state after restart.
#
# call example:
#    service_restart 'nsd'
#
function service_restart() {
	service=$1
	print_status "Restarting ${service}.service"
	systemctl restart "${service}.service" 2>> ${LOGFILE} 1> /dev/null
	if [[ ! $? -eq 0 ]]; then
		print_error "${service}.service restart failed"
		print_error "For troubleshooting check ${LOGFILE}, run systemclt status ${service} and journalctl -xe"
	else
		active=`systemctl status ${service}.service | fgrep 'Active: active'`
		if [[ $active == '' ]]; then
			print_error "${service}.service restart failed"
			print_error "For troubleshooting check ${LOGFILE}, run systemctl status ${service} and journalctl -xe"
		else
			print_good "${service}.service restarted successfully"
		fi
	fi
}

