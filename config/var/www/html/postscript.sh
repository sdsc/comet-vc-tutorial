#!/bin/sh
# Install ssh key
cd /home/ubuntu
mkdir --mode=700 .ssh
cat >> .ssh/authorized_keys << "PUBLIC_KEY"
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDfh9Fcu2scXguBqwuO1XHM5+FuMq7ZFPQK9PrDvKOARJpDlTTFDRF89vlLKeuVFYFA4gnK97MHE5hAIFmjmY9Q5AzPOyTbREaDVTDK/m2lndr4hCWusQJsSF0uMxAiI9fzsgzDquFVKUASKzUb/6FY5UqD8RjNOiwAmno10a3r/A0H8T9BEcDMhPWJfeTQbqtyL5DgBTV/kwO8KcNahLOBjBbwaiqPojeWsoFaVNOpS6vM2sVEpEAmgeeyQ8214eE51j/8tXIBGRExlmMW0owly1QzcRt78YkAO+dbO+Nl3+TLktbIZmLo5OLw1ze2kiecfBz4T8dxwuytc+qxjxK9 iucomet@vc4
PUBLIC_KEY
chown -R ubuntu:ubuntu .ssh
chmod 600 .ssh/authorized_keys
sed -i '/home/d' /etc/fstab
echo '192.168.1.254:/home /home nfs defaults 0 0' >> /etc/fstab
sed -i 's/ens3/eth0/' /etc/network/interfaces
echo 'mlx4_ib
ib_umad
ib_ipoib
ib_cm
ib_ucm
rdma_ucm' >> /etc/modules
echo '
#auto ib0
#iface ib0 inet static
#    address 10.27.0.1
#    netmask 255.255.255.0
#    network 10.27.0.0
#    broadcast 10.27.0.255' >> /etc/network/interfaces

sed -i '/^ubuntu/d' /etc/group
echo 'ubuntu:x:1001:' >> /etc/group

echo 'btl_openib_warn_no_device_params_found = 0' >>  /etc/openmpi/openmpi-mca-params.conf

echo  '
*   -   memlock     -1
*   -   stack       -1
*   -   nofile      8192' >> /etc/security/limits.conf
