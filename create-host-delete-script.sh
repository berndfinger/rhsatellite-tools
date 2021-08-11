#!/bin/bash
# get-hosts-to-delete.sh:
#   Create a script for deleting hosts which have not checked in for more than 6 weeks
#
# Note: The script requires a file /var/log/hammer/delete-hosts/whitelist.txt which contains
#       names of hosts which never must be deleted. The file can be empty.
#       You may want to use directory /var/log/hammer/delete-hosts for storing any delete scripts
#       which have been run so far.
#
# Author: Bernd Finger, Red Hat
# Wed Aug 11 10:10:00 CEST 2021
#

_DATE=$(date +%Y-%m-%d)
_DATE_Y=$(date +%Y)
_DATE_M=$(date +%m)
_HAMMER_TOP_LOG_DIR=/var/log/hammer
_HAMMER_LOG_DIR=${_HAMMER_TOP_LOG_DIR}/${_DATE_Y}/${_DATE_M}
_HOSTS_TO_DELETE=${_HAMMER_LOG_DIR}/hosts-last-checkin-more-than-6-weeks-${_DATE}.txt
_HOSTS_TO_DELETE_SCRIPT=${_HAMMER_TOP_LOG_DIR}/delete-hosts-last-checkin-more-than-6-weeks.sh

if [[ ! -d ${_HAMMER_LOG_DIR} ]]; then
   mkdir -p ${_HAMMER_LOG_DIR}
fi

# Create a list of all hosts which have not checked in for more than 6 weeks:
rm -f ${_HOSTS_TO_DELETE}.tmp ${_HOSTS_TO_DELETE}.orig ${_HOSTS_TO_DELETE}
/root/bin/get-hosts-last-checkin-date-more-than-6-weeks.sh > ${_HOSTS_TO_DELETE}.tmp
sort -k8 ${_HOSTS_TO_DELETE}.tmp > ${_HOSTS_TO_DELETE}
cp -p ${_HOSTS_TO_DELETE} ${_HOSTS_TO_DELETE}.orig

# Remove hosts which are in the whitelist:
for _host in $(cat /var/log/hammer/delete-hosts/whitelist.txt); do
   _pattern=$(grep ${_host} ${_HOSTS_TO_DELETE});
   if [[ ${_pattern}. != "." ]]; then
      sed -i "/${_pattern}/d" ${_HOSTS_TO_DELETE}
   fi
done

# Modify the title line to contain the number of hosts to be deleted:
_NUMBER_OF_HOSTS_TO_DELETE=$(awk 'END{print NR-1}' ${_HOSTS_TO_DELETE})
mv ${_HOSTS_TO_DELETE} ${_HOSTS_TO_DELETE}.tmp
awk '/Number of hosts:/{print "Number of hosts to delete: '${_NUMBER_OF_HOSTS_TO_DELETE}'"}
!/Number of hosts:/{print}' ${_HOSTS_TO_DELETE}.tmp > ${_HOSTS_TO_DELETE}

# Create the delete script
# Note: The delete script displays the name of the host using the printf command, followed by
#       the hammer host delete command. A comment in the same line shows the last checkin date.
rm -f ${_HOSTS_TO_DELETE_SCRIPT}
awk 'NR==1{print}
NR>1{printf ("printf \"%s: \"; %s\n", $5, $0)}' ${_HOSTS_TO_DELETE} > ${_HOSTS_TO_DELETE_SCRIPT}
chmod u+x ${_HOSTS_TO_DELETE_SCRIPT}
