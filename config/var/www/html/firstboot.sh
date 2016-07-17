#!/bin/bash

FLAG="/var/log/firstboot.log"
if [ ! -f $FLAG ]; then
  # Add ib0 configuration
  egrep -q "^iface ib0" /etc/network/interfaces
  if [[ $? -ne 0 ]]; then

    PRIV_IP=$(ip addr show eth0 | awk '/ inet / {print $2}' | cut -d\/ -f1)
    IB_LQ=$(echo $PRIV_IP | cut -d\. -f4)
    IB_IP="10.0.27.${IB_LQ}"

    cat >> /etc/network/interfaces <<EOT

# The Infiniband interface
auto ib0
iface ib0 inet static
    address ${IB_IP}
    netmask 255.255.255.0
    network 10.0.27.0
    broadcast 10.0.27.255
    post-up echo connected > /sys/class/net/ib0/mode
    post-up /sbin/ifconfig ib0 mtu 4092

EOT

    ifup ib0
    touch $FLAG
  fi
fi

exit 0
