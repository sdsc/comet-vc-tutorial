#!/bin/bash

# Set up script for a basic Ubuntu 14.04 virtual cluster on Comet

APPS="git apache2 tftpd-hpa isc-dhcp-server inetutils-inetd"

apt-get install $APPS -y

cd $HOME
git clone https://github.com/sdsc/comet-vc-tutorial.git

# configure the internal NIC
echo '
auto eth0
iface eth0 inet static
        address 10.0.0.254
        netmask 255.255.255.0
        network 10.0.0.0
        broadcast 10.0.0.255
' >> /etc/network/interfaces
ifup eth0

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
subnet 10.0.0.0 netmask 255.255.255.0 {
 range 10.0.0.100 10.0.0.200;
 option routers 10.0.0.254;
 option domain-name-servers 198.202.75.26;
}
' >> /etc/dhcp/dhcpd.conf

# PXEbooting for compute nodes
echo '
allow booting;
allow bootp;
option option-128 code 128 = string;
option option-129 code 129 = text;
next-server 10.0.0.254;
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
ufw allow from 10.0.0.0/24
ufw disable && ufw enable
service ssh restart

# Deploy config
cp -rf $HOME/comet-vc-tutorial/config/etc/* /etc/
cp -rf $HOME/comet-vc-tutorial/config/var/* /var/

python cmutil.py pxefile $HOSTNAME
python cmutil.py setkey
python cmutil.py setpassword
python cmutil.py setboot $HOSTNAME node1 net=true
