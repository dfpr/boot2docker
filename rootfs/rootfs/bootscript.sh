#!/bin/sh

# Configure sysctl
/etc/rc.d/sysctl

# Load TCE extensions
/etc/rc.d/tce-loader

# Automount a hard drive
/etc/rc.d/automount

# set the hostname
/etc/rc.d/hostname
# Trigger the DHCP request sooner (the x64 bit userspace appears to be a second slower)
echo "$(date) dhcp -------------------------------"
/etc/rc.d/dhcp.sh
echo "$(date) dhcp -------------------------------"

# Mount cgroups hierarchy
/etc/rc.d/cgroupfs-mount
# see https://github.com/tianon/cgroupfs-mount

mkdir -p /var/lib/boot2docker/log

# Add any custom certificate chains for secure private registries
# /etc/rc.d/install-ca-certs

# import settings from profile (or unset them)
test -f "/var/lib/boot2docker/profile" && . "/var/lib/boot2docker/profile"

# Disable TLS which is safe since our VM never gets attached to the outside world
export DOCKER_TLS="no"


# sync the clock
/etc/rc.d/ntpd &

# start cron
/etc/rc.d/crond

# TODO: move this (and the docker user creation&pwd out to its own over-rideable?))
if grep -q '^docker:' /etc/passwd; then
    # if we have the docker user, let's create the docker group
    /bin/addgroup -S docker
    # ... and add our docker user to it!
    /bin/addgroup docker docker

    #preload data from boot2docker-cli
    if [ -e "/var/lib/boot2docker/userdata.tar" ]; then
        tar xf /var/lib/boot2docker/userdata.tar -C /home/docker/ > /var/log/userdata.log 2>&1
        rm -f '/home/docker/boot2docker, please format-me'
        chown -R docker:staff /home/docker
    fi
fi

# Automount Shared Folders (VirtualBox, etc.); start VBox services
/etc/rc.d/vbox

# Mount BOINC shared folder 
echo "Mounting BOINC shared/..."
mkdir -p /root/shared 
mount -t vboxsf shared /root/shared/ 
mkdir -p /root/shared/results

# We won't need to SSH into this machine ever
# /etc/rc.d/SSHD

# Launch ACPId
/etc/rc.d/acpid

echo "-------------------"
date
#maybe the links will be up by now - trouble is, on some setups, they may never happen, so we can't just wait until they are
sleep 5
date
ip a
echo "-------------------"

# Allow local bootsync.sh customisation
if [ -e /var/lib/boot2docker/bootsync.sh ]; then
    /bin/sh /var/lib/boot2docker/bootsync.sh
    echo "------------------- ran /var/lib/boot2docker/bootsync.sh"
fi

# Launch Docker
/etc/rc.d/docker

# Allow local HD customisation
if [ -e /var/lib/boot2docker/bootlocal.sh ]; then
    /bin/sh /var/lib/boot2docker/bootlocal.sh > /var/log/bootlocal.log 2>&1 &
    echo "------------------- ran /var/lib/boot2docker/bootlocal.sh"
fi

# Execute automated_script
# disabled - this script was written assuming bash, which we no longer have.
#/etc/rc.d/automated_script.sh

# Only running this in VBox so don't need these:
# Run Hyper-V KVP Daemon
# if modprobe hv_utils &> /dev/null; then
#     /usr/sbin/hv_kvp_daemon
# fi

# Launch vmware-tools
# /etc/rc.d/vmtoolsd

# Launch xenserver-tools
# /etc/rc.d/xedaemon

# Load Parallels Tools daemon
# /etc/rc.d/prltoolsd


# If present run BOINC app
if [[ -f /root/shared/boinc_app ]]; then

    echo "Waiting for Docker daemon to start..."
    for i in $(seq 10); do sleep 1 && docker images && break; done

    # Run app
    echo "Running boinc_app..."
    (cd /root/shared && sh boinc_app)
    exit_status=$?
    echo "boinc_app exited (${exit_status})"

    # dump some logs on failure
    if [ $exit_status != 0 ]; then 
        echo "-------------------docker.log-------------------"
        tail -c 2k /var/log/docker.log
        echo "-------------------dmesg-------------------"
        dmesg | tail -c 2k
        echo "-------------------"
    fi

    # Tar up results and log files
    echo "Saving results..."
    (cd /root/shared/results && tar czvf /root/shared/results.tgz *)
    
    # Alert BOINC of the exit status
    echo $exit_status > /root/shared/completion_trigger_file

fi
