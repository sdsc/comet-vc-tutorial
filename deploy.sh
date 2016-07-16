#!/bin/bash

# Set up script for a basic Ubuntu 14.04 virtual cluster on Comet
# Call using sudo sh deploy.sh

# Update system
apt-get update -y
apt-get upgrade -y

# Define additional packages to install and services to restart
APPS="git apache2 tftpd-hpa isc-dhcp-server inetutils-inetd nfs-kernel-server emacs24-nox"
SERVICES="networking isc-dhcp-server tftpd-hpa inetutils-inetd ssh nfs-kernel-server"

# Install needed packages
apt-get install $APPS -y

# Get the repo with the config files and examples
cd $HOME
git clone https://github.com/sdsc/comet-vc-tutorial.git
chown -R $SUDO_USER:$SUDO_USER $HOME/comet-vc-tutorial

# get netboot files
cd /var/lib/tftpboot
wget http://us.archive.ubuntu.com/ubuntu/dists/trusty/main/installer-amd64/current/images/netboot/netboot.tar.gz
tar -zxf netboot.tar.gz
cd $HOME

# create local repo
mount -t iso9660 /dev/cdrom /media/cdrom
mkdir /var/www/html/ubuntu
cp -r /media/cdrom/* /var/www/html/ubuntu/
umount /media/cdrom

# Deploy config
cp -rf $HOME/comet-vc-tutorial/config/etc/* /etc/
cp -rf $HOME/comet-vc-tutorial/config/var/* /var/

# Modify hosts config
PUBIP=$(ip addr show eth1 | awk '/ inet / {print $2}' | cut -d\/ -f1)
for f in /etc/hosts /var/www/html/hosts; do
    sed -i 's,HOSTNAME,'"${HOSTNAME}"',g;s,PUBIP,'"${PUBIP}"',' $f
done

# configure the internal NIC and set iptables rules
iptables-restore < /etc/iptables.rules
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

# Add priviledged user creation to postscript.sh
EXTRA_GROUPS=$(grep $SUDO_USER /etc/group | cut -d: -f1 | grep -v $SUDO_USER | egrep -v "lpadmin|sambashare" | tr '\n' ',' | sed 's/,$/\n/g')
cat >> /var/www/html/postscript.sh <<End-of-message

# Add privileged user
groupadd -g $SUDO_GID $SUDO_USER
useradd -c "$SUDO_USER,,," -g $SUDO_GID -G $EXTRA_GROUPS -M -s /bin/bash -u $SUDO_UID $SUDO_USER
End-of-message

exit 0
