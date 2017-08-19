DEFAULTS:
Hostname: minibian
users[groups]/passwords:
    root[root]/raspberry
#-------------------------------------------------------------------------------
# MINIBIAN_START
#-------------------------------------------------------------------------------
Hostname: raspberrypi
users[groups]/passwords:
	root[root]/my_usual_root_passwd

Interfaces:
	eth0 - wired
		IP1:     192.168.2.2
		subnet: 255.255.255.0
		gateway: 192.168.2.1
		default route : via 192.168.2.1
		IP2:	dhcp

	wlan0 - Broadcom BCM43438 Built-in Wireless
		IP: dhcp
		Type: managed

packages:
	raspi-conf
	rpi-update
	firmware-brcm80211
	pi-bluetooth
	wpasupplicant

	vim

	usbutils (lsusb and others…)
	locate
	traceroute
	tcpdump

Features:
	custom prompt
	vim customization (Mustang theme and plugins)

	EDITOR=/usr/bin/vim - set globally in custom file /etc/profile.d/env_var.sh
	USB Serial Console Cable enabled in boot partition /config.txt file
	Built-in interfaces (eth0 and wlan0)
	will always have same names independently of their MAC

