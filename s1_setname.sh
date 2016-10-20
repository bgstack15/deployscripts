#!/bin/bash
# File: /root/s1_setname.sh
# Package: deployscripts
# Author: bgstack15
# Startdate: 2015
# Title: Template Script 1: Set Name
# Purpose: Sets hostname regardless of OS
# History: 2016-08-16 Given original headers
# Usage: ./s1[tab][enter]
#   observe the /bin/bash shebang. I only run this on a system after bash is installed.
# Reference:
# Improve:

eval flavor=$( grep -iE "^\s*ID=" /etc/os-release 2>/dev/null | sed 's/^.*=//;' )
if test -z "${flavor}"; then test "$( uname -s )" = "FreeBSD" && flavor=freebsd; fi
case "${flavor}" in
   centos)
      motdfile=/etc/motd
      netfile=/etc/sysconfig/network
      templatename=centos7alpha
      ;;
   ubuntu)
      motdfile=/etc/issue
      templatename=ubuntu16alpha
      ;;
   freebsd)
      flavor=freebsd
      motdfile=/etc/motd
      netfile=/etc/rc.conf
      templatename=freebsd10alpha
      ;;
   *)
      echo "$0: Error 1. Cannot determine OS from /etc/os-release. Aborted." 1>&2
      exit 1
      ;;
esac

# OS agnostic
server=
role=
hostnamefile=/etc/hostname
tmpfile1=~/.$$.$RANDOM.tmp

function clean_setname {
   rm -f $tmpfile1 2>/dev/null
   exit
}

trap 'clean_setname' 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20

while [[ -z "$server" ]];
do
   printf "server (excluding .example.com): "
   read server
done

while [[ -z "$role" ]];
do
   printf "role: "
   read role
done

if [[ "$server" = "${server%%.*}" ]];
then
   serverlong="${server}".example.com
else
   # assume we placed .example.com in it already
   serverlong=${server}
   server="${serverlong%%.*}"
fi

# UPDATE FILES
# MOTD
sed "s/SERVER/${server}/g;s/ROLE/${role}/g;" <${motdfile} > ${tmpfile1}
cp -p ${tmpfile1} ${motdfile}
chmod 444 ${motdfile}
# HOSTNAME
printf "${serverlong}\n" > ${hostnamefile}
chmod 644 ${hostnamefile}

# FLAVOR-SPECIFIC ACTIONS
case "${flavor}" in
   centos)
      # UPDATE hostname and NetworkManager
      hostnamectl set-hostname "${serverlong}"
      {
         echo "NETWORKING=yes"
         echo "HOSTNAME=$serverlong"
      } > ${netfile}
      ;;
   ubuntu)
      # Change volume group names if necessary
      oldvg=$( vgs --rows | grep -E "^\s*VG" | awk '{print $2}' )
      case "${oldvg}" in
         *ubuntu16*-vg)
            vgrename "${oldvg}" "${server}-vg" >/dev/null 2>&1
            sed -i "s/${oldvg%-vg}--vg/${server}--vg/g;" /etc/fstab
            sed -i "s/${oldvg%-vg}--vg/${server}--vg/g;" /boot/grub/grub.cfg
            update-grub >/dev/null 2>&1
            sed -i "s/${templatename}/${server}/g;" /etc/postfix/main.cf
            /etc/init.d/postfix reload >/dev/null 2>&1
            ;;
         *) [ ];;
      esac
      ;;
   freebsd)
         # change hostname for freebsd. Need to update rc.conf, smb4.conf, /etc/mail/freebsd.mc
         hostname "${serverlong}"
         sed -I -e "s/^hostname=\".*\"/hostname=\"${serverlong}\"/;" /etc/rc.conf /etc/rc.conf.example
         sed -I -e "s/netbios name = .*$/netbios name = $( hostname -s )/;" /usr/local/etc/smb4.conf /usr/local/etc/smb4.conf.example
         sed -i -e 's/MASQUERADE_AS.*$/MASQUERADE_AS(\`'"$( hostname )'"')/;' /etc/mail/freebsd.mc

      ;;
# no wildcard needed because already vetted in flavor check earlier
esac
