#/bin/bash
# Script to create a cronjob to stop ntpd, force a time update using ntpdate, then start ntpd again.
# required to work around poor timekeeping on VMWare 5.x
# Chris Vidler - Dynatrace DC RUM SME 2018, GPL3.0
#
#

# set this to a NTP server
NTPSERVER=10.10.10.10

# leave the rest of this alone

CRONFILE="/etc/cron.daily/timeresync"
COMMANDS="#!/bin/sh\n# force time resync\n/bin/systemctl stop ntp\n/sbin/ntpdate $NTPSERVER\n/bin/systemctl start ntpd"


OPTS=1
UNDEPLOY=0
while getopts ":dhz" OPT; do
	case $OPT in
		d)
			DEBUG=$((DEBUG + 1))
			;;
		z)
			UNDEPLOY=1
			;;
		h)
			OPTS=0
			;;
		\?)
			echo -e "*** WARNING: Invalid option -$OPTARG"
			;;
		:)
			OPTS=0
			echo -e "*** FATAL: Option -$OPTARG requires an argument"
			;;
	esac
done

if [ $OPTS -eq 0 ]; then
	echo -e "*** INFO: Usage $0 [-h] [-z]"
	echo -e "-h			This help."
	echo -e "-z			Undeploy."
	exit 1
fi


if [ -f $CRONFILE ] && [ -x $CRONFILE ]; then
	echo "Updating $CRONFILE"
	echo -e "$COMMANDS" > "$CRONFILE"
elif [ -f $CRONFILE ] && [ $UNDEPLOY ]; then
	echo "Removing $CRONFILE"
	rm -f "$CRONFILE"
else
	echo "Creating $CRONFILE"
	echo -e "$COMMANDS" > "$CRONFILE"
	if [ $? -ne 0 ]; then echo -e "Couldn't write $CRONFILE. FAILED!"; exit 1; fi
	chmod +x "$CRONFILE"
fi

