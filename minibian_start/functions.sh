#!/usr/bin/env bash

#-----------------COLORIZE OUTPUT-------------------
function print_good() {
    echo -e "\x1B[01;32m[*]\x1B[0m $1"
}

function print_error() {
    echo -e "\x1B[01;31m[*]\x1B[0m $1"
}

function print_status() {
    printf "\n\x1B[01;34m[*]\x1B[0m $1\n"
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
# call example:
#   check_exit 'Success' 'Error'
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

	if [[ -f ${sys_file} ]]; then
		if [[ ${rm_file} -eq 0 ]]; then
			mv ${sys_file} "${sys_file}_orig"
		fi
		if [[ ${rm_file} -eq 1 ]]; then
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

	if [[ -f ${new_filename} ]]; then
		if [[ ${rm_file} -eq 1 ]]; then
			rm -rf ${new_filename}
		elif [[ ${rm_file} -eq 0 ]]; then
			mv  ${new_filename} "${new_filename}_orig"
		else
			echo "cp_file func: Please specify the third argument (0 | 1)"
			return 1
		fi
	fi
mv ${sys_file} ${new_filename}
}
#---------------------------------------------------

#------------------COPY DIRECTORY------------------
# Copy all files from specified directory (first argument)
# to system directory (second argument)
# and if the system directory already exists, then
# according the third argiment:
# either - 1 -- backup system dir by appending '.dist' to it's name
# or     - 0 -- remove original files from system dir
#
# call example:
#  check_dir 'src/etc/skel' '/etc/skel' 1 # backup the old dir to /etc/skel.dist 
#                                         # and copy all src/etc/skel content to /etc/skel
#
#  check_dir "home/.vim" "~/.vim" 0       # do not backup the originnal directory
#                                         # NOTE: double quotes used to interpret ~ properly
#
function cp_dir() {
	dir=$1
	sys_dir=$2
	backup=$3
	if [[ -d ${sys_dir} ]]; then
		if [ ${backup} -eq 1 -a ! -d "${sys_dir}.dist" ]; then
			cp -r "${sys_dir}" "${sys_dir}.dist"
		fi
			rm -rf ${sys_dir}/*
	else
		mkdir -p "${sys_dir}"
	fi
	cp -r ${dir}/. ${sys_dir}/
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
	systemctl restart "${service}.service" 2>> ${LOGFILE} 1> /dev/null
	if [[ ! $? -eq 0 ]]; then
		print_error "${service}.service restart failed"
		print_error "For troubleshooting check ${LOGFILE}, run systemclt status ${service} and journalctl -xe"
	else
		active=`systemctl status ${service}.service | fgrep 'Active: active'`
		if [[ ${active} == '' ]]; then
			print_error "${service}.service restart failed"
			print_error "For troubleshooting check ${LOGFILE}, run systemctl status ${service} and journalctl -xe"
		else
			print_good "${service}.service restarted successfully"
		fi
	fi
}

#-------------------PERFORM TASK--------------------
# This function takes a Simple array ($1 - first arg)
# which contains a list of shell commands that needs
# to be run in order to perform specific task.
#
# IF all commands in the array succeded, then
# task assumed successful and the function spits out
# Good message ($2 - second arg)
#
# IF any of commands in the array fail, then
# the whole task is failed and the function spits out
# and Error message ($3 - third ard).
#
# STDOUT from all commands is redirected to /dev/null
# STDERR from all commands is redirected to log ($4)
#
# call example:
#    task cmds[@] \
#         "Timezone ${timezone} is configured" \
#         "Failed to configre timezone ${timezone}" \
#         "${LOGFILE}"
#
function task() {
	declare -a commands=("${!1}")
	declare good=$2
	declare error=$3
	declare log=$4
	ex=0
	for cmd in "${commands[@]}"; do
		eval ${cmd} 2>> ${log} 1> /dev/null
		let "ex+=$?"
	done
	if [[ "${ex}" -eq 0 ]]; then
		print_good "${good}"
	else
		print_error "${error}"
	fi
}

