#!/usr/bin/env bash

# Install additional packages:
apt-get update && apt-get install git sudo tmux tcpdump unzip

# Create non-root user drew:
adduser drew
usermod -G sudo drew

#-----------------------INSTALL LIGHTWEIGHT GUI (LXDE)--------------------------
# Istall the Display Server
apt-get install -y --no-install-recommends xserver-xorg

# Install Desktop Environment, Window Manager, Login Manager and VNC Server:
apt-get install -y lxde-core lxappearance openbox lightdm tightvncserver

# Switch user(necessary for creating that file - sudo don't work):
sudo -s
cat >>/etc/systemd/system/vncserver@.service<< "EOF"
[Unit]
Description=Remote desktop service (VNC)
After=syslog.target network.target

[Service]
Type=forking
User=drew
PAMName=login
PIDFile=/home/drew/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver :%i -geometry 1920x1080 -depth 24 -dpi 69
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOF

# Enable the service:
systemctl daemon-reload && sudo systemctl enable vncserver@1.service
