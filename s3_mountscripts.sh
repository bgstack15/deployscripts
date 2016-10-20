#!/bin/bash
# File: /root/s3_mountscripts.sh
# Package: deployscripts
# Author: bgstack15
# Startdate: 2015
# Title: Template Script 3: Mount Scripts Directory
# Purpose: Mounts the network mount for this organization
# History: 2016-05-19 given original headers
# Usage: ./s3[tab][enter]
# Reference:
# Improve:

server=$( hostname )
ipaddr=$( ifconfig | grep -E "Bcast|broadcast" | awk '{print $2}' | sed 's/[^0-9\.]//g;' )
sdir=/mnt/scripts

if [[ ! "$1" = "-y" ]];
then
   cat <<EOFNOTICE
ensure on norite.example.com:
  1. /etc/exports is allowing this host ("${server}")
  2. /etc/sysconfig/iptables allows this ip address ("${ipaddr}")
  3. service nfs restart
  4. service iptables restart
rerun this script with "-y"

References:
https://protect.example.com/wiki/display/itops/norite
EOFNOTICE
else
   # so "-y" was used
   [[ ! -d ${sdir} ]] && mkdir -p ${sdir} 2>/dev/null
   #mount -t nfs norite.example.com:/mnt/scripts /mnt/scripts
   mount /mnt/scripts #it better be in /etc/fstab!
fi
