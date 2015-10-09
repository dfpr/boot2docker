#!/bin/sh

# * stop Docker
# * save docker files to the persistence file in the scratch folder
# * optionally start Docker back up
#
# Should be used from a boinc_app to do save downloaded images immediately after a docker pull 

/usr/local/etc/init.d/docker stop

echo "Saving persistence directories..."
UUID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 32 | head -n 1)
tar cf /root/scratch/boinc2docker_persistence_$UUID.tar /var/lib/docker/* &&
mv /root/scratch/boinc2docker_persistence_$UUID.tar /root/scratch/boinc2docker_persistence.tar

if [[ "$1" != "--no-restart" ]]; then
    /usr/local/etc/init.d/docker start
    for i in $(seq 10); do sleep 1 && docker images && break; done
fi
