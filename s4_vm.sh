#!/bin/bash
# File: /root/s4_vm.sh
# Package: deployscripts
# Author: bgstack15
# Startdate: 2015
# Title: Template Script 4: General Settings
# Purpose: Do initial hard-coded configs
# History: 2016-05-19 given original headers
# Usage: ./s4[tab][enter]
# Reference: Original vm.sh script by user1
# Improve:

eval flavor=$( grep -iE "^\s*ID=" /etc/os-release 2>/dev/null | sed 's/^.*=//;' )
if test -z "${flavor}"; then test "$( uname -s )" = "FreeBSD" && flavor=freebsd; fi

case "${flavor}" in
   centos|redhat)
      templatename=centos7alpha
      keyfile=/etc/pki/tls/private/localhost.key
      certfile=/etc/pki/tls/certs/localhost.crt
      ;;
   ubuntu|debian) 
      templatename=ubuntu16alpha
      keyfile=/etc/ssl/private/localhost.key
      certfile=/etc/ssl/certs/localhost.crt
      ;;
   freebsd)
      templatename=freebsd10alpha
      keyfile=/etc/ssl/localhost.key
      keyfile=/etc/ssl/localhost.crt
      ;;
   *) echo "Assuming centos directory layout for certificates..."
      templatename=unspecified0alpha
      keyfile=/etc/pki/tls/private/localhost.key
      certfile=/etc/pki/tls/certs/localhost.crt
      ;;
esac

rm -rf /root/.viminfo
history -w
history -c

cat /dev/null >/root/.bash_history

printf "Regenerating the ssh key...\n"
rm -rf /root/.ssh/id_rsa*
ssh-keygen -qt rsa -f /root/.ssh/id_rsa -P ""

printf "Changing password for user \"root\"\n"
passwd

#ntpd update example-dc1.example.com
ntpd -gq 1>/dev/null 2>&1

chmod +x /etc/cron.daily/0*logwatch 2>/dev/null || {
   #probably freebsd
   /root/updateval.sh /etc/crontab "^#*.*\t.*\t\*\t\*.*root.*\/usr\/local\/sbin\/logwatch\.pl$" "15\t4\t\*\t\*\t\*\troot\t\/usr\/local\/sbin\/logwatch\.pl" --apply
}

# clears these files without removing pointer, to prevent corruption
[[ -f /var/log/dmesg ]] && /bin/cat /dev/null >/var/log/dmesg
[[ -f /var/log/lastlog ]] && /bin/cat /dev/null >/var/log/lastlog
[[ -f /var/log/messages ]] && /bin/cat /dev/null >/var/log/messages
[[ -f /var/log/secure ]] && /bin/cat /dev/null >/var/log/secure
[[ -f /var/log/wtmp ]] && /bin/cat /dev/null >/var/log/wtmp
[[ -f /var/log/yum.log ]] && /bin/cat /dev/null >/var/log/yum.log
[[ -f /var/log/grubby ]] && /bin/cat /dev/null >/var/log/grubby
[[ -f /var/log/maillog ]] && /bin/cat /dev/null >/var/log/maillog
[[ -f /var/log/mail.log ]] && /bin/cat /dev/null >/var/log/mail.log
[[ -f /var/log/boot.log ]] && /bin/cat /dev/null >/var/log/boot.log
[[ -f /var/log/auth.log ]] && /bin/cat /dev/null >/var/log/auth.log
[[ -f /var/log/syslog ]] && /bin/cat /dev/null >/var/log/syslog
[[ -f /var/log/dpkg.log ]] && /bin/cat /dev/null >/var/log/dpkg.log
[[ -f /var/log/kern.log ]] && /bin/cat /dev/null >/var/log/kern.log

# deletes extra files
/bin/rm -f /var/log/*-???????? /var/log/*.gz /var/log/dmesg.old 2>/dev/null
/bin/rm -rf /var/log/anaconda 2>/dev/null

# suppress extraneous "dm-0: WRITE SAME failed. Manually zeroing" error
# Reference: http://www.it3.be/2013/10/16/write-same-failed/
thispath=$( find /sys | grep max_write_same_blocks | head -n 1 )
[[ -n "${thispath}" ]] && cat <<EOF > /etc/tmpfiles.d/write_same.conf
# Type Path        Mode UID  GID  Age Argument
w ${thispath}  -   -   -   -  0
EOF

#printf "Making new certificate for this host. Press enter to begin...\n"
#read foo
#openssl req -x509 -nodes -days 1095 -newkey rsa:2048 -keyout /etc/pki/tls/private/localhost.key -out /etc/pki/tls/certs/localhost.crt
expect /root/.makecert.exp "$( hostname )" "${keyfile}" "${certfile}"

case "${flavor}" in
   ubuntu)
      grep -liIE "${templatename}" /etc/* 2>/dev/null | xargs -n1 sed -i -e "s/ubuntu16alpha/$( hostname -s )/g;"
      update-grub >/dev/null 2>&1
   ;;
   *) [ ]
   ;;
esac
