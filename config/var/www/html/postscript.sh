#!/bin/sh
# Install ssh key
cd /root
mkdir --mode=700 .ssh
cat >> .ssh/authorized_keys << "PUBLIC_KEY"
$PUBLICKEY
PUBLIC_KEY
chmod 600 .ssh/authorized_keys
sed -i '/home/d' /etc/fstab
echo '10.0.0.254:/home /home nfs defaults 0 0' >> /etc/fstab
#sed -i 's/ens3/eth0/' /etc/network/interfaces
echo 'mlx4_ib
ib_umad
ib_ipoib
ib_cm
ib_ucm
rdma_ucm' >> /etc/modules

#sed -i '/^ubuntu/d' /etc/group
#echo 'ubuntu:x:1001:' >> /etc/group

echo 'btl_openib_warn_no_device_params_found = 0' >>  /etc/openmpi/openmpi-mca-params.conf

echo  '
*   -   memlock     -1
*   -   stack       -1
*   -   nofile      8192' >> /etc/security/limits.conf

wget -O /etc/hosts http://10.0.0.254/hosts

# Create ib0 definition
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
