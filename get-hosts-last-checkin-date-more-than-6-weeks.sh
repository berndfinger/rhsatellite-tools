#!/bin/bash
# get-hosts-last-checkin-date-more-than-6-weeks.sh:
#   Show the number of hosts which have not connected for more than 6 weeks
# 
# Author: Bernd Finger, Red Hat
# Wed Aug 11 10:10:21 CEST 2021
#

printf "Number of hosts: "
hammer host list --search 'last_checkin < "6 weeks ago"' --thin 1 | awk '!/---/&&NR>2{print $3}' | wc -l

#
# get a list of max. 300 hosts and their last checkin dates:
#
for name in $(hammer host list --search 'last_checkin < "6 weeks ago"' --thin 1 | awk '!/---/&&NR>2{print $3}' | awk 'NR<=300{print}'); do
   hammer host info --name ${name} | \
     awk '/^Name:/{name=$NF}/Last Checkin/{$1="";$2=""; sub("  ", ""); printf ("hammer host delete --id %s # last checkin: %s\n", name, $0)}'
done
