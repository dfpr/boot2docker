#!/bin/sh
. /etc/init.d/tc-functions

# Mount shared folder ASAP so most of logging can be sent back to the host
echo "Mounting BOINC shared/..."
modprobe vboxguest; modprobe vboxsf
mkdir -p /root/shared /root/scratch
mount -t vboxsf shared /root/shared/ 
mkdir -p /root/shared/results

# Follow logs and progress onto shared folder, one line at a time, in case we get suspend/resume'd 
safe_tail(){ nohup tail -F $1 | while IFS= read -r line; do echo "$line" >> $2; done & }
safe_tail /var/log/docker.log /root/shared/results/docker.log
safe_tail /var/log/boot2docker.log /root/shared/results/boot2docker.log
safe_tail /tmp/progress /root/shared/results/progress


echo "${YELLOW}Running boot2docker init script...${NORMAL}"

# This log is started before the persistence partition is mounted
/opt/bootscript.sh 2>&1 | tee -a /var/log/boot2docker.log

echo "${YELLOW}Finished boot2docker init script...${NORMAL}"
