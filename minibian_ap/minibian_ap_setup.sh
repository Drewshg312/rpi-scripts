#!/usr/bin/env bash
#==========================================================================
#                         MINIBIAN_ACCESS_POINT
#==========================================================================
source '../minibian_start/minibian_start_setup.sh'

apt-get install -y hostapd \
	isc-dhcp-server \


#==========================================================================

#=============================NETWORK SETUP================================
# copy dhcpd.conf, backup original one:
cp_file etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf 0

# Specify the interface, dhcp server should listen on:
#search_add '^INTERFACES=.*$' 'INTERFACES="wlan1"' '/etc/default/isc-dhcp-server'
cp_file etc/default/isc-dhcp-server /etc/default/isc-dhcp-server 0

ifdown wlan1  2>> ${LOGFILE} 1> /dev/null

# Copy network interfaces config and remove the old one:
cp_file etc/network/interfaces /etc/network/interfaces 1

cp_file etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf 0

# Tell the Pi where to find the hostapd config:
cp_file etc/default/hostapd /etc/default/hostapd 0

# Enable IPv4 forwarding:
sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
search_add '^.*net.ipv4.ip_forward=.*$' 'net.ipv4.ip_forward=1' '/etc/sysctl.conf'
search_add '^.*net.ipv6.conf.all.forwarding=.*$' 'net.ipv6.conf.all.forwarding=1' '/etc/sysctl.conf'

#=============================IPTABLES SETUP================================
# Install iptables-persistent (non-interactive):
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
apt-get install -y iptables-persistent

# Flush the old rules from the ip NAT table
iptables -F
iptables -t nat -F

# Create the NAT between the built in wifi port wlan0 and the usb wifi port wlan1:
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
iptables -A FORWARD -i wlan0 -o wlan1 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i wlan1 -o wlan0 -j ACCEPT

# FOR LOGGING PURPOSES ONLY:
iptables -t nat -S  2>> ${LOGFILE} 1> /dev/null
iptables -S  2>> ${LOGFILE} 1> /dev/null


#==========================================================================

