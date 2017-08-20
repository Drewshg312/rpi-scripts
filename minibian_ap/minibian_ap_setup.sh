#!/usr/bin/env bash

source '../minibian_start/minibian_start_setup.sh'

apt-get install -y hostapd \
	isc-dhcp-server

cp_file etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf

# Specify the interface, dhcp server should listen on:
search_add '^INTERFACES=.*$' 'INTERFACES="wlan1"' '/etc/default/isc-dhcp-server'

ifdown wlan1  2>> ${LOGFILE} 1> /dev/null


