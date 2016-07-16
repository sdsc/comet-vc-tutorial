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
echo -e "\n# The Infiniband network interface\nauto ib0" >> /etc/network/interfaces
grep "iface eth0" /etc/network/interfaces -A5 | \
    sed 's/iface eth0/iface ib0/g;s/10\.0\.0\./10\.0\.27\./g' >> /etc/network/interfaces

