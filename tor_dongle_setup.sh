#!/bin/bash
# This script installs the Debian image to the microSD card, and should
# be run on your laptop/desktop with the microSD card plugged in.

# License
# =======
#
# Copyright (C) 2014 Bob Mottram <bob@robotics.uk.to>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

# Version number of this script
VERSION="1.00"

# typically /dev/sdb or /dev/sdc, depending upon how
# many drives there are on your system
MICROSD_DRIVE=$1

# IP address of the router (gateway)
ROUTER_IP_ADDRESS="192.168.1.254"

# The fixed IP address of the Beaglebone Black on your local network
BBB_FIXED_IP_ADDRESS="192.168.7.2"

MICROSD_MOUNT_POINT="/media/$USER"

DEBIAN_FILE_NAME="debian-jessie-console-armhf-2014-08-13"

# Downloads for the Debian installer
DOWNLOAD_LINK1="https://rcn-ee.net/deb/rootfs/jessie/$DEBIAN_FILE_NAME.tar.xz"
DOWNLOAD_LINK2="http://ynezz.ibawizard.net/beagleboard/jessie/$DEBIAN_FILE_NAME.tar.xz"

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
if [ ! -f ~/freedombone/$DEBIAN_FILE_NAME.tar.xz ]; then
	wget $DOWNLOAD_LINK1
fi
if [ ! -f ~/freedombone/$DEBIAN_FILE_NAME.tar.xz ]; then
	# try another site
    wget $DOWNLOAD_LINK2
	if [ ! -f ~/freedombone/$DEBIAN_FILE_NAME.tar.xz ]; then
		echo 'The Debian installer could not be downloaded'
		exit 3
	fi
fi

echo 'Extracting files...'
tar xJf $DEBIAN_FILE_NAME.tar.xz
if [ ! -d ~/freedombone/$DEBIAN_FILE_NAME ]; then
	echo "Couldn't extract files"
	exit 4
fi
cd $DEBIAN_FILE_NAME
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
		exit 5
	fi
fi

sudo cp $MICROSD_MOUNT_POINT/BOOT/bbb-uEnv.txt $MICROSD_MOUNT_POINT/BOOT/uEnv.txt

sudo sed -i 's/nameserver.*/nameserver 213.73.91.35/g' $MICROSD_MOUNT_POINT/rootfs/etc/resolv.conf
sudo sed -i '/nameserver 213.73.91.35/a\nameserver 85.214.20.141' $MICROSD_MOUNT_POINT/rootfs/etc/resolv.conf

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
echo '    ./install-freedombone.sh [domain] [username] 0 tordongle'
exit 0
