#!/bin/bash

# Set up script for a basic Ubuntu 14.04 virtual cluster on Comet

cd $HOME

git clone https://github.com/sdsc/comet-vc-tutorial.git

APPS="tftpd-hpa isc-dhcp-server"

sudo apt-get install $APPS -y

# Set up PXE
# sudo ??

# Deploy config
sudo cp -rf $HOME/comet-vc-tutorial/config/etc/* /etc/
sudo cp -rf $HOME/comet-vc-tutorial/config/var/* /var/
