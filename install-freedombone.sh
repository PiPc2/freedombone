#!/bin/bash
# Freedombone install script intended for use with Debian Jessie
#
# Note on dynamic dns
# ===================
#
# I'm not particularly trying to promote freedns.afraid.org
# as a service, it just happens to be a dynamic DNS system which
# provides free (as in beer) accounts, and I'm trying to make the
# process of setting up a working server as trivial as possible.
# Other dynamic DNS systems are available, and if you're using
# something different then comment out the section within
# argument_checks and the call to dynamic_dns_freedns.
#
# Prerequisites
# =============
#
# cd ~/
# wget http://freedombone.uk.to/debian-jessie-console-armhf-2014-08-13.tar.xz
#
# Verify it.
#
# sha256sum debian-jessie-console-armhf-2014-08-13.tar.xz
# fc225cfb3c2dfad92cccafa97e92c3cd3db9d94f4771af8da364ef59609f43de
#
# Uncompress it.
#
# tar xJf debian-jessie-console-armhf-2014-08-13.tar.xz
# cd debian-jessie-console-armhf-2014-08-13
#
# sudo apt-get install u-boot-tools dosfstools git-core kpartx wget parted
# sudo ./setup_sdcard.sh --mmc /dev/sdX --dtb beaglebone
#
# When finished eject the micrtoSD then reinsert it
#
# sudo cp /media/$USER/BOOT/bbb-uEnv.txt /media/$USER/BOOT/uEnv.txt
# sync
#
# Eject microSD, insert into BBB, attach USB cable between BBB and laptop.
# On Ubuntu wait until you see the "connected" message.
#
# ssh-keygen -f "/home/$USER/.ssh/known_hosts" -R 192.168.7.2
# ssh debian@192.168.7.2 (password "temppwd")
# su (password "root")
# passwd
# adduser $MY_USERNAME
# sed -i '/iface eth0 inet dhcp/a\iface eth0 inet static' /etc/network/interfaces
# sed -i '/iface eth0 inet static/a\    dns-nameservers 213.73.91.35 85.214.20.141' /etc/network/interfaces
# sed -i "/iface eth0 inet static/a\    gateway $MY_ROUTER_IP" /etc/network/interfaces
# sed -i '/iface eth0 inet static/a\    netmask 255.255.255.0' /etc/network/interfaces
# sed -i "/iface eth0 inet static/a\    address $MY_BBB_STATIC_IP" /etc/network/interfaces
# sed -i '/iface usb0 inet static/,/    gateway 192.168.7.1/ s/^/#/' /etc/network/interfaces
# shutdown now
#
# Connect BBB to router
#
# scp install-freedombone.sh $MY_USERNAME@$MY_BBB_STATIC_IP:/home/$MY_USERNAME
# ssh $MY_USERNAME@$MY_BBB_STATIC_IP
# su
# ./install-freedombone.sh [DOMAIN_NAME] [MY_USERNAME]

DOMAIN_NAME=$1
MY_USERNAME=$2
FREEDNS_SUBDOMAIN_CODE=$3
SYSTEM_TYPE=$4

# Different system variants which may be specified within
# the SYSTEM_TYPE option
VARIANT_WRITER="writer"
VARIANT_CLOUD="cloud"
VARIANT_CHAT="chat"
VARIANT_MAILBOX="mailbox"
VARIANT_SOCIAL="social"

SSH_PORT=2222
KERNEL_VERSION="v3.15.10-bone7"
USE_HWRNG="yes"
INSTALLED_WITHIN_DOCKER="no"

# If you want to run an encrypted mailing list specify its name here.
# There should be no spaces in the name
PRIVATE_MAILING_LIST=

# Domain name or freedns subdomain for Owncloud installation
OWNCLOUD_DOMAIN_NAME=
# Freedns dynamic dns code for owncloud
OWNCLOUD_FREEDNS_SUBDOMAIN_CODE=
OWNCLOUD_ARCHIVE="owncloud-7.0.2.tar.bz2"
OWNCLOUD_DOWNLOAD="https://download.owncloud.org/community/$OWNCLOUD_ARCHIVE"
OWNCLOUD_HASH="ea07124a1b9632aa5227240d655e4d84967fb6dd49e4a16d3207d6179d031a3a"

# Domain name or freedns subdomain for your wiki
WIKI_FREEDNS_SUBDOMAIN_CODE=
WIKI_DOMAIN_NAME=
WIKI_ARCHIVE="dokuwiki-stable.tgz"
WIKI_DOWNLOAD="http://download.dokuwiki.org/src/dokuwiki/$WIKI_ARCHIVE"
WIKI_HASH="a0e79986b87b2744421ce3c33b43a21f296deadd81b1789c25fa4bb095e8e470"

# see https://www.dokuwiki.org/template:mnml-blog
# https://andreashaerter.com/tmp/downloads/dokuwiki-template-mnml-blog/CHECKSUMS.asc
WIKI_MNML_BLOG_ADDON_ARCHIVE="mnml-blog.tar.gz"
WIKI_MNML_BLOG_ADDON="https://andreashaerter.com/downloads/dokuwiki-template-mnml-blog/latest"
WIKI_MNML_BLOG_ADDON_HASH="428c280d09ee14326fef5cd6f6772ecfcd532f7b6779cd992ff79a97381cf39f"

# see https://www.dokuwiki.org/plugin:blogtng
WIKI_BLOGTNG_ADDON_NAME="dokufreaks-plugin-blogtng-93a3fec"
WIKI_BLOGTNG_ADDON_ARCHIVE="$WIKI_BLOGTNG_ADDON_NAME.zip"
WIKI_BLOGTNG_ADDON="https://github.com/dokufreaks/plugin-blogtng/zipball/master"
WIKI_BLOGTNMG_ADDON_HASH="212b3ad918fdc92b2d49ef5d36bc9e086eab27532931ba6b87e05f35fd402a27"

GPG_KEYSERVER="hkp://keys.gnupg.net"

# optionally you can provide your exported GPG key pair here
# Note that the private key file will be deleted after use
# If these are unspecified then a new GPG key will be created
MY_GPG_PUBLIC_KEY=
MY_GPG_PRIVATE_KEY=

# If you have existing mail within a Maildir
# you can specify the directory here and the files
# will be imported
IMPORT_MAILDIR=

# The Debian package repository to use.
DEBIAN_REPO="ftp.de.debian.org"

DEBIAN_VERSION="jessie"

# Directory where source code is downloaded and compiled
INSTALL_DIR=$HOME/build

# device name for an attached usb drive
USB_DRIVE=/dev/sda1

# memory limit for php in MB
MAX_PHP_MEMORY="32"

export DEBIAN_FRONTEND=noninteractive

# File which keeps track of what has already been installed
COMPLETION_FILE=$HOME/freedombone-completed.txt
if [ ! -f $COMPLETION_FILE ]; then
    touch $COMPLETION_FILE
fi

function show_help {
  echo ''
  echo './install-freedombone.sh [domain] [username] [subdomain code] [system type]'
  echo ''
  echo 'domain'
  echo '------'
  echo 'This is your domain name or freedns subdomain.'
  echo ''
  echo 'username'
  echo '--------'
  echo ''
  echo 'This will be your username on the system. It should be all'
  echo 'lower case and contain no spaces'
  echo ''
  echo 'subdomain code'
  echo '--------------'
  echo 'This is the freedns dynamic DNS code for your subdomain.'
  echo "To find it from https://freedns.afraid.org select 'Dynamic DNS',"
  echo "then 'quick cron example' and copy the code located between "
  echo "'?' and '=='."
  echo ''
  echo 'system type'
  echo '-----------'
  echo 'This can either be blank if you wish to install the full system,'
  echo "or for more specialised variants you can specify '$VARIANT_MAILBOX', '$VARIANT_CLOUD',"
  echo "'$VARIANT_CHAT', '$VARIANT_SOCIAL' or '$VARIANT_WRITER'"
  echo ''
}

function argument_checks {
  if [ ! -d /home/$MY_USERNAME ]; then
      echo "There is no user '$MY_USERNAME' on the system. Use 'adduser $MY_USERNAME' to create the user."
      exit 1
  fi
  if [ ! $DOMAIN_NAME ]; then
      show_help
      exit 2
  fi
  if [ ! $MY_USERNAME ]; then
      show_help
      exit 3
  fi
  if [ ! $FREEDNS_SUBDOMAIN_CODE ]; then
      show_help
      exit 4
  fi
}

