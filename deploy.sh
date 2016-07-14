#!/bin/bash

# Set up script for a basic Ubuntu 14.04 virtual cluster on Comet

APPS="python-dev libffi-dev libssl-dev gcc git apache2 tftpd-hpa isc-dhcp-server inetutils-inetd"
SERVICES="networking isc-dhcp-server tftpd-hpa inetutils-inetd ssh"

apt-get install $APPS -y

cd $HOME
git clone https://github.com/sdsc/comet-vc-tutorial.git

# Deploy config
cp -rf $HOME/comet-vc-tutorial/config/etc/* /etc/
cp -rf $HOME/comet-vc-tutorial/config/var/* /var/

# configure the internal NIC
echo '
        pre-up iptables-restore < /etc/iptables.rules

auto eth0
iface eth0 inet static
        address 10.0.0.254
        netmask 255.255.255.0
        network 10.0.0.0
        broadcast 10.0.0.255
' >> /etc/network/interfaces
ifup eth0

sysctl -p
for i in $SERVICES
do
    /etc/init.d/$i restart
done

# install Cloudmesh
$HOME/comet-vc-tutorial/setup-cloudmesh-client-ubuntu-trusty.sh

# clean up any permissions issues caused by Cloudmesh install as root
chown -R $USER:$USER /home/$USER

python cmutil.py pxefile $HOSTNAME
python cmutil.py setkey
python cmutil.py setpassword
python cmutil.py setboot $HOSTNAME node1 net=true
