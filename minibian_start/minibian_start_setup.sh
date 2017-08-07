#!/usr/bin/env bash
#=========================================================================
#                           MINIBIAN_START
#=========================================================================
source config.cfg

set -o nounset

#=========================================================================
#----------------------------NETWORK SETUP--------------------------------
#=========================================================================
#
# Make sure that wireless interfaces will be assigned permanent names.
# Make wifi interfaces to be always wlan0 independently of their mac address
# This is important for our distro to be usable on different physical pi.
#
# Power off the host and unplug all the interfaces except the one you want to be first (wlan0)
# To enable it to control the assignment of permanent names to wlan devices we need to edit file
#
fgrep -q 'KERNEL!="eth*[1-9]|ath*|wlan*[1-9]|msh*|ra*|sta*|ctc*|lcs*|hsi*"' \
	/lib/udev/rules.d/75-persistent-net-generator.rules
if [[ ! $? -eq 0 ]]; then
	sed -i '/^KERNEL!="/ s/^/#/' /lib/udev/rules.d/75-persistent-net-generator.rules && \
	sed -i '/^#KERNEL!="/a KERNEL!="eth*[1-9]|ath*|wlan*[1-9]|msh*|ra*|sta*|ctc*|lcs*|hsi*", \\' \
		/lib/udev/rules.d/75-persistent-net-generator.rules
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

auto wlan0
iface wlan0 inet manual
    wpa-roam /etc/wpa_supplicant/wpa_supplicant.conf

iface default inet dhcp

EOF
#This will add a second static IP address to eth0 interface
#(useful when connecting to network without dhcp)

# Restart networking service:
systemctl daemon-reload
systemctl restart networking.service

#=========================================================================
#
# Update packages and install raspi-config:
apt-get update -y
apt-get install -y raspi-config

# Expand file system:
raspi-config nonint do_expand_rootfs
partprobe
resize2fs /dev/mmcblk0p2

# Set hostname:
hostnamectl set-hostname "${hostname}"

# Set correct Time Zone:
sh -c "echo ${timezone} > /etc/timezone"
dpkg-reconfigure -f noninteractive tzdata

# Update packages and upgrade distro:
#apt-get dist-upgrade -y
#apt-get upgrade -y

# Update Firmware:
apt-get install -y rpi-update
rpi-update

# Change root password:
apt-get install -y python3
pass_hash=`python3 -c 'import crypt; print(crypt.crypt(${new_root_passwd}, crypt.mksalt(crypt.METHOD_SHA512)))'`
echo "root:${pass_hash}" | chpasswd -e

#=========================================================================
#-----------------------------CONFIGURE PROMPT----------------------------
#=========================================================================
mv /etc/skel /etc/skel.dist
cp -r etc/skel /etc/

# Also for root do this:
rm -rf /root/.bashrc /root/.profile
cp /etc/skel/.bashrc /root/.bashrc && source /root/.bashrc
cp /etc/skel/.profile /root/.profile && source /root/.profile

# Enable Wifi and Bluetooth on the new Raspberry Pi 3:
apt-get install -y firmware-brcm80211 pi-bluetooth wpasupplicant #firmware-linux-nonfree wireless-tools

#=========================================================================
#-----------------------------CONFIGURE VIM-------------------------------
#=========================================================================
#Install vim:
apt-get install -y vim

#Upload FROM ANOTHER MACHINE CONFIGS:
cp -r vim/.vim ~/
cp vim/.vimrc ~/

# Make vim default editor for visudo:
update-alternatives --set editor /usr/bin/vim
# Every shell script in /etc/profile.d/ will be sourced during the boot process.
# This will happen before login so all Env Variables will be declared Globally.
cp etc/profile.d/env_var /etc/profile.d

#=========================================================================
#-----------------------------CLEANUP-------------------------------------
#=========================================================================
# Remove all packages that aren't needed for the system:
apt-get autoremove
apt-get clean
echo ""
echo "DONE!"
echo "Please reboot the host"
#=========================================================================
