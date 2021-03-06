#!/usr/bin/env bash
#==========================================================================
#                           MINIBIAN_START
#==========================================================================
source 'config.cfg'
source 'functions.sh'

set -o nounset

#==========SET LOGGING FORMAT===========
declare NOW=$(date +"%b-%d-%y-%H%M%S")
declare LOGFILE="/tmp/install-${NOW}.log"
#=======================================

check_root

print_status "THE LOG FILE: ${LOGFILE}"
#==========================================================================

#=============================NETWORK SETUP================================
#
# Make sure that wireless interfaces will be assigned permanent names.
# Make wifi interfaces to be always wlan0 independently of their mac address
# This is important for our distro to be usable on different physical pi.
#
# Power off the host and unplug all the interfaces except the one you want to be first (wlan0)
# To enable it to control the assignment of permanent names to wlan devices we need to edit file
#
print_status "CONFIGURING NETWORK"

fgrep -q 'KERNEL!="eth*[1-9]|ath*|wlan*[1-9]|msh*|ra*|sta*|ctc*|lcs*|hsi*"' \
	/lib/udev/rules.d/75-persistent-net-generator.rules
if [[ ! $? -eq 0 ]]; then
	sed -i '/^KERNEL!="/ s/^/#/' /lib/udev/rules.d/75-persistent-net-generator.rules && \
	sed -i '/^#KERNEL!="/a KERNEL!="eth*[1-9]|ath*|wlan*[1-9]|msh*|ra*|sta*|ctc*|lcs*|hsi*", \\' \
		/lib/udev/rules.d/75-persistent-net-generator.rules  2>> ${LOGFILE} 1> /dev/null
fi
#
# After boot file will be generated /etc/udev/rules.d/70-persistent-net.rules
# It will be used to associate a wifi MAC address with a particular if name e.g. wlan0, wlan1, etc.

# Setting up WiFi:
cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

allow-hotplug eth0
iface eth0 inet dhcp

auto eth0:1
iface eth0:1 inet static
	address 192.168.2.2
	netmask 255.255.255.0
	#dns-nameservers 127.0.0.1
	post up ip route add default via 192.168.2.1

auto wlan0
iface wlan0 inet manual
	wpa-roam /etc/wpa_supplicant/wpa_supplicant.conf

iface default inet dhcp

EOF
#This will add a second static IP address to eth0 interface
#(useful when connecting to network without dhcp)
check_exit "/etc/network/interfaces modified" "failed to modify /etc/network/interfaces"

# Restart networking service:
systemctl daemon-reload  2>> ${LOGFILE} 1> /dev/null
check_exit "Networking Daemon Reloaded" "Networking Daemon Reload Failed"
service_restart 'networking'
#
#==========================================================================
#
print_status "CONFIGURING HOST SETTINGS (Expanding File System, Setting up Timezone)"
# Update packages and install raspi-config:
apt-get update -y  2>> ${LOGFILE} 1> /dev/null
check_exit "apt-get package lists are updated" "Failed to update apt-get package lists"
apt-get install -y raspi-config  2>> ${LOGFILE} 1> /dev/null
check_exit "raspi-config is installed. Updating firmware. Please wait..." "Failed to install raspi-config package"


# Expand file system:
declare -a cmds_fs=(
	'raspi-config nonint do_expand_rootfs'
	'partprobe'
	'resize2fs /dev/mmcblk0p2'
)
task cmds_fs[@] \
	"Filesystem is expanded. No need to reboot" \
	"Fatal: failed to expand the filesystem" \
	"${LOGFILE}"


# Set hostname:
hostnamectl set-hostname "${hostname}"  2>> ${LOGFILE} 1> /dev/null
check_exit "Hostname is changed to ${hostname}" "Failed to change a hostname to ${hostname}"

# Set correct Time Zone:
declare -a cmds_tz=(
	'sh -c "echo ${timezone}" > /etc/timezone'
	"dpkg-reconfigure -f noninteractive tzdata"
)
task cmds_tz[@] \
	"Timezone ${timezone} is configured" \
	"Failed to configre timezone ${timezone}" \
	"${LOGFILE}"


# Enable Wifi and Bluetooth on the new Raspberry Pi 3:
apt-get install -y firmware-brcm80211 \
	pi-bluetooth \
	wpasupplicant  2>> ${LOGFILE} 1> /dev/null
	#firmware-linux-nonfree
	#wireless-tools


