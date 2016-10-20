#!/bin/bash
# File: /root/s5_auth.sh
# Package: deployscripts
# Author: bgstack15
# Startdate: 2016-08-02
# Title: Template Script 5: AD Authorization
# Purpose: To join AD for users and groups
# History: 2016-08-02 given original headers
# Usage: ./s5[tab][auth]
# Reference:
#    "\\example.com\staff\IT\PlatformServices\Linux\Templates\Building the Centos 7 Template.docx"
# Improve:

eval flavor=$( grep -iE "^\s*ID=" /etc/os-release 2>/dev/null | sed 's/^.*=//;' )
if test -z "${flavor}"; then test "$( uname -s )" = "FreeBSD" && flavor=freebsd; fi

thisuser="Bgstack15"

case "${flavor}" in
   centos|redhat|ubuntu|debian)
      realm join example.com -U "${thisuser}" --install=/
      /bin/cp -fp /etc/sssd/sssd.conf      /etc/sssd/sssd.conf.orig
      /bin/cp -fp /etc/sssd/sssd.conf.example  /etc/sssd/sssd.conf
      chmod 600   /etc/sssd/sssd.conf
      
      /bin/cp -fp /etc/krb5.conf       /etc/krb5.conf.orig
      /bin/cp -fp /etc/krb5.conf.example   /etc/krb5.conf
      chmod 644   /etc/krb5.conf
      
      sed -i -e '\|^sudoers:.*|h; ${x;s/sudoers://;{g;tF};a\' -e 'sudoers:\tfiles' -e '};:F;s/.*sudoers:.*/sudoers:\tfiles/g;' /etc/nsswitch.conf
      
      systemctl restart sssd.service
      time id "${thisuser}" | fold -w 80 | head
      
      cat <<EOF > /etc/cron.d/keepadalive
# File: /etc/cron.d/keepadalive
# Purpose: keeps ad user authentication active and fast, by frequently asking for group info for a user
*/5 * * * *  root  /usr/bin/id Bgstack15 >/dev/null 2>&1
EOF
      ;;
   freebsd)
      kinit "${thisuser}"
      net ads join -k -U "${thisuser}"
      kdestroy
      kinit -k "$( hostname -s | tr 'a-z' 'A-Z')\$"
      /root/updateval.sh /etc/crontab '^#.*\/kinithost.sh' '0,30\t*\t*\t*\t*\troot\t\/usr\/local\/bin\/kinithost\.sh' --apply
      # enable services
      /root/updateval.sh /etc/rc.conf '^samba_server_enable=.*' 'samba_server_enable="YES"' --apply
      /root/updateval.sh /etc/rc.conf '^sssd_enable=.*' 'sssd_enable="YES"' --apply
      # cannot start services regularly until a reboot, so onestart for now
      service samba_server start
      service sssd start
      ;;
   *)
      echo "Cannot identify OS/flavor. Aborted." && exit 2
      ;;
esac
