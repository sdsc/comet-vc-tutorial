#!/bin/bash

# send shadow file entry for non-privileged user
for i in $(awk -F "," '{print $1}' $HOME/vcnodes_"$HOSTNAME".txt )
do
    ssh $i sed -i "/$SUDO_USER/d" /etc/shadow
    grep $SUDO_USER /etc/shadow | ssh $i "cat >> /etc/shadow"
done
