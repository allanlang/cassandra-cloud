#!/bin/bash
# ONLY if /var/lib/cassandra does not exist should we format and then mount this volume!!!
if [ ! -d /var/lib/cassandra ]
then
    mkdir /var/lib/cassandra
    mkfs.ext4 -F /dev/disk/by-id/google-local-ssd-0
    mount -o discard,defaults /dev/disk/by-id/google-local-ssd-0 /var/lib/cassandra
    echo '/dev/disk/by-id/google-local-ssd-0 /var/lib/cassandra ext4 defaults 1 1' >> /etc/fstab
fi