# Update Firmware:
apt-get install -y rpi-update  2>> ${LOGFILE} 1> /dev/null
check_exit "Installed rpi-update package" "Failed to install rpi-update package"
rpi-update  2>> ${LOGFILE} 1> /dev/null
check_exit "Successfully updated firmware" "Failed to update firmware"

# Change root password:
echo "root:${new_root_passwd}" | chpasswd -c SHA512  2>> ${LOGFILE} 1> /dev/null
check_exit "Root password changed" "Failed to change root password"
#==========================================================================

#==============================CONFIGURE PROMPT============================
print_status "CONFIGURING SHELL PROMPT"
cp_dir 'etc/skel' '/etc/skel' 1 2>> ${LOGFILE} 1> /dev/null
check_exit "Customized /etc/skel content. Original is saved in /etc/skel.dist" \
           "Failed to customize /etc/skel content"

rm -rf /root/.bashrc /root/.profile  2>> ${LOGFILE} 1> /dev/null
cp /etc/skel/.bashrc /root/.bashrc  2>> ${LOGFILE} 1> /dev/null
cp /etc/skel/.profile /root/.profile  2>> ${LOGFILE} 1> /dev/null
#==========================================================================

#==============================CONFIGURE VIM===============================
print_status "CONFIGURING VIM"
#Install vim:
apt-get install -y vim  2>> ${LOGFILE} 1> /dev/null
check_exit "Installed vim.basic. Configuring plugins. Please wait..." "Failed to install vim package"

#Upload FROM ANOTHER MACHINE CONFIGS:
cp_dir 'home/.vim' '/root/.vim' 0  2>> ${LOGFILE} 1> /dev/null
cp home/.vimrc /root/  2>> ${LOGFILE} 1> /dev/null

git clone https://github.com/gmarik/vundle.git /root/.vim/bundle/vundle 2>> ${LOGFILE} 1> /dev/null

vim +PluginInstall +qall 2>> ${LOGFILE} 1> /dev/null

# Make vim default editor for visudo:
update-alternatives --set editor /usr/bin/vim.basic 2>> ${LOGFILE} 1> /dev/null

# Every shell script in /etc/profile.d/ will be sourced during the boot process.
# This will happen before login so all Env Variables will be declared Globally.
cp etc/profile.d/env_var.sh /etc/profile.d
check_exit "Environment variables set in /etc/profile.d/env_var.sh" \
           "Failed to set environment variables in /etc/profile.d/env_var.sh"
#==========================================================================

#==========================UPGRADING DISTRO================================
# Update packages and upgrade distro:
print_status "UPGRADING DISTRO (please wait...)"

apt-get dist-upgrade -y  2>> ${LOGFILE} 1> /dev/null
check_exit "Distro Successfully Upgraded" "'apt-get dist-upgrade' failed"
#==========================================================================

#============================SERIAL CONSOLE================================
print_status "CONFIGURING SERIAL CONSOLE"
# This actually disables serial,
# (enabling it breaks serial connection on Raspberry Pi 3)
sed '/enable_uart=/ d' /boot/config.txt  2>> ${LOGFILE} 1> /dev/null
check_exit "UART is disabled in /boot/config.txt" "Failed to disable UART in /boot/config.txt"

if [[ ${serial_console} == 'on' ]]; then
	search_add 'dtoverlay=.*\$' 'dtoverlay=pi3-disable-bt' '/boot/config.txt'
	check_exit "Disabled Bluetooth on the UART" "Failed to Disable  Bluetooth on the UART"
	check_exit "Serial Console access for RPI3 is enabled" "Failed to Enable Serial Console"
else
	print_good "Serial Console access for RPI3 is disabled"
fi
systemctl daemon-reload  2>> ${LOGFILE} 1> /dev/null
check_exit "Systemctl daemon reloaded successfully" "'systemctl daemon-reload' failed"
#==========================================================================

#==============================CLEANUP=====================================
print_status "CLEANING THINGS UP"
# Remove all packages that aren't needed for the system:
apt-get autoremove  2>> ${LOGFILE} 1> /dev/null
check_exit "'apt-get autoremove' succeded" "'atp-get autoremove' failed"
apt-get clean  2>> ${LOGFILE} 1> /dev/null
check_exit "'apt-get clean' succeded" "'atp-get clean' failed"

printf "\nDONE!\n"
echo "Please reboot the host... or at least relogin :)"
#==========================================================================

