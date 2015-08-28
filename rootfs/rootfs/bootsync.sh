#!/bin/sh
. /etc/init.d/tc-functions

echo "${YELLOW}Running boot2docker init script...${NORMAL}"

# Docker's own log should also be useful for debugging
tail -F /var/log/docker.log | vboxmonitor > /dev/null &

# This log is started before the persistence partition is mounted
/opt/bootscript.sh 2>&1 | tee -a /var/log/boot2docker.log | vboxmonitor


echo "${YELLOW}Finished boot2docker init script...${NORMAL}"
