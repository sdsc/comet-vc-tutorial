#!/bin/bash

# Set up script for a basic Ubuntu 14.04 virtual cluster on Comet

cd $HOME

git clone https://github.com/sdsc/comet-vc-tutorial.git

APPS="tftpd-hpa isc-dhcp-server"

sudo apt-get install $APPS -y

# Set up PXE
# sudo ??

# config as root from now on
#
sudo su -

# NAT
sysctl -w net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
iptables -A FORWARD -i eth1 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
/etc/init.d/networking restart

# DHCP
apt-get install apache2 tftpd-hpa inetutils-inetd
echo 'INTERFACES="eth0"' >> /etc/default/isc-dhcp-server
service isc-dhcp-server restart

echo '
subnet 192.168.1.0 netmask 255.255.255.0 {
 range 192.168.1.100 192.168.1.200;
 option routers 192.168.1.254;
 option domain-name-servers 198.202.75.26;
}
' >> /etc/dhcp/dhcpd.conf

# PXEbooting for compute nodes
echo '
allow booting;
allow bootp;
option option-128 code 128 = string;
option option-129 code 129 = text;
next-server 192.168.1.254;
filename "pxelinux.0";
' >> /etc/dhcp/dhcpd.conf

echo '
RUN_DAEMON="yes"
OPTIONS="-l -s /var/lib/tftpboot"
' >> /etc/default/tftpd-hpa

echo '
tftp    dgram   udp    wait    root    /usr/sbin/in.tftpd /usr/sbin/in.tftpd -s /var/lib/tftpboot
' >> /etc/inetd.conf

/etc/init.d/tftpd-hpa restart

# firewall rules update
ufw allow 22/tcp
ufw allow from 192.168.1.0/24
ufw disable && ufw enable

# setting up key
ssh-keygen

echo '
PermitRootLogin without-password
PermitRootLogin yes
' >> /etc/ssh/sshd_config

service ssh restart

# add host keys to known_hosts, distribute private key to compute nodes
grep "^lease" /var/lib/dhcp/dhcpd.leases | sort | uniq | awk {'print $2'} > computes_ips
cat computes_ips | while read line; do ssh-keyscan -H $line >> ~/.ssh/known_hosts; done
cat computes_ips | while read line; do scp ~/.ssh/known_hosts root@$line:/root/.ssh/; done
cat computes_ips | while read line; do scp ~/.ssh/id_rsa root@$line:/root/.ssh/; done

# Deploy config
sudo cp -rf $HOME/comet-vc-tutorial/config/etc/* /etc/
sudo cp -rf $HOME/comet-vc-tutorial/config/var/* /var/
