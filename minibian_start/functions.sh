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
# Check if the file exists and changes it
# to a new version saving the original one appending '_orig' postfix
# if 0 is specified as a third argument
# Or removing the original one if 1 specified as a third argument
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
# Check if the file exists and if third argument is 0
# then backs up the original one appending '_orig' postfix
# OR
# if 1 is specified as a third argument
# then removes the original file
# And renames the specified file (first argument)
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

#---------------SED CONFIG FUNCTION-----------------
# Search through the list of all template config files
# and substitute the specified strings.
#
# First argument is an associative array (-A),
# where Key is a pattern to find,
# and Value is a pattern to replace with.
#
# second argument is a simple array (-A)
# which contains a list of files to be edited by sed
#
# call example:
#	sed_conf "$(declare -p nsd_string)" "$(declare -p nsd_config)"
#
#
# If the simple array needs to be passed to a function,
# Declare it within the function this way:
#	declare -a config=("${!2}") # where 2 - function argument number
#
# And call the function this way:
#	sed_conf "$(declare -p nsd_string)" nsd_config[@] "${LOGFILE}"
#
#
function sed_conf() {
	#declare -a config=("${!2}") 		# Simple array
	eval "declare -A config="${2#*=}
	eval "declare -A string="${1#*=}	# Associative array
	#declare -p string	# prove the associative array was created
	log="$3"
	for key in "${!config[@]}"; do
		exitcode=0
		for K in "${!string[@]}"; do
			sed -i -r "s/${K}/${string[${K}]}/g" "${config[${key}]}" 2>> "${log}"
			let "exitcode+=$?"
		done
		if [[ $exitcode -eq 0 ]]; then
			print_good "	${config[${key}]} was successfully configured"
		else
			print_error "	${config[${key}]} configuration failed"
		fi
	done
}
#---------------------------------------------------

#---------------------------------------------------
# PTR function
# creates the name for PTR zone from subnet IP address
# call example:
#	ptr_name=(ptr "${cidr[LAN]}" "${net[LAN]}" )
#
#10.10.10.10
function ptr() {
	cidr=$1
	net=$2
	if [[ ${cidr} -eq 24 ]]; then
	octets=3
	elif [[ ${cidr} -eq 16 ]]; then
	octets=2
	elif [[ ${cidr} -eq 8 ]]; then
	octets=1
	else
		if [[ ${cidr} -gt 24 ]]; then
			octets=3
		elif [ ${cidr} -gt 16 -a ${cidr} -lt 24 ]; then
			octets=2
		elif [ ${cidr} -gt 8 -a ${cidr} -lt 16 ]; then
			octets=1
		fi
		#oct=(${octets}+1)
		#net_part=`echo "${net}" | cut -d"." -f${oct}-`
		#echo "${net_part}"
	fi
	
	for (( i=${octets}; i>0; i-- )); do
		v=`echo "${net}" | cut -d"." -f ${i}`
		ptr_value+="${v}."
	done
	echo "${ptr_value}in-addr.arpa"
}

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

#-------------------CIDR TO MASK--------------------
function cidr2mask() {
	local i mask=""
	local full_octets=$(($1/8))
	local partial_octet=$(($1%8))
	for ((i=0;i<4;i+=1)); do
		if [ $i -lt $full_octets ]; then
			mask+=255
		elif [ $i -eq $full_octets ]; then
			mask+=$((256 - 2**(8-$partial_octet)))
		else
			mask+=0
		fi
		test $i -lt 3 && mask+=.
	done
	echo $mask
}
#---------------------------------------------------

