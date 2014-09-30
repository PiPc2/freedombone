#!/bin/bash
# This script installs the Debian image to the microSD card, and should
# be run on your laptop/desktop with the microSD card plugged in.

# typically /dev/sdb or /dev/sdc, depending upon how
# many drives there are on your system
MICROSD_DRIVE=$1

# IP address of the router (gateway)
ROUTER_IP_ADDRESS="192.168.2.1"

# The fixed IP address of the Beaglebone Black on your local network
BBB_FIXED_IP_ADDRESS="192.168.2.200"

MICROSD_MOUNT_POINT="/media/$USER"

# Downloads for the Debian installer
DOWNLOAD_LINK1="https://rcn-ee.net/deb/rootfs/jessie/debian-jessie-console-armhf-2014-08-13.tar.xz"
DOWNLOAD_LINK2="http://ynezz.ibawizard.net/beagleboard/jessie/debian-jessie-console-armhf-2014-08-13.tar.xz"


if [ ! MICROSD_DRIVE ]; then
	echo 'You need to specify a drive for the connected microSD.'
	echo 'This can most easily be found by removing the microSD, then'
	echo 'running:'
	echo ''
	echo '  ls /dev/sd*'
	echo ''
	echo 'Then plugging the microSD back in and entering the same command again'
	exit 1
fi

if [ ! -b ${MICROSD_DRIVE}1 ]; then
	echo "The microSD drive could not be found at ${MICROSD_DRIVE}1"
	exit 2
fi

if [ ! -d ~/freedombone ]; then
	mkdir ~/freedombone
fi
cd ~/freedombone
if [ ! -f ~/freedombone/debian-jessie-console-armhf-2014-08-13.tar.xz ]; then
	wget $DOWNLOAD_LINK1
fi
if [ ! -f ~/freedombone/debian-jessie-console-armhf-2014-08-13.tar.xz ]; then
	# try another site
    wget $DOWNLOAD_LINK2
	if [ ! -f ~/freedombone/debian-jessie-console-armhf-2014-08-13.tar.xz ]; then
		echo 'The Debian installer could not be downloaded'
		exit 3
	fi
fi
sudo ./setup_sdcard.sh --mmc $MICROSD_DRIVE --dtb beaglebone

echo ''
echo ''
read -p "Eject the microSD card, re-insert it and wait a minute for it to mount, then press any key to continue... " -n1 -s

if [ ! -b ${MICROSD_DRIVE}1 ]; then
	echo ''
	echo "The microSD drive could not be found at ${MICROSD_DRIVE}1"
	read -p "Wait for the drive to mount then press any key... " -n1 -s
	if [ ! -b ${MICROSD_DRIVE}1 ]; then
		echo "microSD drive not found at ${MICROSD_DRIVE}1"
		exit 4
	fi
fi

sudo cp $MICROSD_MOUNT_POINT/BOOT/bbb-uEnv.txt $MICROSD_MOUNT_POINT/BOOT/uEnv.txt

sudo sed -i '/iface eth0 inet dhcp/a\iface eth0 inet static' $MICROSD_MOUNT_POINT/rootfs/etc/network/interfaces
sudo sed -i '/iface eth0 inet static/a\    dns-nameservers 213.73.91.35 85.214.20.141' $MICROSD_MOUNT_POINT/rootfs/etc/network/interfaces
sudo sed -i "/iface eth0 inet static/a\    gateway $ROUTER_IP_ADDRESS" $MICROSD_MOUNT_POINT/rootfs/etc/network/interfaces
sudo sed -i '/iface eth0 inet static/a\    netmask 255.255.255.0' $MICROSD_MOUNT_POINT/rootfs/etc/network/interfaces
sudo sed -i "/iface eth0 inet static/a\    address $BBB_FIXED_IP_ADDRESS" $MICROSD_MOUNT_POINT/rootfs/etc/network/interfaces
sudo sed -i '/iface usb0 inet static/,/    gateway 192.168.7.1/ s/^/#/' $MICROSD_MOUNT_POINT/rootfs/etc/network/interfaces

sudo sed -i "s/nameserver.*/nameserver 213.73.91.35" $MICROSD_MOUNT_POINT/rootfs/etc/resolv.conf
sudo echo 'nameserver 85.214.20.141' >> $MICROSD_MOUNT_POINT/rootfs/etc/resolv.conf

sync

clear
echo '*** Initial microSD card setup is complete ***'
echo ''
echo 'The microSD card can now be removed and inserted into the Beaglebone Black.'
echo 'Once the Beaglebone has booted then you can log in with:'
echo ''
echo "    ssh debian@$BBB_FIXED_IP_ADDRESS"
echo ''
echo 'The password is "temppwd". You can then become the root user by typing:'
echo ''
echo '    su'
echo ''
echo 'Using the password "root". Change the root user password by typing:'
echo ''
echo '    passwd'
echo ''
echo 'Then create a user for the system with:'
echo ''
echo '    adduser [username]'
echo ''
echo 'Enter the command "exit" a couple of times to get back to your main system'
echo 'then log back in as the user you just created with:'
echo ''
echo '    ssh [username]@$BBB_FIXED_IP_ADDRESS'
echo ''
echo 'and use the "su" command to become the root user again. You can then load'
echo 'the freedombone main installation script with:'
echo ''
echo '    apt-get -y install git'
echo '    git clone https://github.com/bashrc/freedombone.git'
echo '    cd freedombone'
echo ''
echo 'Finally you can run the freedombone installer with:'
echo ''
echo '    ./install-freedombone.sh [domain] [username] [subdomain code] [variant]'
exit 0
