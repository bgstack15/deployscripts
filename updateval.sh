#!/bin/sh
# File: /root/updateval.sh
# Package: deployscripts
# Author: bgstack15
# Startdate: 2016-07-27
# Title: Script that Updates/Adds Value
# Purpose: Supposed to allow idempotent and programmatic modifications to config files
# History: 2016-08-01 last modified main content
#    2016-10-11 Replaced in bgscripts with python3 script. The shell version is maintained for the deployscripts package.
# Usage: ./updateval.sh /etc/rc.conf "^ntpd_enable=.*" 'ntpd_enable="YES"' --apply
# Reference:
#    "Building the FreeBSD 10.3 Template.docx"
# Improve:
# Document: Below this line

infile="${1}"
searchstring="${2}"
destinationstring="${3}"
doapply="${4}"
tmpfile="$( mktemp )"
lineexists=0

#determine sed command
case "$( uname -s )" in
   FreeBSD) sedcommand=gsed; formatstring="-f %p";;
   Linux|*) sedcommand=sed; formatstring="-c %a";;
esac

#linenum=$( grep -niE "${searchstring}" "${infile}" | awk -F: '{print $1;}' )
linenum=$( awk "/${searchstring}/ { print FNR; }" "${infile}" )
#echo "linenum=\"${linenum}\""
for word in ${linenum};
do
   #echo "word=${word}"
   if test -n "${word}" && test ${word} -ge 0;
   then
      # line number is valid
      lineexists=1
      #echo "##### line number is valid"
      if test "${doapply}" = "--apply";
      then
         #echo $sedcommand -i -e "s/${searchstring}/${destinationstring}/;" ${infile}
         $sedcommand -i -e "s/${searchstring}/${destinationstring}/;" ${infile}
      else
         #echo $sedcommand -e "s/${searchstring}/${destinationstring}/;" ${infile}
         $sedcommand -e "s/${searchstring}/${destinationstring}/;" ${infile}
      fi
   fi
done
if test "${lineexists}x" = "0x";
then
   # must add the value
   #echo "##### must add the value"
   if test "${doapply}" = "--apply";
   then
      { cat "${infile}"; printf "${destinationstring}\n"; } > ${tmpfile}
      _perms=$( stat ${formatstring} "${infile}" | tail -c5 )
      mv "${tmpfile}" "${infile}"
      chmod "${_perms}" "${infile}"
   else
      { cat "${infile}"; printf "${destinationstring}\n"; }
   fi
fi
