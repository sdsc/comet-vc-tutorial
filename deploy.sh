#!/bin/bash

# Set up script for a basic Ubuntu 14.04 virtual cluster on Comet
# Call using sudo sh deploy.sh

# Update system
apt-get update

# Define additional packages to install and services to restart
APPS="git apache2 tftpd-hpa isc-dhcp-server inetutils-inetd nfs-kernel-server"
SERVICES="networking isc-dhcp-server tftpd-hpa inetutils-inetd ssh nfs-kernel-server"

# Install needed packages
apt-get install $APPS -y

# Get the repo with the config files and examples
cd $HOME
git clone https://github.com/sdsc/comet-vc-tutorial.git
chown -R $USER:$USER $HOME/comet-vc-tutorial

# get netboot files
mount -t iso9660 /dev/cdrom /media/cdrom
cp -r /media/cdrom/install/netboot/* /var/lib/tftpboot/
chown -R nobody:nogroup /var/lib/tftpboot
umount /media/cdrom

# Deploy config
cp -rf $HOME/comet-vc-tutorial/config/etc/* /etc/
cp -rf $HOME/comet-vc-tutorial/config/var/* /var/

# configure the internal NIC and set iptables rules
iptables-restore < /etc/iptables.rules
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

# Restart services to get new configurations
sysctl -p
for i in $SERVICES
do
    /etc/init.d/$i restart
done

# Create configs requiring cluster MACs
python $HOME/comet-vc-tutorial/cmutil.py pxefile $HOSTNAME
python $HOME/comet-vc-tutorial/cmutil.py setkey
python $HOME/comet-vc-tutorial/cmutil.py setpassword
