#!/bin/sh
# File: /root/s6_bgstack15.sh
# Package: deployscripts
# Author: bgstack15
# Startdate: 2016-05-20
# Title: Template Script 6: bgstackness
# Purpose: Set up my personal configs
# History:
# Usage: ./s6[tab][enter]
# Reference:
#    "\\example.com\staff\IT\PlatformServices\Linux\Templates\Building the Centos 7 Template.docx"
# Improve:

eval flavor=$( grep -iE "^\s*ID=" /etc/os-release | sed 's/^.*=//;' )
thisuser="Bgstack15"

case "${flavor}" in
   centos)
      wget http://mirror.example.com/bgscripts/bgscripts.repo -O /etc/yum.repos.d/bgscripts.repo
      yum -y install keepalive
      #cat <<EOFBGSTACK15 >/etc/sudoers.d/10_bgstack15
      #User_Alias BGSTACK15 = Bgstack15, bgstack15, bgstack15-local
      #BGSTACK15   ALL=(ALL)       NOPASSWD: ALL
      #EOFBGSTACK15
      ;;
   ubuntu)
      wget --quiet http://mirror.example.com/ubuntu/example-debian/example-debian.gpg -O /root/example-debian.gpg
      apt-key add /root/example-debian.gpg
      wget --quiet http://mirror.example.com/ubuntu/example-debian/example-debian.list -O /etc/apt/sources.list.d/example-debian.list
      http_proxy= apt-get update >/dev/null 2>&1
      http_proxy= apt-get -y install bgscripts keepalive
      ;;
esac