function change_login_message {
  if grep -Fxq "change_login_message" $COMPLETION_FILE; then
      return
  fi
  echo '' > /etc/motd
  echo ".---.                  .              .                   " >> /etc/motd
  echo "|                      |              |                   " >> /etc/motd
  echo "|--- .--. .-.  .-.  .-.|  .-. .--.--. |.-.  .-. .--.  .-. " >> /etc/motd
  echo "|    |   (.-' (.-' (   | (   )|  |  | |   )(   )|  | (.-' " >> /etc/motd
  echo "'    '     --'  --'  -' -  -' '  '   -' -'   -' '   -  --'" >> /etc/motd

  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" ]]; then
      echo '              .  .   .  .     .          ' >> /etc/motd
      echo '               \  \ /  /   o _|_         ' >> /etc/motd
      echo '                \  \  /.--..  |  .-. .--.' >> /etc/motd
      echo "                 \/ \/ |   |  | (.-' |   " >> /etc/motd
      echo "                  ' '  ' -'  - -' --''   " >> /etc/motd
  fi

  if [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" ]]; then
      echo '                  .--..             . ' >> /etc/motd
      echo '                 :    |             | ' >> /etc/motd
      echo '                 |    | .-. .  . .-.| ' >> /etc/motd
      echo '                 :    |(   )|  |(   | ' >> /etc/motd
      echo "                   --' - -'  -- - -' -" >> /etc/motd
  fi

  if [[ $SYSTEM_TYPE == "$VARIANT_CHAT" ]]; then
      echo '                  .--..         .   ' >> /etc/motd
      echo '                 :    |        _|_  ' >> /etc/motd
      echo '                 |    |--. .-.  |   ' >> /etc/motd
      echo '                 :    |  |(   ) |   ' >> /etc/motd
      echo "                   --''   - -' - -' " >> /etc/motd
  fi

  if [[ $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      echo '               .-.                    .  ' >> /etc/motd
      echo '              (   )           o       |  ' >> /etc/motd
      echo '                -.  .-.  .-.  .  .-.  |  ' >> /etc/motd
      echo '              (   )(   )(     | (   ) |  ' >> /etc/motd
      echo "                -'   -'   -'-'  - -' - - " >> /etc/motd
  fi

  if [[ $SYSTEM_TYPE == "email" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" ]]; then
      echo '             .    .           . .              ' >> /etc/motd
      echo '             |\  /|        o  | |              ' >> /etc/motd
      echo '             | \/ | .-.    .  | |.-.  .-.-. ,- ' >> /etc/motd
      echo '             |    |(   )   |  | |   )(   ) :   ' >> /etc/motd
      echo '             '    '  -' --'  - -' -'   -'-'  - ' >> /etc/motd
  fi

  echo '' >> /etc/motd
  echo '                  Freedom in the Cloud' >> /etc/motd
  echo '' >> /etc/motd
  echo 'change_login_message' >> $COMPLETION_FILE
}

function search_for_attached_usb_drive {
  # If a USB drive is attached then search for email,
  # gpg, ssh keys and emacs configuration
  if grep -Fxq "search_for_attached_usb_drive" $COMPLETION_FILE; then
      return
  fi
  if [ -b $USB_DRIVE ]; then
      if [ ! -d /media/usb ]; then
          echo 'Mounting USB drive'
          mkdir /media/usb
          mount $USB_DRIVE /media/usb
      fi
      if ! [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
          if [ -d /media/usb/Maildir ]; then
              echo 'Maildir found on USB drive'
              IMPORT_MAILDIR=/media/usb/Maildir
          fi
          if [ -d /media/usb/.gnupg ]; then
              echo 'Importing GPG keyring'
              cp -r /media/usb/.gnupg /home/$MY_USERNAME
              chown -R $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/.gnupg
              if [ -f /home/$MY_USERNAME/.gnupg/secring.gpg ]; then
                  shred -zu /media/usb/.gnupg/secring.gpg
                  shred -zu /media/usb/.gnupg/random_seed
                  shred -zu /media/usb/.gnupg/trustdb.gpg
                  rm -rf /media/usb/.gnupg
              else
                  echo 'GPG files did not copy'
                  exit 7
              fi
          fi

          if [ -f /media/usb/private_key.gpg ]; then
              echo 'GPG private key found on USB drive'
              MY_GPG_PRIVATE_KEY=/media/usb/private_key.gpg
          fi
          if [ -f /media/usb/public_key.gpg ]; then
              echo 'GPG public key found on USB drive'
              MY_GPG_PUBLIC_KEY=/media/usb/public_key.gpg
          fi
      fi
      if [ -d /media/usb/.ssh ]; then
          echo 'Importing ssh keys'
          cp -r /media/usb/.ssh /home/$MY_USERNAME
          chown -R $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/.ssh
          # for security delete the ssh keys from the usb drive
          if [ -f /home/$MY_USERNAME/.ssh/id_rsa ]; then
              shred -zu /media/usb/.ssh/id_rsa
              shred -zu /media/usb/.ssh/id_rsa.pub
              shred -zu /media/usb/.ssh/known_hosts
              rm -rf /media/usb/.ssh
          else
              echo 'ssh files did not copy'
              exit 8
          fi
      fi
      if [ -f /media/usb/.emacs ]; then
          echo 'Importing .emacs file'
          cp -f /media/usb/.emacs /home/$MY_USERNAME/.emacs
          chown $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/.emacs
      fi
      if [ -d /media/usb/.emacs.d ]; then
          echo 'Importing .emacs.d directory'
          cp -r /media/usb/.emacs.d /home/$MY_USERNAME
          chown -R $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/.emacs.d
      fi
      if [ -d /media/usb/personal ]; then
          echo 'Importing personal directory'
          cp -r /media/usb/personal /home/$MY_USERNAME
          chown -R $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/personal
      fi
  else
      if [ -d /media/usb ]; then
          umount /media/usb
          rm -rf /media/usb
      fi
      echo 'No USB drive attached'
  fi
  echo 'search_for_attached_usb_drive' >> $COMPLETION_FILE
}

function remove_proprietary_repos {
  if grep -Fxq "remove_proprietary_repos" $COMPLETION_FILE; then
      return
  fi
  sed -i 's/ non-free//g' /etc/apt/sources.list
  echo 'remove_proprietary_repos' >> $COMPLETION_FILE
}

function change_debian_repos {
  if grep -Fxq "change_debian_repos" $COMPLETION_FILE; then
      return
  fi
  rm -rf /var/lib/apt/lists/*
  apt-get clean
  sed -i "s/ftp.us.debian.org/$DEBIAN_REPO/g" /etc/apt/sources.list

  # ensure that there is a security repo
  if ! grep -q "security" /etc/apt/sources.list; then
      if grep -q "jessie" /etc/apt/sources.list; then
          echo "deb http://security.debian.org/ jessie/updates main contrib" >> /etc/apt/sources.list
          echo "#deb-src http://security.debian.org/ jessie/updates main contrib" >> /etc/apt/sources.list
      else
          if grep -q "wheezy" /etc/apt/sources.list; then
              echo "deb http://security.debian.org/ wheezy/updates main contrib" >> /etc/apt/sources.list
              echo "#deb-src http://security.debian.org/ wheezy/updates main contrib" >> /etc/apt/sources.list
          fi
      fi
  fi

  apt-get update
  apt-get -y --force-yes install apt-transport-https
  echo 'change_debian_repos' >> $COMPLETION_FILE
}

function initial_setup {
  if grep -Fxq "initial_setup" $COMPLETION_FILE; then
      return
  fi
  apt-get -y remove --purge apache*
  apt-get -y dist-upgrade
  apt-get -y install ca-certificates emacs24
  echo 'initial_setup' >> $COMPLETION_FILE
}

function install_editor {
  if grep -Fxq "install_editor" $COMPLETION_FILE; then
      return
  fi
  update-alternatives --set editor /usr/bin/emacs24
  echo 'install_editor' >> $COMPLETION_FILE
}

function enable_backports {
  if grep -Fxq "enable_backports" $COMPLETION_FILE; then
      return
  fi
  if ! grep -Fxq "deb http://$DEBIAN_REPO/debian jessie-backports main" /etc/apt/sources.list; then
    echo "deb http://$DEBIAN_REPO/debian jessie-backports main" >> /etc/apt/sources.list
  fi
  echo 'enable_backports' >> $COMPLETION_FILE
}

function update_the_kernel {
  if grep -Fxq "update_the_kernel" $COMPLETION_FILE; then
      return
  fi
  if [[ $INSTALLED_WITHIN_DOCKER == "yes" ]]; then
      return
  fi
  cd /opt/scripts/tools
  ./update_kernel.sh --kernel $KERNEL_VERSION
  echo 'update_the_kernel' >> $COMPLETION_FILE
}

function enable_zram {
  if grep -Fxq "enable_zram" $COMPLETION_FILE; then
      return
  fi
  if [[ $INSTALLED_WITHIN_DOCKER == "yes" ]]; then
      return
  fi
  if ! grep -q "options zram num_devices=1" /etc/modprobe.d/zram.conf; then
      echo 'options zram num_devices=1' >> /etc/modprobe.d/zram.conf
  fi
  echo '#!/bin/bash' > /etc/init.d/zram
  echo '### BEGIN INIT INFO' >> /etc/init.d/zram
  echo '# Provides: zram' >> /etc/init.d/zram
  echo '# Required-Start:' >> /etc/init.d/zram
  echo '# Required-Stop:' >> /etc/init.d/zram
  echo '# Default-Start: 2 3 4 5' >> /etc/init.d/zram
  echo '# Default-Stop: 0 1 6' >> /etc/init.d/zram
  echo '# Short-Description: Increased Performance In Linux With zRam (Virtual Swap Compressed in RAM)' >> /etc/init.d/zram
  echo '# Description: Adapted from systemd scripts at https://github.com/mystilleef/FedoraZram' >> /etc/init.d/zram
  echo '### END INIT INFO' >> /etc/init.d/zram
  echo 'start() {' >> /etc/init.d/zram
  echo '    # get the number of CPUs' >> /etc/init.d/zram
  echo '    num_cpus=$(grep -c processor /proc/cpuinfo)' >> /etc/init.d/zram
  echo '    # if something goes wrong, assume we have 1' >> /etc/init.d/zram
  echo '    [ "$num_cpus" != 0 ] || num_cpus=1' >> /etc/init.d/zram
  echo '    # set decremented number of CPUs' >> /etc/init.d/zram
  echo '    decr_num_cpus=$((num_cpus - 1))' >> /etc/init.d/zram
  echo '    # get the amount of memory in the machine' >> /etc/init.d/zram
  echo '    mem_total_kb=$(grep MemTotal /proc/meminfo | grep -E --only-matching "[[:digit:]]+")' >> /etc/init.d/zram
  echo '    mem_total=$((mem_total_kb * 1024))' >> /etc/init.d/zram
  echo '    # load dependency modules' >> /etc/init.d/zram
  echo '    modprobe zram num_devices=$num_cpus' >> /etc/init.d/zram
  echo '    # initialize the devices' >> /etc/init.d/zram
  echo '    for i in $(seq 0 $decr_num_cpus); do' >> /etc/init.d/zram
  echo '      echo $((mem_total / num_cpus)) > /sys/block/zram$i/disksize' >> /etc/init.d/zram
  echo '    done' >> /etc/init.d/zram
  echo '    # Creating swap filesystems' >> /etc/init.d/zram
  echo '    for i in $(seq 0 $decr_num_cpus); do' >> /etc/init.d/zram
  echo '      mkswap /dev/zram$i' >> /etc/init.d/zram
  echo '    done' >> /etc/init.d/zram
  echo '    # Switch the swaps on' >> /etc/init.d/zram
  echo '    for i in $(seq 0 $decr_num_cpus); do' >> /etc/init.d/zram
  echo '      swapon -p 100 /dev/zram$i' >> /etc/init.d/zram
  echo '    done' >> /etc/init.d/zram
  echo '}' >> /etc/init.d/zram
  echo 'stop() {' >> /etc/init.d/zram
  echo '    # get the number of CPUs' >> /etc/init.d/zram
  echo '    num_cpus=$(grep -c processor /proc/cpuinfo)' >> /etc/init.d/zram
  echo '    # set decremented number of CPUs' >> /etc/init.d/zram
  echo '    decr_num_cpus=$((num_cpus - 1))' >> /etc/init.d/zram
  echo '    # Switching off swap' >> /etc/init.d/zram
  echo '    for i in $(seq 0 $decr_num_cpus); do' >> /etc/init.d/zram
  echo '      if [ "$(grep /dev/zram$i /proc/swaps)" != "" ]; then' >> /etc/init.d/zram
  echo '        swapoff /dev/zram$i' >> /etc/init.d/zram
  echo '        sleep 1' >> /etc/init.d/zram
  echo '      fi' >> /etc/init.d/zram
  echo '    done' >> /etc/init.d/zram
  echo '    sleep 1' >> /etc/init.d/zram
  echo '    rmmod zram' >> /etc/init.d/zram
  echo '}' >> /etc/init.d/zram
  echo 'case "$1" in' >> /etc/init.d/zram
  echo '    start)' >> /etc/init.d/zram
  echo '        start' >> /etc/init.d/zram
  echo '        ;;' >> /etc/init.d/zram
  echo '    stop)' >> /etc/init.d/zram
  echo '        stop' >> /etc/init.d/zram
  echo '        ;;' >> /etc/init.d/zram
  echo '    restart)' >> /etc/init.d/zram
  echo '        stop' >> /etc/init.d/zram
  echo '        sleep 3' >> /etc/init.d/zram
  echo '        start' >> /etc/init.d/zram
  echo '        ;;' >> /etc/init.d/zram
  echo '    *)' >> /etc/init.d/zram
  echo '        echo "Usage: $0 {start|stop|restart}"' >> /etc/init.d/zram
  echo '        RETVAL=1' >> /etc/init.d/zram
  echo 'esac' >> /etc/init.d/zram
  echo 'exit $RETVAL' >> /etc/init.d/zram
  chmod +x /etc/init.d/zram
  update-rc.d zram defaults
  echo 'enable_zram' >> $COMPLETION_FILE
}

function random_number_generator {
  if grep -Fxq "random_number_generator" $COMPLETION_FILE; then
      return
  fi
  if [[ $INSTALLED_WITHIN_DOCKER == "yes" ]]; then
      # it is assumed that docker uses the random number
      # generator of the host system
      return
  fi
  if [[ $USE_HWRNG == "yes" ]]; then
    apt-get -y --force-yes install rng-tools
    sed -i 's|#HRNGDEVICE=/dev/hwrng|HRNGDEVICE=/dev/hwrng|g' /etc/default/rng-tools
  else
    apt-get -y --force-yes install haveged
  fi
  echo 'random_number_generator' >> $COMPLETION_FILE
}

function configure_ssh {
  if grep -Fxq "configure_ssh" $COMPLETION_FILE; then
      return
  fi
  sed -i "s/Port 22/Port $SSH_PORT/g" /etc/ssh/sshd_config
  sed -i 's/PermitRootLogin without-password/PermitRootLogin no/g' /etc/ssh/sshd_config
  sed -i 's/X11Forwarding yes/X11Forwarding no/g' /etc/ssh/sshd_config
  sed -i 's/ServerKeyBits 1024/ServerKeyBits 4096/g' /etc/ssh/sshd_config
  sed -i 's/TCPKeepAlive yes/TCPKeepAlive no/g' /etc/ssh/sshd_config
  sed -i 's|HostKey /etc/ssh/ssh_host_dsa_key|#HostKey /etc/ssh/ssh_host_dsa_key|g' /etc/ssh/sshd_config
  sed -i 's|HostKey /etc/ssh/ssh_host_ecdsa_key|#HostKey /etc/ssh/ssh_host_ecdsa_key|g' /etc/ssh/sshd_config
  echo 'ClientAliveInterval 60' >> /etc/ssh/sshd_config
  echo 'ClientAliveCountMax 3' >> /etc/ssh/sshd_config
  echo 'Ciphers aes256-ctr,aes128-ctr' >> /etc/ssh/sshd_config
  echo 'MACs hmac-sha2-512,hmac-sha2-256,hmac-ripemd160
  KexAlgorithms diffie-hellman-group-exchange-sha256,diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1' >> /etc/ssh/sshd_config
  apt-get -y --force-yes install fail2ban
  echo 'configure_ssh' >> $COMPLETION_FILE
  # Don't reboot if installing within docker
  # random numbers will come from the host system
  if [[ $INSTALLED_WITHIN_DOCKER == "yes" ]]; then
      return
  fi
  echo ''
  echo ''
  echo '  *** Rebooting to initialise ssh settings and random number generator ***'
  echo ''
  echo "  *** Reconnect via ssh on port $SSH_PORT, then run this script again  ***"
  echo ''
  reboot
}

function regenerate_ssh_keys {
  if grep -Fxq "regenerate_ssh_keys" $COMPLETION_FILE; then
      return
  fi
  rm -f /etc/ssh/ssh_host_*
  dpkg-reconfigure openssh-server
  service ssh restart
  echo 'regenerate_ssh_keys' >> $COMPLETION_FILE
}

function configure_dns {
  if grep -Fxq "configure_dns" $COMPLETION_FILE; then
      return
  fi
  echo 'domain localdomain' > /etc/resolv.conf
  echo 'search localdomain' >> /etc/resolv.conf
  echo 'nameserver 213.73.91.35' >> /etc/resolv.conf
  echo 'nameserver 85.214.20.141' >> /etc/resolv.conf
  echo 'configure_dns' >> $COMPLETION_FILE
}

function set_your_domain_name {
  if grep -Fxq "set_your_domain_name" $COMPLETION_FILE; then
      return
  fi
  echo "$DOMAIN_NAME" > /etc/hostname
  hostname $DOMAIN_NAME
  sed -i "s/127.0.1.1       arm/127.0.1.1       $DOMAIN_NAME/g" /etc/hosts
  echo "127.0.1.1  $DOMAIN_NAME" >> /etc/hosts
  echo 'set_your_domain_name' >> $COMPLETION_FILE
}

function time_synchronisation {
  if grep -Fxq "time_synchronisation" $COMPLETION_FILE; then
      return
  fi
  apt-get -y --force-yes install tlsdate
  apt-get -y remove ntpdate

  echo '#!/bin/bash' > /usr/bin/updatedate
  echo 'TIMESOURCE=google.com' >> /usr/bin/updatedate
  echo 'TIMESOURCE2=www.ptb.de' >> /usr/bin/updatedate
  echo 'LOGFILE=/var/log/tlsdate.log' >> /usr/bin/updatedate
  echo 'TIMEOUT=5' >> /usr/bin/updatedate
  echo "EMAIL=$MY_USERNAME@$DOMAIN_NAME" >> /usr/bin/updatedate
  echo '# File which contains the previous date as a number' >> /usr/bin/updatedate
  echo 'BEFORE_DATE_FILE=/var/log/tlsdateprevious.txt' >> /usr/bin/updatedate
  echo '# File which contains the previous date as a string' >> /usr/bin/updatedate
  echo 'BEFORE_FULLDATE_FILE=/var/log/tlsdate.txt' >> /usr/bin/updatedate
  echo 'DATE_BEFORE=$(date)' >> /usr/bin/updatedate
  echo 'BEFORE=$(date -d "$Y-$M-$D" "+%s")' >> /usr/bin/updatedate
  echo 'BACKWARDS_BETWEEN=0' >> /usr/bin/updatedate
  echo '# If the date was previously set' >> /usr/bin/updatedate
  echo 'if [[ -f "$BEFORE_DATE_FILE" ]]; then' >> /usr/bin/updatedate
  echo '    BEFORE_FILE=$(cat $BEFORE_DATE_FILE)' >> /usr/bin/updatedate
  echo '    BEFORE_FULLDATE=$(cat $BEFORE_FULLDATE_FILE)' >> /usr/bin/updatedate
  echo '    # is the date going backwards?' >> /usr/bin/updatedate
  echo '    if (( BEFORE_FILE > BEFORE )); then' >> /usr/bin/updatedate
  echo '        echo -n "Date went backwards between tlsdate updates. " >> $LOGFILE' >> /usr/bin/updatedate
  echo '        echo -n "$BEFORE_FILE > $BEFORE, " >> $LOGFILE' >> /usr/bin/updatedate
  echo '        echo "$BEFORE_FULLDATE > $DATE_BEFORE" >> $LOGFILE' >> /usr/bin/updatedate
  echo '        # Send a warning email' > /usr/bin/updatedate
  echo '        echo $(tail $LOGFILE -n 2) | mail -s "tlsdate anomaly" $EMAIL' >> /usr/bin/updatedate
  echo '        # Try another time source' >> /usr/bin/updatedate
  echo '        TIMESOURCE=$TIMESOURCE2' >> /usr/bin/updatedate
  echo '        # try running without any parameters' >> /usr/bin/updatedate
  echo '        tlsdate >> $LOGFILE' >> /usr/bin/updatedate
  echo '        BACKWARDS_BETWEEN=1' >> /usr/bin/updatedate
  echo '    fi' >> /usr/bin/updatedate
  echo 'fi' >> /usr/bin/updatedate
  echo '# Set the date' >> /usr/bin/updatedate
  echo '/usr/bin/timeout $TIMEOUT tlsdate -l -t -H $TIMESOURCE -p 443 >> $LOGFILE' >> /usr/bin/updatedate
  echo 'DATE_AFTER=$(date)' >> /usr/bin/updatedate
  echo 'AFTER=$(date -d "$Y-$M-$D" '+%s')' >> /usr/bin/updatedate
  echo '# After setting the date did it go backwards?' >> /usr/bin/updatedate
  echo 'if (( AFTER < BEFORE )); then' >> /usr/bin/updatedate
  echo '    echo "Incorrect date: $DATE_BEFORE -> $DATE_AFTER" >> $LOGFILE' >> /usr/bin/updatedate
  echo '    # Send a warning email' >> /usr/bin/updatedate
  echo '    echo $(tail $LOGFILE -n 2) | mail -s "tlsdate anomaly" $EMAIL' >> /usr/bin/updatedate
  echo '    # Try resetting the date from another time source' >> /usr/bin/updatedate
  echo '    /usr/bin/timeout $TIMEOUT tlsdate -l -t -H $TIMESOURCE2 -p 443 >> $LOGFILE' >> /usr/bin/updatedate
  echo '    DATE_AFTER=$(date)' >> /usr/bin/updatedate
  echo '    AFTER=$(date -d "$Y-$M-$D" "+%s")' >> /usr/bin/updatedate
  echo 'else' >> /usr/bin/updatedate
  echo '    echo -n $TIMESOURCE >> $LOGFILE' >> /usr/bin/updatedate
  echo '    if [[ -f "$BEFORE_DATE_FILE" ]]; then' >> /usr/bin/updatedate
  echo '        echo -n " " >> $LOGFILE' >> /usr/bin/updatedate
  echo '        echo -n $BEFORE_FILE >> $LOGFILE' >> /usr/bin/updatedate
  echo '    fi' >> /usr/bin/updatedate
  echo '    echo -n " " >> $LOGFILE' >> /usr/bin/updatedate
  echo '    echo -n $BEFORE >> $LOGFILE' >> /usr/bin/updatedate
  echo '    echo -n " " >> $LOGFILE' >> /usr/bin/updatedate
  echo '    echo -n $AFTER >> $LOGFILE' >> /usr/bin/updatedate
  echo '    echo -n " " >> $LOGFILE' >> /usr/bin/updatedate
  echo '    echo $DATE_AFTER >> $LOGFILE' >> /usr/bin/updatedate
  echo 'fi' >> /usr/bin/updatedate
  echo '# Log the last date' >> /usr/bin/updatedate
  echo 'if [ BACKWARDS_BETWEEN == 0 ]; then' >> /usr/bin/updatedate
  echo '    echo "$AFTER" > $BEFORE_DATE_FILE' >> /usr/bin/updatedate
  echo '    echo "$DATE_AFTER" > $BEFORE_FULLDATE_FILE' >> /usr/bin/updatedate
  echo '    exit 0' >> /usr/bin/updatedate
  echo 'else' >> /usr/bin/updatedate
  echo '    exit 1' >> /usr/bin/updatedate
  echo 'fi' >> /usr/bin/updatedate
  chmod +x /usr/bin/updatedate
  echo '*/15           * *   *   *   root /usr/bin/updatedate' >> /etc/crontab
  service cron restart

  echo '#!/bin/bash' > /etc/init.d/tlsdate
  echo '# /etc/init.d/tlsdate' >> /etc/init.d/tlsdate
  echo '### BEGIN INIT INFO' >> /etc/init.d/tlsdate
  echo '# Provides:          tlsdate' >> /etc/init.d/tlsdate
  echo '# Required-Start:    $remote_fs $syslog' >> /etc/init.d/tlsdate
  echo '# Required-Stop:     $remote_fs $syslog' >> /etc/init.d/tlsdate
  echo '# Default-Start:     2 3 4 5' >> /etc/init.d/tlsdate
  echo '# Default-Stop:      0 1 6' >> /etc/init.d/tlsdate
  echo '# Short-Description: Initially calls tlsdate with the timewarp option' >> /etc/init.d/tlsdate
  echo '# Description:       Initially calls tlsdate with the timewarp option' >> /etc/init.d/tlsdate
  echo '### END INIT INFO' >> /etc/init.d/tlsdate
  echo '# Author: Bob Mottram <bob@robotics.uk.to>' >> /etc/init.d/tlsdate
  echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/sbin:/usr/sbin:/bin"' >> /etc/init.d/tlsdate
  echo 'LOGFILE="/var/log/tlsdate.log"' >> /etc/init.d/tlsdate
  echo 'TLSDATECOMMAND="tlsdate --timewarp -l -H www.ptb.de -p 443 >> $LOGFILE"' >> /etc/init.d/tlsdate
  echo '#Start-Stop here' >> /etc/init.d/tlsdate
  echo 'case "$1" in' >> /etc/init.d/tlsdate
  echo '  start)' >> /etc/init.d/tlsdate
  echo '    echo "tlsdate started"' >> /etc/init.d/tlsdate
  echo '    $TLSDATECOMMAND' >> /etc/init.d/tlsdate
  echo '    ;;' >> /etc/init.d/tlsdate
  echo '  stop)' >> /etc/init.d/tlsdate
  echo '    echo "tlsdate stopped"' >> /etc/init.d/tlsdate
  echo '    ;;' >> /etc/init.d/tlsdate
  echo '  restart)' >> /etc/init.d/tlsdate
  echo '    echo "tlsdate restarted"' >> /etc/init.d/tlsdate
  echo '    $TLSDATECOMMAND' >> /etc/init.d/tlsdate
  echo '    ;;' >> /etc/init.d/tlsdate
  echo '    *)' >> /etc/init.d/tlsdate
  echo '  echo "Usage: $0 {start|stop|restart}"' >> /etc/init.d/tlsdate
  echo '  exit 1' >> /etc/init.d/tlsdate
  echo '  ;;' >> /etc/init.d/tlsdate
  echo 'esac' >> /etc/init.d/tlsdate
  echo 'exit 0' >> /etc/init.d/tlsdate
  chmod +x /etc/init.d/tlsdate
  update-rc.d tlsdate defaults
  echo 'time_synchronisation' >> $COMPLETION_FILE
}

function configure_firewall {
  if grep -Fxq "configure_firewall" $COMPLETION_FILE; then
      return
  fi
  if [[ $INSTALLED_WITHIN_DOCKER == "yes" ]]; then
      # docker does its own firewalling
      return
  fi
  iptables -P INPUT ACCEPT
  ip6tables -P INPUT ACCEPT
  iptables -F
  ip6tables -F
  iptables -X
  ip6tables -X
  iptables -P INPUT DROP
  ip6tables -P INPUT DROP
  iptables -A INPUT -i lo -j ACCEPT
  iptables -A INPUT -i eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  echo 'configure_firewall' >> $COMPLETION_FILE
}

function save_firewall_settings {
  iptables-save > /etc/firewall.conf
  ip6tables-save > /etc/firewall6.conf
  printf '#!/bin/sh\n' > /etc/network/if-up.d/iptables
  printf 'iptables-restore < /etc/firewall.conf\n' >> /etc/network/if-up.d/iptables
  printf 'ip6tables-restore < /etc/firewall6.conf\n' >> /etc/network/if-up.d/iptables
  chmod +x /etc/network/if-up.d/iptables
}

function configure_firewall_for_dns {
  if grep -Fxq "configure_firewall_for_dns" $COMPLETION_FILE; then
      return
  fi
  if [[ $INSTALLED_WITHIN_DOCKER == "yes" ]]; then
      # docker does its own firewalling
      return
  fi
  iptables -A INPUT -i eth0 -p udp -m udp --dport 1024:65535 --sport 53 -j ACCEPT
  save_firewall_settings
  echo 'configure_firewall_for_dns' >> $COMPLETION_FILE
}

function configure_firewall_for_xmpp {
  if [ ! -d /etc/prosody ]; then
      return
  fi
  if grep -Fxq "configure_firewall_for_xmpp" $COMPLETION_FILE; then
      return
  fi
  if [[ $INSTALLED_WITHIN_DOCKER == "yes" ]]; then
      # docker does its own firewalling
      return
  fi
  iptables -A INPUT -i eth0 -p tcp --dport 5222:5223 -j ACCEPT
  iptables -A INPUT -i eth0 -p tcp --dport 5269 -j ACCEPT
  iptables -A INPUT -i eth0 -p tcp --dport 5280:5281 -j ACCEPT
  save_firewall_settings
  echo 'configure_firewall_for_xmpp' >> $COMPLETION_FILE
}

function configure_firewall_for_irc {
  if [ ! -d /etc/ngircd ]; then
      return
  fi
  if grep -Fxq "configure_firewall_for_irc" $COMPLETION_FILE; then
      return
  fi
  if [[ $INSTALLED_WITHIN_DOCKER == "yes" ]]; then
      # docker does its own firewalling
      return
  fi
  iptables -A INPUT -i eth0 -p tcp --dport 6697  -j ACCEPT
  iptables -A INPUT -i eth0 -p tcp --dport 9999 -j ACCEPT
  save_firewall_settings
  echo 'configure_firewall_for_irc' >> $COMPLETION_FILE
}

function configure_firewall_for_ftp {
  if grep -Fxq "configure_firewall_for_ftp" $COMPLETION_FILE; then
      return
  fi
  if [[ $INSTALLED_WITHIN_DOCKER == "yes" ]]; then
      # docker does its own firewalling
      return
  fi
  iptables -I INPUT -i eth0 -p tcp --dport 1024:65535 --sport 20:21 -j ACCEPT
  save_firewall_settings
  echo 'configure_firewall_for_ftp' >> $COMPLETION_FILE
}

function configure_firewall_for_web_access {
  if grep -Fxq "configure_firewall_for_web_access" $COMPLETION_FILE; then
      return
  fi
  if [[ $INSTALLED_WITHIN_DOCKER == "yes" ]]; then
      # docker does its own firewalling
      return
  fi
  iptables -A INPUT -i eth0 -p tcp --dport 32768:61000 --sport 80 -j ACCEPT
  iptables -A INPUT -i eth0 -p tcp --dport 32768:61000 --sport 443 -j ACCEPT
  save_firewall_settings
  echo 'configure_firewall_for_web_access' >> $COMPLETION_FILE
}

function configure_firewall_for_web_server {
  if grep -Fxq "configure_firewall_for_web_server" $COMPLETION_FILE; then
      return
  fi
  if [[ $INSTALLED_WITHIN_DOCKER == "yes" ]]; then
      # docker does its own firewalling
      return
  fi
  iptables -A INPUT -i eth0 -p tcp --dport 80 -j ACCEPT
  iptables -A INPUT -i eth0 -p tcp --dport 443 -j ACCEPT
  save_firewall_settings
  echo 'configure_firewall_for_web_server' >> $COMPLETION_FILE
}

function configure_firewall_for_ssh {
  if grep -Fxq "configure_firewall_for_ssh" $COMPLETION_FILE; then
      return
  fi
  if [[ $INSTALLED_WITHIN_DOCKER == "yes" ]]; then
      # docker does its own firewalling
      return
  fi
  iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
  iptables -A INPUT -i eth0 -p tcp --dport $SSH_PORT -j ACCEPT
  save_firewall_settings
  echo 'configure_firewall_for_ssh' >> $COMPLETION_FILE
}

function configure_firewall_for_git {
  if grep -Fxq "configure_firewall_for_git" $COMPLETION_FILE; then
      return
  fi
  if [[ $INSTALLED_WITHIN_DOCKER == "yes" ]]; then
      # docker does its own firewalling
      return
  fi
  iptables -A INPUT -i eth0 -p tcp --dport 9418 -j ACCEPT
  save_firewall_settings
  echo 'configure_firewall_for_git' >> $COMPLETION_FILE
}

function configure_firewall_for_email {
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      return
  fi
  if grep -Fxq "configure_firewall_for_email" $COMPLETION_FILE; then
      return
  fi
  if [[ $INSTALLED_WITHIN_DOCKER == "yes" ]]; then
      # docker does its own firewalling
      return
  fi
  iptables -A INPUT -i eth0 -p tcp --dport 25 -j ACCEPT
  iptables -A INPUT -i eth0 -p tcp --dport 587 -j ACCEPT
  iptables -A INPUT -i eth0 -p tcp --dport 465 -j ACCEPT
  iptables -A INPUT -i eth0 -p tcp --dport 993 -j ACCEPT
  save_firewall_settings
  echo 'configure_firewall_for_email' >> $COMPLETION_FILE
}

function configure_internet_protocol {
  if grep -Fxq "configure_internet_protocol" $COMPLETION_FILE; then
      return
  fi
  sed -i "s/#net.ipv4.tcp_syncookies=1/net.ipv4.tcp_syncookies=1/g" /etc/sysctl.conf
  sed -i "s/#net.ipv4.conf.all.accept_redirects = 0/net.ipv4.conf.all.accept_redirects = 0/g" /etc/sysctl.conf
  sed -i "s/#net.ipv6.conf.all.accept_redirects = 0/net.ipv6.conf.all.accept_redirects = 0/g" /etc/sysctl.conf
  sed -i "s/#net.ipv4.conf.all.send_redirects = 0/net.ipv4.conf.all.send_redirects = 0/g" /etc/sysctl.conf
  sed -i "s/#net.ipv4.conf.all.accept_source_route = 0/net.ipv4.conf.all.accept_source_route = 0/g" /etc/sysctl.conf
  sed -i "s/#net.ipv6.conf.all.accept_source_route = 0/net.ipv6.conf.all.accept_source_route = 0/g" /etc/sysctl.conf
  sed -i "s/#net.ipv4.conf.default.rp_filter=1/net.ipv4.conf.default.rp_filter=1/g" /etc/sysctl.conf
  sed -i "s/#net.ipv4.conf.all.rp_filter=1/net.ipv4.conf.all.rp_filter=1/g" /etc/sysctl.conf
  sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=0/g" /etc/sysctl.conf
  sed -i "s/#net.ipv6.conf.all.forwarding=1/net.ipv6.conf.all.forwarding=0/g" /etc/sysctl.conf
  echo '# ignore pings' >> /etc/sysctl.conf
  echo 'net.ipv4.icmp_echo_ignore_all = 1' >> /etc/sysctl.conf
  echo 'net.ipv6.icmp_echo_ignore_all = 1' >> /etc/sysctl.conf
  echo '# disable ipv6' >> /etc/sysctl.conf
  echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
  echo 'net.ipv4.tcp_synack_retries = 2' >> /etc/sysctl.conf
  echo 'net.ipv4.tcp_syn_retries = 1' >> /etc/sysctl.conf
  echo '# keepalive' >> /etc/sysctl.conf
  echo 'net.ipv4.tcp_keepalive_probes = 9' >> /etc/sysctl.conf
  echo 'net.ipv4.tcp_keepalive_intvl = 75' >> /etc/sysctl.conf
  echo 'net.ipv4.tcp_keepalive_time = 7200' >> /etc/sysctl.conf
  echo 'configure_internet_protocol' >> $COMPLETION_FILE
}

function script_to_make_self_signed_certificates {
  if grep -Fxq "script_to_make_self_signed_certificates" $COMPLETION_FILE; then
      return
  fi
  echo '#!/bin/bash' > /usr/bin/makecert
  echo 'HOSTNAME=$1' >> /usr/bin/makecert
  echo 'COUNTRY_CODE="US"' >> /usr/bin/makecert
  echo 'AREA="Free Speech Zone"' >> /usr/bin/makecert
  echo 'LOCATION="Freedomville"' >> /usr/bin/makecert
  echo 'ORGANISATION="Freedombone"' >> /usr/bin/makecert
  echo 'UNIT="Freedombone Unit"' >> /usr/bin/makecert
  echo 'if ! which openssl > /dev/null ;then' >> /usr/bin/makecert
  echo '    echo "$0: openssl is not installed, exiting" 1>&2' >> /usr/bin/makecert
  echo '    exit 1' >> /usr/bin/makecert
  echo 'fi' >> /usr/bin/makecert
  echo 'openssl req -x509 -nodes -days 3650 -sha256 -subj "/O=$ORGANISATION/OU=$UNIT/C=$COUNTRY_CODE/ST=$AREA/L=$LOCATION/CN=$HOSTNAME" -newkey rsa:4096 -keyout /etc/ssl/private/$HOSTNAME.key -out /etc/ssl/certs/$HOSTNAME.crt' >> /usr/bin/makecert
  echo 'openssl dhparam -check -text -5 1024 -out /etc/ssl/certs/$HOSTNAME.dhparam' >> /usr/bin/makecert
  echo 'chmod 400 /etc/ssl/private/$HOSTNAME.key' >> /usr/bin/makecert
  echo 'chmod 640 /etc/ssl/certs/$HOSTNAME.crt' >> /usr/bin/makecert
  echo 'chmod 640 /etc/ssl/certs/$HOSTNAME.dhparam' >> /usr/bin/makecert
  echo 'if [ -f /etc/init.d/nginx ]; then' >> /usr/bin/makecert
  echo '  /etc/init.d/nginx reload' >> /usr/bin/makecert
  echo 'fi' >> /usr/bin/makecert
  echo '# add the public certificate to a separate directory' >> /usr/bin/makecert
  echo '# so that we can redistribute it easily' >> /usr/bin/makecert
  echo 'if [ ! -d /etc/ssl/mycerts ]; then' >> /usr/bin/makecert
  echo '  mkdir /etc/ssl/mycerts' >> /usr/bin/makecert
  echo 'fi' >> /usr/bin/makecert
  echo 'cp /etc/ssl/certs/$HOSTNAME.crt /etc/ssl/mycerts' >> /usr/bin/makecert
  echo '# Create a bundle of your certificates' >> /usr/bin/makecert
  echo 'cat /etc/ssl/mycerts/*.crt > /etc/ssl/freedombone-bundle.crt' >> /usr/bin/makecert
  echo 'tar -czvf /etc/ssl/freedombone-certs.tar.gz /etc/ssl/mycerts/*.crt' >> /usr/bin/makecert
  chmod +x /usr/bin/makecert
  echo 'script_to_make_self_signed_certificates' >> $COMPLETION_FILE
}

function configure_email {
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      return
  fi
  if grep -Fxq "configure_email" $COMPLETION_FILE; then
      return
  fi
  apt-get -y remove postfix
  apt-get -y --force-yes install exim4 sasl2-bin swaks libnet-ssleay-perl procmail
  echo 'dc_eximconfig_configtype="internet"' > /etc/exim4/update-exim4.conf.conf
  echo "dc_other_hostnames='$DOMAIN_NAME'" >> /etc/exim4/update-exim4.conf.conf
  echo "dc_local_interfaces=''" >> /etc/exim4/update-exim4.conf.conf
  echo "dc_readhost=''" >> /etc/exim4/update-exim4.conf.conf
  echo "dc_relay_domains=''" >> /etc/exim4/update-exim4.conf.conf
  echo "dc_minimaldns='false'" >> /etc/exim4/update-exim4.conf.conf
  echo "dc_relay_nets='192.168.1.0/24'" >> /etc/exim4/update-exim4.conf.conf
  echo "dc_smarthost=''" >> /etc/exim4/update-exim4.conf.conf
  echo "CFILEMODE='644'" >> /etc/exim4/update-exim4.conf.conf
  echo "dc_use_split_config='false'" >> /etc/exim4/update-exim4.conf.conf
  echo "dc_hide_mailname=''" >> /etc/exim4/update-exim4.conf.conf
  echo "dc_mailname_in_oh='true'" >> /etc/exim4/update-exim4.conf.conf
  echo "dc_localdelivery='maildir_home'" >> /etc/exim4/update-exim4.conf.conf
  update-exim4.conf
  sed -i "s/START=no/START=yes/g" /etc/default/saslauthd
  /etc/init.d/saslauthd start

  # make a tls certificate for email
  makecert exim
  mv /etc/ssl/private/exim.key /etc/exim4
  mv /etc/ssl/certs/exim.crt /etc/exim4
  mv /etc/ssl/certs/exim.dhparam /etc/exim4
  chown root:Debian-exim /etc/exim4/exim.key /etc/exim4/exim.crt /etc/exim4/exim.dhparam
  chmod 640 /etc/exim4/exim.key /etc/exim4/exim.crt /etc/exim4/exim.dhparam

  sed -i '/login_saslauthd_server/,/.endif/ s/# *//' /etc/exim4/exim4.conf.template
  sed -i "/.ifdef MAIN_HARDCODE_PRIMARY_HOSTNAME/i\MAIN_HARDCODE_PRIMARY_HOSTNAME = $DOMAIN_NAME\nMAIN_TLS_ENABLE = true" /etc/exim4/exim4.conf.template
  sed -i "s|SMTPLISTENEROPTIONS=''|SMTPLISTENEROPTIONS='-oX 465:25:587 -oP /var/run/exim4/exim.pid'|g" /etc/default/exim4
  if ! grep -q "tls_on_connect_ports=465" /etc/exim4/exim4.conf.template; then
    sed -i '/SSL configuration for exim/i\tls_on_connect_ports=465' /etc/exim4/exim4.conf.template
  fi

  adduser $MY_USERNAME sasl
  addgroup Debian-exim sasl
  /etc/init.d/exim4 restart
  if [ ! -d /etc/skel/Maildir ]; then
    mkdir -m 700 /etc/skel/Maildir
    mkdir -m 700 /etc/skel/Maildir/Sent
    mkdir -m 700 /etc/skel/Maildir/Sent/tmp
    mkdir -m 700 /etc/skel/Maildir/Sent/cur
    mkdir -m 700 /etc/skel/Maildir/Sent/new
    mkdir -m 700 /etc/skel/Maildir/.learn-spam
    mkdir -m 700 /etc/skel/Maildir/.learn-spam/cur
    mkdir -m 700 /etc/skel/Maildir/.learn-spam/new
    mkdir -m 700 /etc/skel/Maildir/.learn-spam/tmp
    mkdir -m 700 /etc/skel/Maildir/.learn-ham
    mkdir -m 700 /etc/skel/Maildir/.learn-ham/cur
    mkdir -m 700 /etc/skel/Maildir/.learn-ham/new
    mkdir -m 700 /etc/skel/Maildir/.learn-ham/tmp
    ln -s /etc/skel/Maildir/.learn-spam /etc/skel/Maildir/spam
    ln -s /etc/skel/Maildir/.learn-ham /etc/skel/Maildir/ham
  fi

  if [ ! -d /home/$MY_USERNAME/Maildir ]; then
    mkdir -m 700 /home/$MY_USERNAME/Maildir
    mkdir -m 700 /home/$MY_USERNAME/Maildir/cur
    mkdir -m 700 /home/$MY_USERNAME/Maildir/tmp
    mkdir -m 700 /home/$MY_USERNAME/Maildir/new
    mkdir -m 700 /home/$MY_USERNAME/Maildir/Sent
    mkdir -m 700 /home/$MY_USERNAME/Maildir/Sent/cur
    mkdir -m 700 /home/$MY_USERNAME/Maildir/Sent/tmp
    mkdir -m 700 /home/$MY_USERNAME/Maildir/Sent/new
    mkdir -m 700 /home/$MY_USERNAME/Maildir/.learn-spam
    mkdir -m 700 /home/$MY_USERNAME/Maildir/.learn-spam/cur
    mkdir -m 700 /home/$MY_USERNAME/Maildir/.learn-spam/new
    mkdir -m 700 /home/$MY_USERNAME/Maildir/.learn-spam/tmp
    mkdir -m 700 /home/$MY_USERNAME/Maildir/.learn-ham
    mkdir -m 700 /home/$MY_USERNAME/Maildir/.learn-ham/cur
    mkdir -m 700 /home/$MY_USERNAME/Maildir/.learn-ham/new
    mkdir -m 700 /home/$MY_USERNAME/Maildir/.learn-ham/tmp
    ln -s /home/$MY_USERNAME/Maildir/.learn-spam /home/$MY_USERNAME/Maildir/spam
    ln -s /home/$MY_USERNAME/Maildir/.learn-ham /home/$MY_USERNAME/Maildir/ham
    chown -R $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/Maildir
  fi
  echo 'configure_email' >> $COMPLETION_FILE
}

function spam_filtering {
  # NOTE: spamassassin installation currently doesn't work, sa-compile fails with a make error 23/09/2014
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      return
  fi
  if grep -Fxq "spam_filtering" $COMPLETION_FILE; then
      return
  fi
  apt-get -y --force-yes install exim4-daemon-heavy
  apt-get -y --force-yes install spamassassin
  sa-update -v
  sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/spamassassin
  sed -i 's/# spamd_address = 127.0.0.1 783/spamd_address = 127.0.0.1 783/g' /etc/exim4/exim4.conf.template
  # This configuration is based on https://wiki.debian.org/DebianSpamAssassin
  sed -i 's/local_parts = postmaster/local_parts = postmaster:abuse/g' /etc/exim4/conf.d/acl/30_exim4-config_check_rcpt
  sed -i '/domains = +local_domains : +relay_to_domains/a\    set acl_m0 = rfcnames' /etc/exim4/conf.d/acl/30_exim4-config_check_rcpt
  sed -i 's/accept/accept condition = ${if eq{$acl_m0}{rfcnames} {1}{0}}/g' /etc/exim4/conf.d/acl/40_exim4-config_check_data
  echo 'warn  message = X-Spam-Score: $spam_score ($spam_bar)' >> /etc/exim4/conf.d/acl/40_exim4-config_check_data
  echo '      spam = nobody:true' >> /etc/exim4/conf.d/acl/40_exim4-config_check_data
  echo 'warn  message = X-Spam-Flag: YES' >> /etc/exim4/conf.d/acl/40_exim4-config_check_data
  echo '      spam = nobody' >> /etc/exim4/conf.d/acl/40_exim4-config_check_data
  echo 'warn  message = X-Spam-Report: $spam_report' >> /etc/exim4/conf.d/acl/40_exim4-config_check_data
  echo '      spam = nobody' >> /etc/exim4/conf.d/acl/40_exim4-config_check_data
  echo '# reject spam at high scores (> 12)' >> /etc/exim4/conf.d/acl/40_exim4-config_check_data
  echo 'deny  message = This message scored $spam_score spam points.' >> /etc/exim4/conf.d/acl/40_exim4-config_check_data
  echo '      spam = nobody:true' >> /etc/exim4/conf.d/acl/40_exim4-config_check_data
  echo '      condition = ${if >{$spam_score_int}{120}{1}{0}}' >> /etc/exim4/conf.d/acl/40_exim4-config_check_data
  # procmail configuration
  echo 'MAILDIR=$HOME/Maildir' > /home/$MY_USERNAME/.procmailrc
  echo 'DEFAULT=$MAILDIR/' >> /home/$MY_USERNAME/.procmailrc
  echo 'LOGFILE=$HOME/log/procmail.log' >> /home/$MY_USERNAME/.procmailrc
  echo 'LOGABSTRACT=all' >> /home/$MY_USERNAME/.procmailrc
  echo '# get spamassassin to check emails' >> /home/$MY_USERNAME/.procmailrc
  echo ':0fw: .spamassassin.lock' >> /home/$MY_USERNAME/.procmailrc
  echo '  * < 256000' >> /home/$MY_USERNAME/.procmailrc
  echo '| spamc' >> /home/$MY_USERNAME/.procmailrc
  echo '# strong spam are discarded' >> /home/$MY_USERNAME/.procmailrc
  echo ':0' >> /home/$MY_USERNAME/.procmailrc
  echo '  * ^X-Spam-Level: \*\*\*\*\*\*' >> /home/$MY_USERNAME/.procmailrc
  echo '/dev/null' >> /home/$MY_USERNAME/.procmailrc
  echo '# weak spam are kept just in case - clear this out every now and then' >> /home/$MY_USERNAME/.procmailrc
  echo ':0' >> /home/$MY_USERNAME/.procmailrc
  echo '  * ^X-Spam-Level: \*\*\*\*\*' >> /home/$MY_USERNAME/.procmailrc
  echo '.0-spam/' >> /home/$MY_USERNAME/.procmailrc
  echo '# otherwise, marginal spam goes here for revision' >> /home/$MY_USERNAME/.procmailrc
  echo ':0' >> /home/$MY_USERNAME/.procmailrc
  echo '  * ^X-Spam-Level: \*\*' >> /home/$MY_USERNAME/.procmailrc
  echo '.spam/' >> /home/$MY_USERNAME/.procmailrc
  chown $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/.procmailrc
  # filtering scripts
  echo '#!/bin/bash' > /usr/bin/filterspam
  echo 'USERNAME=$1' >> /usr/bin/filterspam
  echo 'MAILDIR=/home/$USERNAME/Maildir/.learn-spam' >> /usr/bin/filterspam
  echo 'if [ ! -d "$MAILDIR" ]; then' >> /usr/bin/filterspam
  echo '    exit' >> /usr/bin/filterspam
  echo 'fi' >> /usr/bin/filterspam
  echo 'for f in `ls $MAILDIR/cur`' >> /usr/bin/filterspam
  echo 'do' >> /usr/bin/filterspam
  echo '    spamc -L spam < "$MAILDIR/cur/$f" > /dev/null' >> /usr/bin/filterspam
  echo '    rm "$MAILDIR/cur/$f"' >> /usr/bin/filterspam
  echo 'done' >> /usr/bin/filterspam
  echo 'for f in `ls $MAILDIR/new`' >> /usr/bin/filterspam
  echo 'do' >> /usr/bin/filterspam
  echo '    spamc -L spam < "$MAILDIR/new/$f" > /dev/null' >> /usr/bin/filterspam
  echo '    rm "$MAILDIR/new/$f"' >> /usr/bin/filterspam
  echo 'done' >> /usr/bin/filterspam

  echo '#!/bin/bash' > /usr/bin/filterham
  echo 'USERNAME=$1' >> /usr/bin/filterham
  echo 'MAILDIR=/home/$USERNAME/Maildir/.learn-ham' >> /usr/bin/filterham
  echo 'if [ ! -d "$MAILDIR" ]; then' >> /usr/bin/filterham
  echo '    exit' >> /usr/bin/filterham
  echo 'fi' >> /usr/bin/filterham
  echo 'for f in `ls $MAILDIR/cur`' >> /usr/bin/filterham
  echo 'do' >> /usr/bin/filterham
  echo '    spamc -L ham < "$MAILDIR/cur/$f" > /dev/null' >> /usr/bin/filterham
  echo '    rm "$MAILDIR/cur/$f"' >> /usr/bin/filterham
  echo 'done' >> /usr/bin/filterham
  echo 'for f in `ls $MAILDIR/new`' >> /usr/bin/filterham
  echo 'do' >> /usr/bin/filterham
  echo '    spamc -L ham < "$MAILDIR/new/$f" > /dev/null' >> /usr/bin/filterham
  echo '    rm "$MAILDIR/new/$f"' >> /usr/bin/filterham
  echo 'done' >> /usr/bin/filterham

  if ! grep -q "filterspam" /etc/crontab; then
    echo "*/3 * * * * root /usr/bin/timeout 120 /usr/bin/filterspam $MY_USERNAME" >> /etc/crontab
  fi
  if ! grep -q "filterham" /etc/crontab; then
    echo "*/3 * * * * root /usr/bin/timeout 120 /usr/bin/filterham $MY_USERNAME" >> /etc/crontab
  fi
  chmod 655 /usr/bin/filterspam /usr/bin/filterham
  sed -i 's/# use_bayes 1/use_bayes 1/g' /etc/mail/spamassassin/local.cf
  sed -i 's/# bayes_auto_learn 1/bayes_auto_learn 1/g' /etc/mail/spamassassin/local.cf

  service spamassassin restart
  service exim4 restart
  service cron restart
  echo 'spam_filtering' >> $COMPLETION_FILE
}

function configure_imap {
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      return
  fi
  if grep -Fxq "configure_imap" $COMPLETION_FILE; then
      return
  fi
  apt-get -y --force-yes install dovecot-common dovecot-imapd
  makecert dovecot
  chown root:dovecot /etc/ssl/certs/dovecot.crt
  chown root:dovecot /etc/ssl/private/dovecot.key
  chown root:dovecot /etc/ssl/private/dovecot.dhparams

  sed -i 's|#ssl = yes|ssl = yes|g' /etc/dovecot/conf.d/10-ssl.conf
  sed -i 's|ssl_cert = </etc/dovecot/dovecot.pem|ssl_cert = </etc/ssl/certs/dovecot.crt|g' /etc/dovecot/conf.d/10-ssl.conf
  sed -i 's|ssl_key = </etc/dovecot/private/dovecot.pem|/etc/ssl/private/dovecot.key|g' /etc/dovecot/conf.d/10-ssl.conf
  sed -i 's|#ssl_dh_parameters_length = 1024|ssl_dh_parameters_length = 1024|g' /etc/dovecot/conf.d/10-ssl.conf
  sed -i 's/#ssl_prefer_server_ciphers = no/ssl_prefer_server_ciphers = yes/g' /etc/dovecot/conf.d/10-ssl.conf
  echo "ssl_cipher_list = 'EDH+CAMELLIA:EDH+aRSA:EECDH+aRSA+AESGCM:EECDH+aRSA+SHA384:EECDH+aRSA+SHA256:EECDH:+CAMELLIA256:+AES256:+CAMELLIA128:+AES128:+SSLv3:!aNULL:!eNULL:!LOW:!3DES:!MD5:!EXP:!PSK:!DSS:!RC4:!SEED:!ECDSA:CAMELLIA256-SHA:AES256-SHA:CAMELLIA128-SHA:AES128-SHA'" >> /etc/dovecot/conf.d/10-ssl.conf


  sed -i 's/#listen = *, ::/listen = */g' /etc/dovecot/dovecot.conf
  sed -i 's/#disable_plaintext_auth = yes/disable_plaintext_auth = no/g' /etc/dovecot/conf.d/10-auth.conf
  sed -i 's/auth_mechanisms = plain/auth_mechanisms = plain login/g' /etc/dovecot/conf.d/10-auth.conf
  sed -i 's|#   mail_location = maildir:~/Maildir|   mail_location = maildir:~/Maildir:LAYOUT=fs|g' /etc/dovecot/conf.d/10-mail.conf
  echo 'configure_imap' >> $COMPLETION_FILE
}

function configure_gpg {
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      return
  fi
  if grep -Fxq "configure_gpg" $COMPLETION_FILE; then
      return
  fi
  apt-get -y --force-yes install gnupg

  if [ ! -d /home/$MY_USERNAME/.gnupg ]; then
      mkdir /home/$MY_USERNAME/.gnupg
      echo 'keyserver hkp://keys.gnupg.net' >> /home/$MY_USERNAME/.gnupg/gpg.conf
      echo 'keyserver-options auto-key-retrieve' >> /home/$MY_USERNAME/.gnupg/gpg.conf
  fi

  sed -i "s|keyserver hkp://keys.gnupg.net|keyserver $GPG_KEYSERVER|g" /home/$MY_USERNAME/.gnupg/gpg.conf

  if ! grep -q "# default preferences" /home/$MY_USERNAME/.gnupg/gpg.conf; then
      echo '' >> /home/$MY_USERNAME/.gnupg/gpg.conf
      echo '# default preferences' >> /home/$MY_USERNAME/.gnupg/gpg.conf
      echo 'personal-digest-preferences SHA256' >> /home/$MY_USERNAME/.gnupg/gpg.conf
      echo 'cert-digest-algo SHA256' >> /home/$MY_USERNAME/.gnupg/gpg.conf
      echo 'default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed' >> /home/$MY_USERNAME/.gnupg/gpg.conf
  fi

  chown -R $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/.gnupg

  if [[ $MY_GPG_PUBLIC_KEY && $MY_GPG_PRIVATE_KEY ]]; then
      # use your existing GPG keys which were exported
      if [ ! -f $MY_GPG_PUBLIC_KEY ]; then
          echo "GPG public key file $MY_GPG_PUBLIC_KEY was not found"
          exit 5
      fi
      if [ ! -f $MY_GPG_PRIVATE_KEY ]; then
          echo "GPG private key file $MY_GPG_PRIVATE_KEY was not found"
          exit 6
      fi
      su -c "gpg --import $MY_GPG_PUBLIC_KEY" - $MY_USERNAME
      su -c "gpg --allow-secret-key-import --import $MY_GPG_PRIVATE_KEY" - $MY_USERNAME
      # for security ensure that the private key file doesn't linger around
      shred -zu $MY_GPG_PRIVATE_KEY
  else
      # Generate a GPG key
      echo 'Key-Type: 1' > /home/$MY_USERNAME/gpg-genkey.conf
      echo 'Key-Length: 4096' >> /home/$MY_USERNAME/gpg-genkey.conf
      echo 'Subkey-Type: 1' >> /home/$MY_USERNAME/gpg-genkey.conf
      echo 'Subkey-Length: 4096' >> /home/$MY_USERNAME/gpg-genkey.conf
      echo "Name-Real:  $MY_USERNAME@$DOMAIN_NAME" >> /home/$MY_USERNAME/gpg-genkey.conf
      echo "Name-Email: $MY_USERNAME@$DOMAIN_NAME" >> /home/$MY_USERNAME/gpg-genkey.conf
      echo 'Expire-Date: 0' >> /home/$MY_USERNAME/gpg-genkey.conf
      chown $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/gpg-genkey.conf
      su -c "gpg --batch --gen-key /home/$MY_USERNAME/gpg-genkey.conf" - $MY_USERNAME
      shred -zu /home/$MY_USERNAME/gpg-genkey.conf
      MY_GPG_PUBLIC_KEY_ID=$(su -c "gpg --list-keys $DOMAIN_NAME | grep 'pub ' | awk -F ' ' '{print $2}' | awk -F '/' '{print $2}'" - $MY_USERNAME)
      MY_GPG_PUBLIC_KEY=/tmp/public_key.gpg
      su -c "gpg --output $MY_GPG_PUBLIC_KEY --armor --export $MY_GPG_PUBLIC_KEY_ID" - $MY_USERNAME
  fi

  echo 'configure_gpg' >> $COMPLETION_FILE
}

function email_client {
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      return
  fi
  if grep -Fxq "email_client" $COMPLETION_FILE; then
      return
  fi
  apt-get -y --force-yes install mutt-patched lynx abook
  if [ ! -d /home/$MY_USERNAME/.mutt ]; then
    mkdir /home/$MY_USERNAME/.mutt
  fi
  echo "text/html; lynx -dump -width=78 -nolist %s | sed ‘s/^ //’; copiousoutput; needsterminal; nametemplate=%s.html" > /home/$MY_USERNAME/.mutt/mailcap
  chown -R $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/.mutt


  echo 'set mbox_type=Maildir' >> /etc/Muttrc
  echo 'set folder="~/Maildir"' >> /etc/Muttrc
  echo 'set mask="!^\\.[^.]"' >> /etc/Muttrc
  echo 'set mbox="~/Maildir"' >> /etc/Muttrc
  echo 'set record="+Sent"' >> /etc/Muttrc
  echo 'set postponed="+Drafts"' >> /etc/Muttrc
  echo 'set trash="+Trash"' >> /etc/Muttrc
  echo 'set spoolfile="~/Maildir"' >> /etc/Muttrc
  echo 'auto_view text/x-vcard text/html text/enriched' >> /etc/Muttrc
  echo 'set editor="emacs"' >> /etc/Muttrc
  echo 'set header_cache="+.cache"' >> /etc/Muttrc
  echo '' >> /etc/Muttrc
  echo 'macro index S "<tag-prefix><save-message>=.learn-spam<enter>" "move to learn-spam"' >> /etc/Muttrc
  echo 'macro pager S "<save-message>=.learn-spam<enter>" "move to learn-spam"' >> /etc/Muttrc
  echo 'macro index H "<tag-prefix><copy-message>=.learn-ham<enter>" "copy to learn-ham"' >> /etc/Muttrc
  echo 'macro pager H "<copy-message>=.learn-ham<enter>" "copy to learn-ham"' >> /etc/Muttrc
  echo '' >> /etc/Muttrc
  echo '# set up the sidebar' >> /etc/Muttrc
  echo 'set sidebar_width=12' >> /etc/Muttrc
  echo 'set sidebar_visible=yes' >> /etc/Muttrc
  echo "set sidebar_delim='|'" >> /etc/Muttrc
  echo 'set sidebar_sort=yes' >> /etc/Muttrc
  echo '' >> /etc/Muttrc
  echo 'set rfc2047_parameters' >> /etc/Muttrc
  echo '' >> /etc/Muttrc
  echo '# Show inbox and sent items' >> /etc/Muttrc
  echo 'mailboxes = =Sent' >> /etc/Muttrc
  echo '' >> /etc/Muttrc
  echo '# Alter these colours as needed for maximum bling' >> /etc/Muttrc
  echo 'color sidebar_new yellow default' >> /etc/Muttrc
  echo 'color normal white default' >> /etc/Muttrc
  echo 'color hdrdefault brightcyan default' >> /etc/Muttrc
  echo 'color signature green default' >> /etc/Muttrc
  echo 'color attachment brightyellow default' >> /etc/Muttrc
  echo 'color quoted green default' >> /etc/Muttrc
  echo 'color quoted1 white default' >> /etc/Muttrc
  echo 'color tilde blue default' >> /etc/Muttrc
  echo '' >> /etc/Muttrc
  echo '# ctrl-n, ctrl-p to select next, prev folder' >> /etc/Muttrc
  echo '# ctrl-o to open selected folder' >> /etc/Muttrc
  echo 'bind index \Cp sidebar-prev' >> /etc/Muttrc
  echo 'bind index \Cn sidebar-next' >> /etc/Muttrc
  echo 'bind index \Co sidebar-open' >> /etc/Muttrc
  echo 'bind pager \Cp sidebar-prev' >> /etc/Muttrc
  echo 'bind pager \Cn sidebar-next' >> /etc/Muttrc
  echo 'bind pager \Co sidebar-open' >> /etc/Muttrc
  echo '' >> /etc/Muttrc
  echo '# ctrl-b toggles sidebar visibility' >> /etc/Muttrc
  echo "macro index,pager \Cb '<enter-command>toggle sidebar_visible<enter><redraw-screen>' 'toggle sidebar'" >> /etc/Muttrc
  echo '' >> /etc/Muttrc
  echo '# esc-m Mark new messages as read' >> /etc/Muttrc
  echo 'macro index <esc>m "T~N<enter>;WNT~O<enter>;WO\CT~T<enter>" "mark all messages read"' >> /etc/Muttrc
  echo '' >> /etc/Muttrc
  echo '# Collapsing threads' >> /etc/Muttrc
  echo 'macro index [ "<collapse-thread>" "collapse/uncollapse thread"' >> /etc/Muttrc
  echo 'macro index ] "<collapse-all>"    "collapse/uncollapse all threads"' >> /etc/Muttrc
  echo '' >> /etc/Muttrc
  echo '# threads containing new messages' >> /etc/Muttrc
  echo 'uncolor index "~(~N)"' >> /etc/Muttrc
  echo 'color index brightblue default "~(~N)"' >> /etc/Muttrc
  echo '' >> /etc/Muttrc
  echo '# new messages themselves' >> /etc/Muttrc
  echo 'uncolor index "~N"' >> /etc/Muttrc
  echo 'color index brightyellow default "~N"' >> /etc/Muttrc
  echo '' >> /etc/Muttrc
  echo '# GPG/PGP integration' >> /etc/Muttrc
  echo '# this set the number of seconds to keep in memory the passphrase used to encrypt/sign' >> /etc/Muttrc
  echo 'set pgp_timeout=60' >> /etc/Muttrc
  echo '' >> /etc/Muttrc
  echo '# automatically sign and encrypt with PGP/MIME' >> /etc/Muttrc
  echo 'set pgp_autosign         # autosign all outgoing mails' >> /etc/Muttrc
  echo 'set pgp_autoencrypt      # Try to encrypt automatically' >> /etc/Muttrc
  echo 'set pgp_replyencrypt     # autocrypt replies to crypted' >> /etc/Muttrc
  echo 'set pgp_replysign        # autosign replies to signed' >> /etc/Muttrc
  echo 'set pgp_auto_decode=yes  # decode attachments' >> /etc/Muttrc
  echo 'set fcc_clear            # Keep cleartext copy of sent encrypted mail' >> /etc/Muttrc
  echo 'unset smime_is_default' >> /etc/Muttrc
  echo '' >> /etc/Muttrc
  echo 'set alias_file=~/.mutt-alias' >> /etc/Muttrc
  echo 'source ~/.mutt-alias' >> /etc/Muttrc
  echo 'set query_command= "abook --mutt-query \"%s\""' >> /etc/Muttrc
  echo 'macro index,pager A "<pipe-message>abook --add-email-quiet<return>" "add the sender address to abook"' >> /etc/Muttrc

  cp -f /etc/Muttrc /home/$MY_USERNAME/.muttrc
  touch /home/$MY_USERNAME/.mutt-alias
  chown $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/.muttrc
  chown $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/.mutt-alias

  echo 'email_client' >> $COMPLETION_FILE
}

function folders_for_mailing_lists {
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      return
  fi
  if grep -Fxq "folders_for_mailing_lists" $COMPLETION_FILE; then
      return
  fi
  echo '#!/bin/bash' > /usr/bin/mailinglistrule
  echo 'MYUSERNAME=$1' >> /usr/bin/mailinglistrule
  echo 'MAILINGLIST=$2' >> /usr/bin/mailinglistrule
  echo 'SUBJECTTAG=$3' >> /usr/bin/mailinglistrule
  echo 'MUTTRC=/home/$MYUSERNAME/.muttrc' >> /usr/bin/mailinglistrule
  echo 'PM=/home/$MYUSERNAME/.procmailrc' >> /usr/bin/mailinglistrule
  echo 'LISTDIR=/home/$MYUSERNAME/Maildir/$MAILINGLIST' >> /usr/bin/mailinglistrule

  echo 'if ! [[ $MYUSERNAME && $MAILINGLIST && $SUBJECTTAG ]]; then' >> /usr/bin/mailinglistrule
  echo '  echo "mailinglistsrule [user name] [mailing list name] [subject tag]"' >> /usr/bin/mailinglistrule
  echo '  exit 1' >> /usr/bin/mailinglistrule
  echo 'fi' >> /usr/bin/mailinglistrule
  echo 'if [ ! -d "$LISTDIR" ]; then' >> /usr/bin/mailinglistrule
  echo '  mkdir -m 700 $LISTDIR' >> /usr/bin/mailinglistrule
  echo '  mkdir -m 700 $LISTDIR/tmp' >> /usr/bin/mailinglistrule
  echo '  mkdir -m 700 $LISTDIR/new' >> /usr/bin/mailinglistrule
  echo '  mkdir -m 700 $LISTDIR/cur' >> /usr/bin/mailinglistrule
  echo 'fi' >> /usr/bin/mailinglistrule
  echo 'chown -R $MYUSERNAME:$MYUSERNAME $LISTDIR' >> /usr/bin/mailinglistrule
  echo 'echo "" >> $PM' >> /usr/bin/mailinglistrule
  echo 'echo ":0" >> $PM' >> /usr/bin/mailinglistrule
  echo 'echo "  * ^Subject:.*()\[$SUBJECTTAG\]" >> $PM' >> /usr/bin/mailinglistrule
  echo 'echo "$LISTDIR/new" >> $PM' >> /usr/bin/mailinglistrule
  echo 'chown $MYUSERNAME:$MYUSERNAME $PM' >> /usr/bin/mailinglistrule
  echo 'if [ ! -f "$MUTTRC" ]; then' >> /usr/bin/mailinglistrule
  echo '  cp /etc/Muttrc $MUTTRC' >> /usr/bin/mailinglistrule
  echo '  chown $MYUSERNAME:$MYUSERNAME $MUTTRC' >> /usr/bin/mailinglistrule
  echo 'fi' >> /usr/bin/mailinglistrule
  echo 'PROCMAILLOG=/home/$MYUSERNAME/log' >> /usr/bin/mailinglistrule
  echo 'if [ ! -d $PROCMAILLOG ]; then' >> /usr/bin/mailinglistrule
  echo '  mkdir $PROCMAILLOG' >> /usr/bin/mailinglistrule
  echo '  chown -R $MYUSERNAME:$MYUSERNAME $PROCMAILLOG' >> /usr/bin/mailinglistrule
  echo 'fi' >> /usr/bin/mailinglistrule
  echo 'MUTT_MAILBOXES=$(grep "mailboxes =" $MUTTRC)' >> /usr/bin/mailinglistrule
  echo 'if [[ $MUTT_MAILBOXES != *$MAILINGLIST* ]]; then' >> /usr/bin/mailinglistrule
  echo '  sed -i "s|$MUTT_MAILBOXES|$MUTT_MAILBOXES =$MAILINGLIST|g" $MUTTRC' >> /usr/bin/mailinglistrule
  echo '  chown $MYUSERNAME:$MYUSERNAME $MUTTRC' >> /usr/bin/mailinglistrule
  echo 'fi' >> /usr/bin/mailinglistrule
  chmod +x /usr/bin/mailinglistrule
  echo 'folders_for_mailing_lists' >> $COMPLETION_FILE
}

function folders_for_email_addresses {
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      return
  fi
  if grep -Fxq "folders_for_email_addresses" $COMPLETION_FILE; then
      return
  fi
  echo '#!/bin/bash' > /usr/bin/emailrule
  echo 'MYUSERNAME=$1' >> /usr/bin/emailrule
  echo 'EMAILADDRESS=$2' >> /usr/bin/emailrule
  echo 'MAILINGLIST=$3' >> /usr/bin/emailrule
  echo 'MUTTRC=/home/$MYUSERNAME/.muttrc' >> /usr/bin/emailrule
  echo 'PM=/home/$MYUSERNAME/.procmailrc' >> /usr/bin/emailrule
  echo 'LISTDIR=/home/$MYUSERNAME/Maildir/$MAILINGLIST' >> /usr/bin/emailrule
  echo 'if ! [[ $MYUSERNAME && $EMAILADDRESS && $MAILINGLIST ]]; then' >> /usr/bin/emailrule
  echo '  echo "emailrule [user name] [email address] [mailing list name]"' >> /usr/bin/emailrule
  echo '  exit 1' >> /usr/bin/emailrule
  echo 'fi' >> /usr/bin/emailrule
  echo 'if [ ! -d "$LISTDIR" ]; then' >> /usr/bin/emailrule
  echo '  mkdir -m 700 $LISTDIR' >> /usr/bin/emailrule
  echo '  mkdir -m 700 $LISTDIR/tmp' >> /usr/bin/emailrule
  echo '  mkdir -m 700 $LISTDIR/new' >> /usr/bin/emailrule
  echo '  mkdir -m 700 $LISTDIR/cur' >> /usr/bin/emailrule
  echo 'fi' >> /usr/bin/emailrule
  echo 'chown -R $MYUSERNAME:$MYUSERNAME $LISTDIR' >> /usr/bin/emailrule
  echo 'echo "" >> $PM' >> /usr/bin/emailrule
  echo 'echo ":0" >> $PM' >> /usr/bin/emailrule
  echo 'echo "  * ^From: $EMAILADDRESS" >> $PM' >> /usr/bin/emailrule
  echo 'echo "$LISTDIR/new" >> $PM' >> /usr/bin/emailrule
  echo 'chown $MYUSERNAME:$MYUSERNAME $PM' >> /usr/bin/emailrule
  echo 'if [ ! -f "$MUTTRC" ]; then' >> /usr/bin/emailrule
  echo '  cp /etc/Muttrc $MUTTRC' >> /usr/bin/emailrule
  echo '  chown $MYUSERNAME:$MYUSERNAME $MUTTRC' >> /usr/bin/emailrule
  echo 'fi' >> /usr/bin/emailrule
  echo 'PROCMAILLOG=/home/$MYUSERNAME/log' >> /usr/bin/emailrule
  echo 'if [ ! -d $PROCMAILLOG ]; then' >> /usr/bin/emailrule
  echo '  mkdir $PROCMAILLOG' >> /usr/bin/emailrule
  echo '  chown -R $MYUSERNAME:$MYUSERNAME $PROCMAILLOG' >> /usr/bin/emailrule
  echo 'fi' >> /usr/bin/emailrule
  echo 'MUTT_MAILBOXES=$(grep "mailboxes =" $MUTTRC)' >> /usr/bin/emailrule
  echo 'if [[ $MUTT_MAILBOXES != *$MAILINGLIST* ]]; then' >> /usr/bin/emailrule
  echo '  sed -i "s|$MUTT_MAILBOXES|$MUTT_MAILBOXES =$MAILINGLIST|g" $MUTTRC' >> /usr/bin/emailrule
  echo '  chown $MYUSERNAME:$MYUSERNAME $MUTTRC' >> /usr/bin/emailrule
  echo 'fi' >> /usr/bin/emailrule
  chmod +x /usr/bin/emailrule
  echo 'folders_for_email_addresses' >> $COMPLETION_FILE
}

function dynamic_dns_freedns {
  if grep -Fxq "dynamic_dns_freedns" $COMPLETION_FILE; then
      return
  fi

  echo '#!/bin/bash' > /usr/bin/dynamicdns
  echo '# subdomain name 1' >> /usr/bin/dynamicdns
  echo "wget -O - https://freedns.afraid.org/dynamic/update.php?$FREEDNS_SUBDOMAIN_CODE== >> /dev/null 2>&1" >> /usr/bin/dynamicdns
  echo '# add any other subdomains below' >> /usr/bin/dynamicdns
  chmod 600 /usr/bin/dynamicdns
  chmod +x /usr/bin/dynamicdns

  if ! grep -q "dynamicdns" /etc/crontab; then
    sed -i '/# m h dom mon dow user command/a\*/5 * * * * root /usr/bin/timeout 240 /usr/bin/dynamicdns' /etc/crontab
  fi
  service cron restart
  echo 'dynamic_dns_freedns' >> $COMPLETION_FILE
}

function create_private_mailing_list {
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      return
  fi
  # This installation doesn't work, results in ruby errors
  # There is currently no schleuder package for Debian jessie
  if grep -Fxq "create_private_mailing_list" $COMPLETION_FILE; then
      return
  fi
  if [ ! $PRIVATE_MAILING_LIST ]; then
      return
  fi
  if [ $PRIVATE_MAILING_LIST == $MY_USERNAME ]; then
      echo 'The name of the private mailing list should not be the'
      echo 'same as your username'
      exit 10
  fi
  if [ ! $MY_GPG_PUBLIC_KEY ]; then
      echo 'To create a private mailing list you need to specify a file'
      echo 'containing your exported GPG key within MY_GPG_PUBLIC_KEY at'
      echo 'the top of the script'
      exit 11
  fi
  apt-get -y --force-yes install ruby ruby-dev ruby-gpgme libgpgme11-dev libmagic-dev
  gem install schleuder
  schleuder-fix-gem-dependencies
  schleuder-init-setup --gem
  # NOTE: this is version number sensitive and so might need changing
  ln -s /var/lib/gems/2.1.0/gems/schleuder-2.2.4 /var/lib/schleuder
  sed -i 's/#smtp_port: 25/smtp_port: 465/g' /etc/schleuder/schleuder.conf
  sed -i 's/#superadminaddr: root@localhost/superadminaddr: root@localhost' /etc/schleuder/schleuder.conf
  schleuder-newlist $PRIVATE_MAILING_LIST@$DOMAIN_NAME -realname "$PRIVATE_MAILING_LIST" -adminaddress $MY_USERNAME@$DOMAIN_NAME -initmember $MY_USERNAME@$DOMAIN_NAME -initmemberkey $MY_GPG_PUBLIC_KEY -nointeractive
  emailrule $MY_USERNAME $PRIVATE_MAILING_LIST@$DOMAIN_NAME $PRIVATE_MAILING_LIST

  echo 'schleuder:' > /etc/exim4/conf.d/router/550_exim4-config_schleuder
  echo '  debug_print = "R: schleuder for $local_part@$domain"' >> /etc/exim4/conf.d/router/550_exim4-config_schleuder
  echo '  driver = accept' >> /etc/exim4/conf.d/router/550_exim4-config_schleuder
  echo '  local_part_suffix_optional' >> /etc/exim4/conf.d/router/550_exim4-config_schleuder
  echo '  local_part_suffix = +* : -bounce : -sendkey' >> /etc/exim4/conf.d/router/550_exim4-config_schleuder
  echo '  domains = +local_domains' >> /etc/exim4/conf.d/router/550_exim4-config_schleuder
  echo '  user = schleuder' >> /etc/exim4/conf.d/router/550_exim4-config_schleuder
  echo '  group = schleuder' >> /etc/exim4/conf.d/router/550_exim4-config_schleuder
  echo '  require_files = schleuder:+/var/lib/schleuder/$domain/${local_part}' >> /etc/exim4/conf.d/router/550_exim4-config_schleuder
  echo '  transport = schleuder_transport' >> /etc/exim4/conf.d/router/550_exim4-config_schleuder

  echo 'schleuder_transport:' > /etc/exim4/conf.d/transport/30_exim4-config_schleuder
  echo '  debug_print = "T: schleuder_transport for $local_part@$domain"' >> /etc/exim4/conf.d/transport/30_exim4-config_schleuder
  echo '  driver = pipe' >> /etc/exim4/conf.d/transport/30_exim4-config_schleuder
  echo '  home_directory = "/var/lib/schleuder/$domain/$local_part"' >> /etc/exim4/conf.d/transport/30_exim4-config_schleuder
  echo '  command = "/usr/bin/schleuder $local_part@$domain"' >> /etc/exim4/conf.d/transport/30_exim4-config_schleuder
  chown -R schleuder:schleuder /var/lib/schleuder
  update-exim4.conf.template -r
  update-exim4.conf
  service exim4 restart
  useradd -d /var/schleuderlists -s /bin/false schleuder
  adduser Debian-exim schleuder
  usermod -a -G mail schleuder
  #exim -d -bt $PRIVATE_MAILING_LIST@$DOMAIN_NAME
  echo 'create_private_mailing_list' >> $COMPLETION_FILE
}

function import_email {
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      return
  fi
  EMAIL_COMPLETE_MSG='  *** Freedombone mailbox installation is complete ***'
  if grep -Fxq "import_email" $COMPLETION_FILE; then
      if [[ $SYSTEM_TYPE == "email" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" ]]; then
          echo $EMAIL_COMPLETE_MSG
          if [ -d /media/usb ]; then
              umount /media/usb
              rm -rf /media/usb
              echo '            You can now remove the USB drive'
          fi
          exit 0
      fi
      return
  fi
  if [ $IMPORT_MAILDIR ]; then
      if [ -d $IMPORT_MAILDIR ]; then
          echo 'Transfering email files'
          cp -r $IMPORT_MAILDIR /home/$MY_USERNAME
          chown -R $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/Maildir
      else
          echo "Email import directory $IMPORT_MAILDIR not found"
          exit 9
      fi
  fi
  echo 'import_email' >> $COMPLETION_FILE
  if [[ $SYSTEM_TYPE == "email" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" ]]; then
      apt-get -y --force-yes autoremove
      # unmount any attached usb drive
      echo ''
      echo $EMAIL_COMPLETE_MSG
      echo ''
      if [ -d /media/usb ]; then
          umount /media/usb
          rm -rf /media/usb
          echo '            You can now remove the USB drive'
      fi
      exit 0
  fi
}

function install_web_server {
  if [[ $SYSTEM_TYPE == "$VARIANT_CHAT" ]]; then
      return
  fi
  if grep -Fxq "install_web_server" $COMPLETION_FILE; then
      return
  fi
  # remove apache
  apt-get -y remove --purge apache2
  if [ -d /etc/apache2 ]; then
    rm -rf /etc/apache2
  fi
  # install nginx
  apt-get -y --force-yes install nginx php5-fpm git
  # install a script to easily enable and disable nginx virtual hosts
  if [ ! -d $INSTALL_DIR ]; then
      mkdir $INSTALL_DIR
  fi
  cd $INSTALL_DIR
  git clone https://github.com/perusio/nginx_ensite
  cd $INSTALL_DIR/nginx_ensite
  cp nginx_* /usr/sbin
  nginx_dissite default
  echo 'install_web_server' >> $COMPLETION_FILE
}

function configure_php {
  sed -i "s/memory_limit = 128M/memory_limit = $MAX_PHP_MEMORYM/g" /etc/php5/fpm/php.ini
  sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php5/fpm/php.ini
  sed -i "s/memory_limit = -1/memory_limit = $MAX_PHP_MEMORYM/g" /etc/php5/cli/php.ini
  sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 50M/g" /etc/php5/fpm/php.ini
  sed -i "s/post_max_size = 8M/post_max_size = 50M/g" /etc/php5/fpm/php.ini
  sed -i "s/memory_limit = /memory_limit = $MAX_PHP_MEMORYM/g" /etc/php5/cli/php.ini
  sed -i "s/memory_limit = /memory_limit = $MAX_PHP_MEMORYM/g" /etc/php5/fpm/php.ini
}

function install_owncloud {
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "email" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      return
  fi
  OWNCLOUD_COMPLETION_MSG1=" *** Freedombone $SYSTEM_TYPE is now installed ***"
  OWNCLOUD_COMPLETION_MSG2="Open $OWNCLOUD_DOMAIN_NAME in a web browser to complete the setup"
  if grep -Fxq "install_owncloud" $COMPLETION_FILE; then
      if [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" ]]; then
          # unmount any attached usb drive
          if [ -d /media/usb ]; then
              umount /media/usb
              rm -rf /media/usb
          fi
          echo ''
          echo $OWNCLOUD_COMPLETION_MSG1
          echo $OWNCLOUD_COMPLETION_MSG2
          exit 0
      fi
      return
  fi
  # if this is exclusively a cloud setup
  if [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" ]]; then
      OWNCLOUD_DOMAIN_NAME=$DOMAIN_NAME
      OWNCLOUD_FREEDNS_SUBDOMAIN_CODE=$FREEDNS_SUBDOMAIN_CODE
  fi
  if [ ! $OWNCLOUD_DOMAIN_NAME ]; then
      return
  fi
  if ! [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" ]]; then
      if [ ! $SYSTEM_TYPE ]; then
          return
      fi
  fi
  apt-get -y --force-yes install php5 php5-gd php-xml-parser php5-intl wget
  apt-get -y --force-yes install php5-sqlite php5-mysql smbclient curl libcurl3 php5-curl bzip2

  if [ ! -d /var/www/$OWNCLOUD_DOMAIN_NAME ]; then
      mkdir /var/www/$OWNCLOUD_DOMAIN_NAME
      mkdir /var/www/$OWNCLOUD_DOMAIN_NAME/htdocs
  fi

  echo 'server {' > /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    listen 80;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo "    server_name $OWNCLOUD_DOMAIN_NAME;" >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    rewrite ^ https://$server_name$request_uri? permanent;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '}' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME

  echo 'server {' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    listen 443 ssl;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo "    root /var/www/$OWNCLOUD_DOMAIN_NAME/htdocs;" >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo "    server_name $OWNCLOUD_DOMAIN_NAME;" >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME

  echo '    ssl on;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo "    ssl_certificate /etc/ssl/certs/$OWNCLOUD_DOMAIN_NAME.crt;" >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo "    ssl_certificate_key /etc/ssl/private/$OWNCLOUD_DOMAIN_NAME.key;" >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo "    ssl_dhparam /etc/ssl/certs/$OWNCLOUD_DOMAIN_NAME.dhparam;" >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME

  echo '    ssl_session_timeout 5m;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    ssl_prefer_server_ciphers on;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # not possible to do exclusive' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo "    ssl_ciphers 'EDH+CAMELLIA:EDH+aRSA:EECDH+aRSA+AESGCM:EECDH+aRSA+SHA384:EECDH+aRSA+SHA256:EECDH:+CAMELLIA256:+AES256:+CAMELLIA128:+AES128:+SSLv3:!aNULL:!eNULL:!LOW:!3DES:!MD5:!EXP:!PSK:!DSS:!RC4:!SEED:!ECDSA:CAMELLIA256-SHA:AES256-SHA:CAMELLIA128-SHA:AES128-SHA';" >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    add_header X-Frame-Options DENY;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    add_header X-Content-Type-Options nosniff;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    add_header Strict-Transport-Security max-age=15768000;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    # if you want to be able to access the site via HTTP' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    # then replace the above with the following:' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    # add_header Strict-Transport-Security "max-age=0;";' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME

  echo "    # make sure webfinger and other well known services aren't blocked" >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    # by denying dot files and rewrite request to the front controller' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    location ^~ /.well-known/ {' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '        allow all;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '        rewrite ^/(.*) /index.php?q=$uri&$args last;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME

  echo '    client_max_body_size 10G; # set max upload size' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    client_body_buffer_size 128k;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    fastcgi_buffers 64 4K;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME

  echo '    rewrite ^/caldav(.*)$ /remote.php/caldav$1 redirect;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    rewrite ^/carddav(.*)$ /remote.php/carddav$1 redirect;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    rewrite ^/webdav(.*)$ /remote.php/webdav$1 redirect;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME

  echo '    index index.php;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    error_page 403 /core/templates/403.php;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    error_page 404 /core/templates/404.php;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME

  echo '    location = /robots.txt {' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '        allow all;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '        log_not_found off;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '        access_log off;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME

  echo '    location ~ ^/(data|config|\.ht|db_structure\.xml|README) {' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '        deny all;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME

  echo '    location / {' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '        # The following 2 rules are only needed with webfinger' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '        rewrite ^/.well-known/host-meta /public.php?service=host-meta last;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '        rewrite ^/.well-known/host-meta.json /public.php?service=host-meta-json last;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME

  echo '        rewrite ^/.well-known/carddav /remote.php/carddav/ redirect;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '        rewrite ^/.well-known/caldav /remote.php/caldav/ redirect;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME

  echo '        rewrite ^(/core/doc/[^\/]+/)$ $1/index.html;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME

  echo '        try_files $uri $uri/ index.php;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME

  echo '    location ~ ^(.+?\.php)(/.*)?$ {' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '        try_files $1 =404;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '        fastcgi_split_path_info ^(.+\.php)(/.+)$;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '        fastcgi_pass unix:/var/run/php5-fpm.sock;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '        fastcgi_index index.php;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '        include fastcgi_params;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '        fastcgi_param SCRIPT_FILENAME $document_root$1;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '        fastcgi_param PATH_INFO $2;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '        fastcgi_param HTTPS on;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME

  echo '    # Optional: set long EXPIRES header on static assets' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    location ~* ^.+\.(jpg|jpeg|gif|bmp|ico|png|css|js|swf)$ {' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '        expires 30d;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo "        # Optional: Don't log access to assets" >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '        access_log off;' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo '}' >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME

  configure_php

  if [ ! -f /etc/ssl/private/$OWNCLOUD_DOMAIN_NAME.key ]; then
      makecert $OWNCLOUD_DOMAIN_NAME
  fi

  # download owncloud
  cd $INSTALL_DIR
  if [ ! -f $INSTALL_DIR/$OWNCLOUD_ARCHIVE ]; then
      wget $OWNCLOUD_DOWNLOAD
  fi
  if [ ! -f $INSTALL_DIR/$OWNCLOUD_ARCHIVE ]; then
      echo 'Owncloud could not be downloaded.  Check that it exists at '
      echo $OWNCLOUD_DOWNLOAD
      echo 'And if neccessary update the version number and hash within this script'
      exit 18
  fi
  # Check that the hash is correct
  CHECKSUM=$(sha256sum $OWNCLOUD_ARCHIVE | awk -F ' ' '{print $1}')
  if [[ $CHECKSUM != $OWNCLOUD_HASH ]]; then
      echo 'The sha256 hash of the owncloud download is incorrect. Possibly the file may have been tampered with. Check the hash on the Owncloud web site.'
      exit 19
  fi
  tar -xjf $OWNCLOUD_ARCHIVE
  echo 'Copying files...'
  cp -r owncloud/* /var/www/$OWNCLOUD_DOMAIN_NAME/htdocs
  chown -R www-data:www-data /var/www/$OWNCLOUD_DOMAIN_NAME/htdocs/apps
  chown -R www-data:www-data /var/www/$OWNCLOUD_DOMAIN_NAME/htdocs/config
  chown www-data:www-data /var/www/$OWNCLOUD_DOMAIN_NAME/htdocs

  nginx_ensite $OWNCLOUD_DOMAIN_NAME
  service php5-fpm restart
  service nginx restart

  # update the dynamic DNS
  if [[ $OWNCLOUD_FREEDNS_SUBDOMAIN_CODE != $FREEDNS_SUBDOMAIN_CODE ]]; then
      if ! grep -q "$OWNCLOUD_DOMAIN_NAME" /usr/bin/dynamicdns; then
          echo "# $OWNCLOUD_DOMAIN_NAME" >> /usr/bin/dynamicdns
          echo "wget -O - https://freedns.afraid.org/dynamic/update.php?$OWNCLOUD_FREEDNS_SUBDOMAIN_CODE== >> /dev/null 2>&1" >> /usr/bin/dynamicdns
      fi
  fi

  echo 'install_owncloud' >> $COMPLETION_FILE

  if [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" ]]; then
      # unmount any attached usb drive
      if [ -d /media/usb ]; then
          umount /media/usb
          rm -rf /media/usb
      fi
      echo ''
      echo $OWNCLOUD_COMPLETION_MSG1
      echo $OWNCLOUD_COMPLETION_MSG2
      exit 0
  fi
}

function install_xmpp {
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "email" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      return
  fi
  if grep -Fxq "install_xmpp" $COMPLETION_FILE; then
      return
  fi
  apt-get -y --force-yes install prosody
  if [ ! -f "/etc/ssl/private/xmpp.key" ]; then
      makecert xmpp
  fi
  chown prosody:prosody /etc/ssl/private/xmpp.key
  chown prosody:prosody /etc/ssl/certs/xmpp.*
  cp -a /etc/prosody/conf.avail/example.com.cfg.lua /etc/prosody/conf.avail/xmpp.cfg.lua

  sed -i 's|/etc/prosody/certs/example.com.key|/etc/ssl/private/xmpp.key|g' /etc/prosody/conf.avail/xmpp.cfg.lua
  sed -i 's|/etc/prosody/certs/example.com.crt|/etc/ssl/certs/xmpp.crt|g' /etc/prosody/conf.avail/xmpp.cfg.lua
  if ! grep -q "xmpp.dhparam" /etc/prosody/conf.avail/xmpp.cfg.lua; then
      sed -i '/certificate =/a\              dhparam = "/etc/ssl/certs/xmpp.dhparam";' /etc/prosody/conf.avail/xmpp.cfg.lua
  fi
  sed -i "s/example.com/$DOMAIN_NAME/g" /etc/prosody/conf.avail/xmpp.cfg.lua
  sed -i 's/enabled = false -- Remove this line to enable this host//g' /etc/prosody/conf.avail/xmpp.cfg.lua

  if ! grep -q "modules_enabled" /etc/prosody/conf.avail/xmpp.cfg.lua; then
      echo '' >> /etc/prosody/conf.avail/xmpp.cfg.lua
      echo 'modules_enabled = {' >> /etc/prosody/conf.avail/xmpp.cfg.lua
      echo '  "bosh"; -- Enable mod_bosh' >> /etc/prosody/conf.avail/xmpp.cfg.lua
      echo '  "tls"; -- Enable mod_tls' >> /etc/prosody/conf.avail/xmpp.cfg.lua
      echo '  "saslauth"; -- Enable mod_saslauth' >> /etc/prosody/conf.avail/xmpp.cfg.lua
      echo '}' >> /etc/prosody/conf.avail/xmpp.cfg.lua
      echo '' >> /etc/prosody/conf.avail/xmpp.cfg.lua
      echo 'c2s_require_encryption = true' >> /etc/prosody/conf.avail/xmpp.cfg.lua
      echo 's2s_require_encryption = true' >> /etc/prosody/conf.avail/xmpp.cfg.lua
      echo 'allow_unencrypted_plain_auth = false' >> /etc/prosody/conf.avail/xmpp.cfg.lua
  fi
  ln -sf /etc/prosody/conf.avail/xmpp.cfg.lua /etc/prosody/conf.d/xmpp.cfg.lua

  sed -i 's|/etc/prosody/certs/localhost.key|/etc/ssl/private/xmpp.key|g' /etc/prosody/prosody.cfg.lua
  sed -i 's|/etc/prosody/certs/localhost.crt|/etc/ssl/certs/xmpp.crt|g' /etc/prosody/prosody.cfg.lua
  if ! grep -q "xmpp.dhparam" /etc/prosody/prosody.cfg.lua; then
      sed -i '/certificate =/a\      dhparam = "/etc/ssl/certs/xmpp.dhparam";' /etc/prosody/prosody.cfg.lua
  fi
  sed -i 's/c2s_require_encryption = false/c2s_require_encryption = true/g' /etc/prosody/prosody.cfg.lua
  if ! grep -q "s2s_require_encryption" /etc/prosody/prosody.cfg.lua; then
      sed -i '/c2s_require_encryption/a\s2s_require_encryption = true' /etc/prosody/prosody.cfg.lua
  fi
  if ! grep -q "allow_unencrypted_plain_auth" /etc/prosody/prosody.cfg.lua; then
      echo 'allow_unencrypted_plain_auth = false' >> /etc/prosody/conf.avail/xmpp.cfg.lua
  fi
  sed -i 's/--"bosh";/"bosh";/g' /etc/prosody/prosody.cfg.lua
  sed -i 's/authentication = "internal_plain"/authentication = "internal_hashed"/g' /etc/prosody/prosody.cfg.lua
  sed -i 's/enabled = false -- Remove this line to enable this host//g' /etc/prosody/prosody.cfg.lua
  sed -i 's/example.com/$DOMAIN_NAME/g' /etc/prosody/prosody.cfg.lua

  service prosody restart
  touch /home/$MY_USERNAME/README

  if ! grep -q "Your XMPP password is" /home/$MY_USERNAME/README; then
      XMPP_PASSWORD=$(openssl rand -base64 8)
      prosodyctl register $MY_USERNAME $DOMAIN_NAME $XMPP_PASSWORD
      echo "Your XMPP password is: $XMPP_PASSWORD" >> /home/$MY_USERNAME/README
      echo 'You can change it with: ' >> /home/$MY_USERNAME/README
      echo '' >> /home/$MY_USERNAME/README
      echo "    prosodyctl passwd $MY_USERNAME@$DOMAIN_NAME" >> /home/$MY_USERNAME/README
      chown $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/README
  fi
  echo 'install_xmpp' >> $COMPLETION_FILE
}

function install_irc_server {
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "email" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      return
  fi
  if grep -Fxq "install_irc_server" $COMPLETION_FILE; then
      return
  fi
  apt-get -y --force-yes install ngircd
  if [ ! "/etc/ssl/private/ngircd.key" ]; then
      makecert ngircd
  fi

  echo '**************************************************' > /etc/ngircd/motd
  echo '*           F R E E D O M B O N E   I R C        *' >> /etc/ngircd/motd
  echo '*                                                *' >> /etc/ngircd/motd
  echo '*               Freedom in the Cloud             *' >> /etc/ngircd/motd
  echo '**************************************************' >> /etc/ngircd/motd
  sed -i 's|MotdFile = /etc/ngircd/ngircd.motd|MotdFile = /etc/ngircd/motd|g' /etc/ngircd/ngircd.conf
  sed -i "s/irc@irc.example.com/$MY_USERNAME@$DOMAIN_NAME/g" /etc/ngircd/ngircd.conf
  sed -i "s/irc.example.net/$DOMAIN_NAME/g" /etc/ngircd/ngircd.conf
  sed -i "s|Yet another IRC Server running on Debian GNU/Linux|IRC Server of $DOMAIN_NAME|g" /etc/ngircd/ngircd.conf
  sed -i 's/;Password = wealllikedebian/Password =/g' /etc/ngircd/ngircd.conf
  sed -i 's|;CertFile = /etc/ssl/certs/server.crt|CertFile = /etc/ssl/certs/ngircd.crt|g' /etc/ngircd/ngircd.conf
  sed -i 's|;DHFile = /etc/ngircd/dhparams.pem|DHFile = /etc/ssl/certs/ngircd.dhparam|g' /etc/ngircd/ngircd.conf
  sed -i 's|;KeyFile = /etc/ssl/private/server.key|KeyFile = /etc/ssl/private/ngircd.key|g' /etc/ngircd/ngircd.conf
  sed -i 's/;Ports = 6697, 9999/Ports = 6697, 9999/g' /etc/ngircd/ngircd.conf
  sed -i 's/;Name = #ngircd/Name = #freedombone/g' /etc/ngircd/ngircd.conf
  sed -i 's/;Topic = Our ngircd testing channel/Topic = Freedombone chat channel/g' /etc/ngircd/ngircd.conf
  sed -i 's/;MaxUsers = 23/MaxUsers = 23/g' /etc/ngircd/ngircd.conf
  sed -i 's|;KeyFile = /etc/ngircd/#chan.key|KeyFile = /etc/ngircd/#freedombone.key|g' /etc/ngircd/ngircd.conf
  sed -i 's/;CloakHost = cloaked.host/CloakHost = cloaked.host/g' /etc/ngircd/ngircd.conf
  IRC_SALT=$(openssl rand -base64 32)
  IRC_OPERATOR_PASSWORD=$(openssl rand -base64 8)
  sed -i "s|;CloakHostSalt = abcdefghijklmnopqrstuvwxyz|CloakHostSalt = $IRC_SALT|g" /etc/ngircd/ngircd.conf
  sed -i 's/;ConnectIPv4 = yes/ConnectIPv4 = yes/g' /etc/ngircd/ngircd.conf
  sed -i 's/;MorePrivacy = no/MorePrivacy = yes/g' /etc/ngircd/ngircd.conf
  sed -i 's/;RequireAuthPing = no/RequireAuthPing = no/g' /etc/ngircd/ngircd.conf
  sed -i "s/;Name = TheOper/Name = $MY_USERNAME/g" /etc/ngircd/ngircd.conf
  sed -i "s/;Password = ThePwd/Password = $IRC_OPERATOR_PASSWORD/g" /etc/ngircd/ngircd.conf
  service ngircd restart
  echo 'install_irc_server' >> $COMPLETION_FILE
}

function install_wiki {
  if [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "email" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      return
  fi
  if grep -Fxq "install_wiki" $COMPLETION_FILE; then
      return
  fi
  # if this is exclusively a writer setup
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" ]]; then
      WIKI_DOMAIN_NAME=$DOMAIN_NAME
      WIKI_FREEDNS_SUBDOMAIN_CODE=$FREEDNS_SUBDOMAIN_CODE
  fi
  if [ ! $WIKI_DOMAIN_NAME ]; then
      return
  fi
  if ! [[ $SYSTEM_TYPE == "$VARIANT_WRITER" ]]; then
      if [ ! $SYSTEM_TYPE ]; then
          return
      fi
  fi
  apt-get -y --force-yes install php5 php5-gd php-xml-parser php5-intl wget
  apt-get -y --force-yes install php5-sqlite php5-mysql smbclient curl libcurl3 php5-curl bzip2

  if [ ! -d /var/www/$WIKI_DOMAIN_NAME ]; then
      mkdir /var/www/$WIKI_DOMAIN_NAME
  fi
  if [ ! -d /var/www/$WIKI_DOMAIN_NAME/htdocs ]; then
      mkdir /var/www/$WIKI_DOMAIN_NAME/htdocs
  fi

  if [ ! -f /etc/ssl/private/$WIKI_DOMAIN_NAME.key ]; then
      makecert $WIKI_DOMAIN_NAME
  fi

  # download the archive
  cd $INSTALL_DIR
  if [ ! -f $INSTALL_DIR/$WIKI_ARCHIVE ]; then
      wget $WIKI_DOWNLOAD
  fi
  if [ ! -f $INSTALL_DIR/$WIKI_ARCHIVE ]; then
      echo 'Dokuwiki could not be downloaded.  Check that it exists at '
      echo $WIKI_DOWNLOAD
      echo 'And if neccessary update the version number and hash within this script'
      exit 18
  fi
  # Check that the hash is correct
  CHECKSUM=$(sha256sum $WIKI_ARCHIVE | awk -F ' ' '{print $1}')
  if [[ $CHECKSUM != $WIKI_HASH ]]; then
      echo 'The sha256 hash of the Dokuwiki download is incorrect. Possibly the file may have been tampered with. Check the hash on the Dokuwiki web site.'
      exit 21
  fi

  tar -xzvf $WIKI_ARCHIVE
  cd dokuwiki-*
  mv * /var/www/$WIKI_DOMAIN_NAME/htdocs/
  chmod -R 755 /var/www/$WIKI_DOMAIN_NAME/htdocs
  chown -R www-data:www-data /var/www/$WIKI_DOMAIN_NAME/htdocs

  if ! grep -q "video/ogg" /var/www/$WIKI_DOMAIN_NAME/htdocs/conf/mime.conf; then
      echo 'ogv     video/ogg' >> /var/www/$WIKI_DOMAIN_NAME/htdocs/conf/mime.conf
      echo 'mp4     video/mp4' >> /var/www/$WIKI_DOMAIN_NAME/htdocs/conf/mime.conf
      echo 'webm    video/webm' >> /var/www/$WIKI_DOMAIN_NAME/htdocs/conf/mime.conf
  fi

  echo 'server {' > /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    listen 80;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo "    server_name $WIKI_DOMAIN_NAME;" >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo "    root /var/www/$WIKI_DOMAIN_NAME/htdocs;" >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo "    error_log /var/www/$WIKI_DOMAIN_NAME/error.log;" >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    index index.php;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    # Uncomment this if you need to redirect HTTP to HTTPS' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    #rewrite ^ https://$server_name$request_uri? permanent;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    location / {' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        try_files $uri $uri/ /index.php;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    location ~ \.php$ {' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        fastcgi_split_path_info ^(.+\.php)(/.+)$;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        fastcgi_pass unix:/var/run/php5-fpm.sock;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        fastcgi_index index.php;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        include fastcgi_params;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '}' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo 'server {' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    listen 443 ssl;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo "    root /var/www/$WIKI_DOMAIN_NAME/htdocs;" >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo "    server_name $WIKI_DOMAIN_NAME;" >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo "    error_log /var/www/$WIKI_DOMAIN_NAME/error_ssl.log;" >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    index index.php;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    charset utf-8;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    client_max_body_size 20m;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    client_body_buffer_size 128k;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    ssl on;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo "    ssl_certificate /etc/ssl/certs/$WIKI_DOMAIN_NAME.crt;" >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo "    ssl_certificate_key /etc/ssl/private/$WIKI_DOMAIN_NAME.key;" >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo "    ssl_dhparam /etc/ssl/certs/$WIKI_DOMAIN_NAME.dhparam;" >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    ssl_session_timeout 5m;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    ssl_prefer_server_ciphers on;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    ssl_session_cache  builtin:1000  shared:SSL:10m;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # not possible to do exclusive' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo "    ssl_ciphers 'EDH+CAMELLIA:EDH+aRSA:EECDH+aRSA+AESGCM:EECDH+aRSA+SHA384:EECDH+aRSA+SHA256:EECDH:+CAMELLIA256:+AES256:+CAMELLIA128:+AES128:+SSLv3:!aNULL:!eNULL:!LOW:!3DES:!MD5:!EXP:!PSK:!DSS:!RC4:!SEED:!ECDSA:CAMELLIA256-SHA:AES256-SHA:CAMELLIA128-SHA:AES128-SHA';" >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    add_header X-Frame-Options DENY;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    add_header X-Content-Type-Options nosniff;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    add_header Strict-Transport-Security "max-age=0;";' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    # rewrite to front controller as default rule' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    location / {' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        rewrite ^/(.*) /index.php?q=$uri&$args last;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo "    # make sure webfinger and other well known services aren't blocked" >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    # by denying dot files and rewrite request to the front controller' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    location ^~ /.well-known/ {' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        allow all;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        rewrite ^/(.*) /index.php?q=$uri&$args last;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    # statically serve these file types when possible' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    # otherwise fall back to front controller' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    # allow browser to cache them' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    # added .htm for advanced source code editor library' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    location ~* \.(jpg|jpeg|gif|png|ico|css|js|htm|html|ttf|woff|svg)$ {' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        expires 30d;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        try_files $uri /index.php?q=$uri&$args;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    # block these file types' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    location ~* \.(tpl|md|tgz|log|out)$ {' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        deny all;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    # or a unix socket' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    location ~* \.php$ {' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        # Zero-day exploit defense.' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        # http://forum.nginx.org/read.php?2,88845,page=3' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo "        # Won't work properly (404 error) if the file is not stored on this" >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo "        # server, which is entirely possible with php-fpm/php-fcgi." >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo "        # Comment the 'try_files' line out if you set up php-fpm/php-fcgi on" >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo "        # another machine. And then cross your fingers that you won't get hacked." >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo "        try_files $uri /dev/null =404;" >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        # NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        fastcgi_split_path_info ^(.+\.php)(/.+)$;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        # With php5-cgi alone:' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        # fastcgi_pass 127.0.0.1:9000;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        # With php5-fpm:' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        fastcgi_pass unix:/var/run/php5-fpm.sock;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        include fastcgi_params;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        fastcgi_index index.php;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    # deny access to all dot files' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    location ~ /\. {' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        deny all;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    #deny access to store' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    location ~ /store {' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '        deny all;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '}' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME

  configure_php

  nginx_ensite $WIKI_DOMAIN_NAME
  service php5-fpm restart
  service nginx restart

  # update the dynamic DNS
  if [[ $WIKI_FREEDNS_SUBDOMAIN_CODE != $FREEDNS_SUBDOMAIN_CODE ]]; then
      if ! grep -q "$WIKI_DOMAIN_NAME" /usr/bin/dynamicdns; then
          echo "# $WIKI_DOMAIN_NAME" >> /usr/bin/dynamicdns
          echo "wget -O - https://freedns.afraid.org/dynamic/update.php?$WIKI_FREEDNS_SUBDOMAIN_CODE== >> /dev/null 2>&1" >> /usr/bin/dynamicdns
      fi
  fi

  # add some post-install instructions
  if ! grep -q "Once you have set up the wiki" /home/$MY_USERNAME/README; then
      echo '' >> /home/$MY_USERNAME/README
      echo 'Once you have set up the wiki then remove the install file:' >> /home/$MY_USERNAME/README
      echo '' >> /home/$MY_USERNAME/README
      echo "  rm /var/www/$WIKI_DOMAIN_NAME/htdocs/install.php" >> /home/$MY_USERNAME/README
  fi

  echo 'install_wiki' >> $COMPLETION_FILE
}

function install_blog {
  if [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "email" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      return
  fi
  if grep -Fxq "install_blog" $COMPLETION_FILE; then
      return
  fi
  if [ ! -f $WIKI_DOMAIN_NAME ]; then
      return
  fi

  # download mnml-blog
  cd $INSTALL_DIR
  rm -f latest
  wget $WIKI_MNML_BLOG_ADDON
  if [ ! -f "$INSTALL_DIR/latest" ]; then
      echo 'Dokuwiki mnml-blog addon could not be downloaded. Check the Dokuwiki web site and alter WIKI_MNML_BLOG_ADDON at the top of this script as needed.'
      exit 21
  fi
  mv latest $WIKI_MNML_BLOG_ADDON_ARCHIVE

  # Check that the mnml-blog download hash is correct
  CHECKSUM=$(sha256sum $WIKI_MNML_BLOG_ADDON_ARCHIVE | awk -F ' ' '{print $1}')
  if [[ $CHECKSUM != $WIKI_MNML_BLOG_ADDON_HASH ]]; then
      echo 'The sha256 hash of the mnml-blog download is incorrect. Possibly the file may have been tampered with. Check the hash on the Dokuwiki mnmlblog web site and alter WIKI_MNML_BLOG_ADDON_HASH if needed.'
      exit 22
  fi

  # download blogTNG
  wget $WIKI_BLOGTNG_ADDON
  if [ ! -f "$INSTALL_DIR/master" ]; then
      echo 'Dokuwiki blogTNG addon could not be downloaded. Check the Dokuwiki web site and alter WIKI_BLOGTNG_ADDON at the top of this script as needed.'
      exit 23
  fi
  mv master $WIKI_BLOGTNG_ADDON_ARCHIVE

  # Check that the blogTNG hash is correct
  CHECKSUM=$(sha256sum $WIKI_BLOGTNG_ADDON_ARCHIVE | awk -F ' ' '{print $1}')
  if [[ $CHECKSUM != $WIKI_BLOGTNG_ADDON_HASH ]]; then
      echo 'The sha256 hash of the blogTNG download is incorrect. Possibly the file may have been tampered with. Check the hash on the Dokuwiki blogTNG web site and alter WIKI_BLOGTNG_ADDON_HASH if needed.'
      exit 24
  fi

  # install blogTNG
  unzip $WIKI_BLOGTNG_ADDON_ARCHIVE
  mv $WIKI_BLOGTNG_ADDON_NAME blogtng
  cp blogtng /var/www/$WIKI_DOMAIN_NAME/htdocs/lib/plugins/

  # install mnml-blog
  tar -xzvf $WIKI_MNML_BLOG_ADDON_ARCHIVE
  cp mnml-blog /var/www/$WIKI_DOMAIN_NAME/htdocs/lib/tpl/
  cp -r /var/www/$WIKI_DOMAIN_NAME/htdocs/lib/tpl/mnml-blog/blogtng-tpl/* /var/www/$WIKI_DOMAIN_NAME/htdocs/lib/plugins/blogtng/tpl/default/

  echo 'install_blog' >> $COMPLETION_FILE
}

function install_final {
  if grep -Fxq "install_final" $COMPLETION_FILE; then
      return
  fi
  # unmount any attached usb drive
  if [ -d /media/usb ]; then
      umount /media/usb
      rm -rf /media/usb
  fi
  apt-get -y --force-yes autoremove
  echo 'install_final' >> $COMPLETION_FILE
  echo ''
  echo '  *** Freedombone installation is complete. Rebooting... ***'
  echo ''
  reboot
}

argument_checks
configure_firewall
configure_firewall_for_ssh
configure_firewall_for_dns
configure_firewall_for_ftp
configure_firewall_for_web_access
remove_proprietary_repos
change_debian_repos
enable_backports
configure_dns
initial_setup
install_editor
change_login_message
update_the_kernel
enable_zram
random_number_generator
set_your_domain_name
time_synchronisation
configure_internet_protocol
configure_ssh
search_for_attached_usb_drive
regenerate_ssh_keys
script_to_make_self_signed_certificates
configure_email
#spam_filtering
configure_imap
configure_gpg
email_client
configure_firewall_for_email
folders_for_mailing_lists
folders_for_email_addresses
dynamic_dns_freedns
#create_private_mailing_list
import_email
install_web_server
configure_firewall_for_web_server
install_owncloud
install_xmpp
configure_firewall_for_xmpp
install_irc_server
configure_firewall_for_irc
install_wiki
install_blog
install_final
echo 'Freedombone installation is complete'
exit 0
