#!/bin/bash
# File: /root/s2_networking.sh
# Package: deployscripts
# Author: bgstack15
# Startdate: 2015
# Title: Template Script 2: Networking
# Purpose: Set initial hard-coded network settings
# History: 2016-07-28 given initial headers
# Usage: ./s2[tab][enter]
# Reference:
# Improve:

eval flavor=$( grep -iE "^\s*ID=" /etc/os-release 2>/dev/null | sed 's/^.*=//;' )
if test -z "${flavor}"; then test "$( uname -s )" = "FreeBSD" && flavor=freebsd; fi

# interactive:
#macaddr=$( ip link show | grep ether | awk '{print $2}' )
macaddr=$( ifconfig | grep -oIE "(ether|HWaddr)\>.*\>" | awk '{print $2}' )
printf 'IP address: '; read thisip
echo ${thisip} | grep -qiE "^([0-9]{1,3}\.){3}[0-9]{1,3}" || { echo "Invalid IP. Aborted."; exit 1; }
defgateway=${thisip%.*}.254
printf "Gateway [${defgateway}]: "; read thisgateway
[[ -z ${thisgateway} ]] && thisgateway=${defgateway}
echo ${thisgateway} | grep -qiE "^([0-9]{1,3}\.){3}[0-9]{1,3}" || { echo "Invalid gateway. Aborted."; exit 1; }

#build other components
_netmask="255.255.255.0" #class c, or CIDR /24. Good enough for the example default.
_network="${thisip%.*}.0"
_broadcast="${thisip%.*}.255"

case "${flavor}" in
   centos)
      netfile=/etc/sysconfig/network-scripts/.template
      tmpfile=/tmp/netfile1
      outfile=/etc/sysconfig/network-scripts/ifcfg-eth0
      
      sed "s/HWADDR=.*/HWADDR=\"${macaddr}\"/;" ${netfile} > ${tmpfile}
      cat <<EOF >> ${tmpfile}
IPADDR=${thisip}
NETMASK=255.255.255.0
GATEWAY=${thisgateway}
EOF
      
      chmod --reference ${netfile} ${tmpfile}
      mv -f ${tmpfile} ${outfile}
      rm -f /etc/sysconfig/network-scripts/ifcfg-eno*
      systemctl restart network.service
      ;;
   ubuntu)
      netfile=/etc/network/interfaces.example
      tmpfile=/tmp/netfile1
      outfile=/etc/network/interfaces

      sed "s/THISIP/${thisip}/;s/THISNETMASK/${_netmask}/;s/THISNETWORK/${_network}/;s/THISBROADCAST/${_broadcast}/;s/THISGATEWAY/${thisgateway}/;" ${netfile} > ${tmpfile}
      chmod --reference ${outfile} ${tmpfile} 2>/dev/null
      mv -f ${tmpfile} ${outfile}
      ifdown -a
      ifup -a

      # Firewall rules, since ufw is disabled by default per https://help.ubuntu.com/16.04/serverguide/firewall.html
      ufw enable
      ufw allow ssh
      ;;
   freebsd)
      netfile=/etc/rc.conf.example
      tmpfile=/tmp/netfile1
      outfile=/etc/rc.conf
      sed "s/^ifconfig_em0=.*\$/ifconfig_em0=\"inet ${thisip} netmask ${_netmask}\"/;s/^defaultrouter=.*/defaultrouter=\"${thisgateway}\"/;" ${netfile} > ${tmpfile}
      cp -p ${tmpfile} ${outfile} 
      /etc/rc.d/netif restart
      ;;
   *)
      echo "$0: Error 1. OS cannot be determined from /etc/os-release. Aborted." 1>&2
      exit 1
      ;;
esac

echo "Please reboot (telinit 6)."
