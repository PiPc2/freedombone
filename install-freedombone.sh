#!/bin/bash
#
# .---.                  .              .
# |                      |              |
# |--- .--. .-.  .-.  .-.|  .-. .--.--. |.-.  .-. .--.  .-.
# |    |   (.-' (.-' (   | (   )|  |  | |   )(   )|  | (.-'
# '    '     --'  --'  -' -  -' '  '   -' -'   -' '   -  --'
#
#                    Freedom in the Cloud
#
# This install script is intended for use with Debian Jessie
#
# Please note that the various hashes and download archives
# for systems such as Owncloud and Dokuwiki may need to be updated
#
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
#
# Summary
# =======
#
# This script is intended to be run on the target device, which
# is typically a Beaglebone Black.
#
# To be able to run this script you need to get to a condition
# where you have Debian Jessie installed, with at least one
# unprivileged user account and at least one subdomain created on
# https://freedns.afraid.org/. If you're not installing on a
# Beaglebone Black then set the variable INSTALLING_ON_BBB to "no"
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
# You will need to initially prepare a microSD card with a Debian
# image on it. This can be done using the initial_setup.sh script.
#
# If you are not using a Beaglebone Black then just prepare the
# target system with a fresh installation of Debian Jessie.

DOMAIN_NAME=$1
MY_USERNAME=$2
FREEDNS_SUBDOMAIN_CODE=$3
SYSTEM_TYPE=$4

# Are we installing on a Beaglebone Black (BBB) or some other system?
INSTALLING_ON_BBB="yes"

# Different system variants which may be specified within
# the SYSTEM_TYPE option
VARIANT_WRITER="writer"
VARIANT_CLOUD="cloud"
VARIANT_CHAT="chat"
VARIANT_MAILBOX="mailbox"
VARIANT_NONMAILBOX="nonmailbox"
VARIANT_SOCIAL="social"
VARIANT_MEDIA="media"

SSH_PORT=2222

# kernel specifically tweaked for the Beaglebone Black
KERNEL_VERSION="v3.15.10-bone7"

# Whether or not to use the beaglebone's hardware random number generator
USE_HWRNG="yes"

# Whether this system is being installed within a docker container
INSTALLED_WITHIN_DOCKER="no"

# If you want to run an encrypted mailing list specify its name here.
# There should be no spaces in the name
PRIVATE_MAILING_LIST=

# Domain name or freedns subdomain for mediagoblin installation
MEDIAGOBLIN_DOMAIN_NAME=
MEDIAGOBLIN_FREEDNS_SUBDOMAIN_CODE=
MEDIAGOBLIN_REPO=""
MEDIAGOBLIN_ADMIN_PASSWORD=

# Domain name or freedns subdomain for microblog installation
MICROBLOG_DOMAIN_NAME=
MICROBLOG_FREEDNS_SUBDOMAIN_CODE=
MICROBLOG_REPO="git://gitorious.org/social/mainline.git"
MICROBLOG_ADMIN_PASSWORD=

# Domain name or redmatrix installation
REDMATRIX_DOMAIN_NAME=
REDMATRIX_FREEDNS_SUBDOMAIN_CODE=
REDMATRIX_REPO="https://github.com/friendica/red.git"
REDMATRIX_ADDONS_REPO="https://github.com/friendica/red-addons.git"
REDMATRIX_ADMIN_PASSWORD=

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
WIKI_BLOGTNG_ADDON_HASH="212b3ad918fdc92b2d49ef5d36bc9e086eab27532931ba6b87e05f35fd402a27"

# see https://www.dokuwiki.org/plugin:sqlite
WIKI_SQLITE_ADDON_NAME="cosmocode-sqlite-7be4003"
WIKI_SQLITE_ADDON_ARCHIVE="$WIKI_SQLITE_ADDON_NAME.tar.gz"
WIKI_SQLITE_ADDON="https://github.com/cosmocode/sqlite/tarball/master"
WIKI_SQLITE_ADDON_HASH="930335e647c7e62f3068689c256ee169fad2426b64f8360685d391ecb5eeda0c"

GPG_KEYSERVER="hkp://keys.gnupg.net"

# whether to encrypt all incoming email with your public key
GPG_ENCRYPT_STORED_EMAIL="yes"

# gets set to yes if gpg keys are imported from usb
GPG_KEYS_IMPORTED="no"

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
DEBIAN_REPO="ftp.us.debian.org"

DEBIAN_VERSION="jessie"

# Directory where source code is downloaded and compiled
INSTALL_DIR=$HOME/build

# device name for an attached usb drive
USB_DRIVE=/dev/sda1

# Location where the USB drive is mounted to
USB_MOUNT=/mnt/usb

# Name of a script used to create a backup of the system on usb drive
BACKUP_SCRIPT_NAME="backup"

# Name of a script used to restore the system from usb drive
RESTORE_SCRIPT_NAME="restore"

# memory limit for php in MB
MAX_PHP_MEMORY=32

# default MariaDB password
MARIADB_PASSWORD=

#list of encryption protocols
SSL_PROTOCOLS="TLSv1 TLSv1.1 TLSv1.2"

# list of ciphers to use.  See bettercrypto.org recommendations
SSL_CIPHERS="EDH+CAMELLIA:EDH+aRSA:EECDH+aRSA+AESGCM:EECDH+aRSA+SHA384:EECDH+aRSA+SHA256:EECDH:+CAMELLIA256:+AES256:+CAMELLIA128:+AES128:+SSLv3:!aNULL:!eNULL:!LOW:!3DES:!MD5:!EXP:!PSK:!DSS:!RC4:!SEED:!ECDSA:CAMELLIA256-SHA:AES256-SHA:CAMELLIA128-SHA:AES128-SHA"

export DEBIAN_FRONTEND=noninteractive

# File which keeps track of what has already been installed
COMPLETION_FILE=$HOME/freedombone-completed.txt
if [ ! -f $COMPLETION_FILE ]; then
    touch $COMPLETION_FILE
fi

# message if something fails to install
CHECK_MESSAGE="Check your internet connection, /etc/network/interfaces and /etc/resolv.conf, then delete $COMPLETION_FILE, run 'rm -fR /var/lib/apt/lists/* && apt-get update --fix-missing' and run this script again. If hash sum mismatches persist then try setting $DEBIAN_REPO to a different mirror and also change /etc/apt/sources.list."

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
  echo "'$VARIANT_CHAT', '$VARIANT_SOCIAL', '$VARIANT_MEDIA' or '$VARIANT_WRITER'."
  echo "If you wish to install everything except email then use the '$VARIANT_NONMAILBOX' variaint."

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
  if [ $SYSTEM_TYPE ]; then
      if [[ $SYSTEM_TYPE != $VARIANT_WRITER && $SYSTEM_TYPE != $VARIANT_CLOUD && $SYSTEM_TYPE != $VARIANT_CHAT && $SYSTEM_TYPE != $VARIANT_MAILBOX && $SYSTEM_TYPE != $VARIANT_NONMAILBOX && $SYSTEM_TYPE != $VARIANT_SOCIAL && $SYSTEM_TYPE != $VARIANT_MEDIA ]]; then
          echo "'$SYSTEM_TYPE' is an unrecognised Freedombone variant."
          exit 30
      fi
  fi
}

function check_hwrng {
  # If hardware random number generation was enabled then make sure that the device exists.
  # if /dev/hwrng is not found then any subsequent cryptographic key generation would
  # suffer from low entropy and might be insecure
  if [ ! -f /etc/default/rng-tools ]; then
      return
  fi
  if [ ! -b /dev/hwrng ]; then
      ls /dev/hw*
      echo 'The hardware random number generator is enabled but could not be detected on'
      echo '/dev/hwrng.  There may be a problem with the installation or the Beaglebone hardware.'
      exit 75
  fi
}

function remove_default_user {
  # make sure you don't use the default user account
  if [[ $MY_USERNAME == "debian" ]]; then
      echo 'Do not use the default debian user account. Create a different user with: adduser [username]'
      exit 68
  fi
  # remove the default debian user to prevent it from becoming an attack vector
  if [ -d /home/debian ]; then
      userdel -r debian
      echo 'Default debian user account removed'
  fi
}

function enforce_good_passwords {
  # because humans are generally bad at choosing passwords
  if grep -Fxq "enforce_good_passwords" $COMPLETION_FILE; then
      return
  fi
  apt-get -y --force-yes install libpam-cracklib

  sed -i 's/password.*requisite.*pam_cracklib.so.*/password        required                       pam_cracklib.so retry=2 dcredit=-4 ucredit=-1 ocredit=-1 lcredit=0 minlen=10 reject_username/g' /etc/pam.d/common-password
  echo 'enforce_good_passwords' >> $COMPLETION_FILE
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

  if [[ $SYSTEM_TYPE == "$VARIANT_MEDIA" ]]; then
      echo '                 .    .        .            ' >> /etc/motd
      echo '                 |\  /|        |   o        ' >> /etc/motd
      echo "                 | \/ | .-. .-.|   .  .-.   " >> /etc/motd
      echo "                 |    |(.-'(   |   | (   )  " >> /etc/motd
      echo "                 '    '  --' -' --'  - -' - " >> /etc/motd
  fi

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

  if [[ $SYSTEM_TYPE == "$VARIANT_MAILBOX" ]]; then
      echo '             .    .           . .              ' >> /etc/motd
      echo '             |\  /|        o  | |              ' >> /etc/motd
      echo '             | \/ | .-.    .  | |.-.  .-.-. ,- ' >> /etc/motd
      echo '             |    |(   )   |  | |   )(   ) :   ' >> /etc/motd
      echo "             '    '  -' --'  - -' -'   -'-'  - " >> /etc/motd
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
      if [ ! -d $USB_MOUNT ]; then
          echo 'Mounting USB drive'
          mkdir $USB_MOUNT
          mount $USB_DRIVE $USB_MOUNT
      fi
      if ! [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" || $SYSTEM_TYPE == "$VARIANT_NONMAILBOX" ]]; then
          if [ -d $USB_MOUNT/Maildir ]; then
              echo 'Maildir found on USB drive'
              IMPORT_MAILDIR=$USB_MOUNT/Maildir
          fi
          if [ -d $USB_MOUNT/.gnupg ]; then
              echo 'Importing GPG keyring'
              cp -r $USB_MOUNT/.gnupg /home/$MY_USERNAME
              chown -R $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/.gnupg
              GPG_KEYS_IMPORTED="yes"
              if [ -f /home/$MY_USERNAME/.gnupg/secring.gpg ]; then
                  shred -zu $USB_MOUNT/.gnupg/secring.gpg
                  shred -zu $USB_MOUNT/.gnupg/random_seed
                  shred -zu $USB_MOUNT/.gnupg/trustdb.gpg
                  rm -rf $USB_MOUNT/.gnupg
              else
                  echo 'GPG files did not copy'
                  exit 7
              fi
          fi

          if [ -f $USB_MOUNT/private_key.gpg ]; then
              echo 'GPG private key found on USB drive'
              MY_GPG_PRIVATE_KEY=$USB_MOUNT/private_key.gpg
          fi
          if [ -f $USB_MOUNT/public_key.gpg ]; then
              echo 'GPG public key found on USB drive'
              MY_GPG_PUBLIC_KEY=$USB_MOUNT/public_key.gpg
          fi
      fi
      if [ -d $USB_MOUNT/.ssh ]; then
          echo 'Importing ssh keys'
          cp -r $USB_MOUNT/.ssh /home/$MY_USERNAME
          chown -R $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/.ssh
          # for security delete the ssh keys from the usb drive
          if [ -f /home/$MY_USERNAME/.ssh/id_rsa ]; then
              shred -zu $USB_MOUNT/.ssh/id_rsa
              shred -zu $USB_MOUNT/.ssh/id_rsa.pub
              shred -zu $USB_MOUNT/.ssh/known_hosts
              rm -rf $USB_MOUNT/.ssh
          else
              echo 'ssh files did not copy'
              exit 8
          fi
      fi
      if [ -f $USB_MOUNT/.emacs ]; then
          echo 'Importing .emacs file'
          cp -f $USB_MOUNT/.emacs /home/$MY_USERNAME/.emacs
          chown $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/.emacs
      fi
      if [ -d $USB_MOUNT/.emacs.d ]; then
          echo 'Importing .emacs.d directory'
          cp -r $USB_MOUNT/.emacs.d /home/$MY_USERNAME
          chown -R $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/.emacs.d
      fi
      if [ -d $USB_MOUNT/ssl ]; then
          echo 'Importing SSL certificates'
          cp -r $USB_MOUNT/ssl/* /etc/ssl
          chmod 640 /etc/ssl/certs/*
          chmod 400 /etc/ssl/private/*
          # change ownership of some certificates
          if [ -d /etc/prosody ]; then
              chown prosody:prosody /etc/ssl/private/xmpp.*
              chown prosody:prosody /etc/ssl/certs/xmpp.*
          fi
          if [ -d /etc/dovecot ]; then
              chown root:dovecot /etc/ssl/certs/dovecot.*
              chown root:dovecot /etc/ssl/private/dovecot.*
          fi
          if [ -f /etc/ssl/private/exim.key ]; then
              chown root:Debian-exim /etc/ssl/private/exim.key /etc/ssl/certs/exim.crt /etc/ssl/certs/exim.dhparam
          fi
      fi
      if [ -d $USB_MOUNT/personal ]; then
          echo 'Importing personal directory'
          cp -r $USB_MOUNT/personal /home/$MY_USERNAME
          chown -R $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/personal
      fi
  else
      if [ -d $USB_MOUNT ]; then
          umount $USB_MOUNT
          rm -rf $USB_MOUNT
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
  # if this is not a beaglebone or is a docker container
  # then just use the standard kernel
  if [[ $INSTALLED_WITHIN_DOCKER == "yes" || $INSTALLING_ON_BBB != "yes" ]]; then
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
  if [[ $INSTALLED_WITHIN_DOCKER == "yes" || $INSTALLING_ON_BBB != "yes" ]]; then
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
  if [[ $INSTALLING_ON_BBB != "yes" ]]; then
      # On systems which are not beaglebones assume that
      # no hardware random number generator is available
      # and use the second best option
      apt-get -y --force-yes install haveged
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
  if [[ $INSTALLED_WITHIN_DOCKER == "yes" || $INSTALLING_ON_BBB != "yes" ]]; then
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
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" || $SYSTEM_TYPE == "$VARIANT_NONMAILBOX" ]]; then
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
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" || $SYSTEM_TYPE == "$VARIANT_NONMAILBOX" ]]; then
      return
  fi
  if grep -Fxq "configure_email" $COMPLETION_FILE; then
      return
  fi
  apt-get -y remove postfix
  apt-get -y --force-yes install exim4 sasl2-bin swaks libnet-ssleay-perl procmail

  if [ ! -d /etc/exim4 ]; then
      echo "ERROR: Exim does not appear to have installed. $CHECK_MESSAGE"
      exit 48
  fi

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
  if [ ! -f /etc/ssl/private/exim.key ]; then
      makecert exim
  fi
  cp /etc/ssl/private/exim.key /etc/exim4
  cp /etc/ssl/certs/exim.crt /etc/exim4
  cp /etc/ssl/certs/exim.dhparam /etc/exim4
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
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" || $SYSTEM_TYPE == "$VARIANT_NONMAILBOX" ]]; then
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
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" || $SYSTEM_TYPE == "$VARIANT_NONMAILBOX" ]]; then
      return
  fi
  if grep -Fxq "configure_imap" $COMPLETION_FILE; then
      return
  fi
  apt-get -y --force-yes install dovecot-common dovecot-imapd

  if [ ! -d /etc/dovecot ]; then
      echo "ERROR: Dovecot does not appear to have installed. $CHECK_MESSAGE"
      exit 48
  fi

  if [ ! -f /etc/ssl/private/dovecot.key ]; then
      makecert dovecot
  fi
  chown root:dovecot /etc/ssl/certs/dovecot.*
  chown root:dovecot /etc/ssl/private/dovecot.*

  sed -i 's|#ssl = yes|ssl = yes|g' /etc/dovecot/conf.d/10-ssl.conf
  sed -i 's|ssl_cert = </etc/dovecot/dovecot.pem|ssl_cert = </etc/ssl/certs/dovecot.crt|g' /etc/dovecot/conf.d/10-ssl.conf
  sed -i 's|ssl_key = </etc/dovecot/private/dovecot.pem|/etc/ssl/private/dovecot.key|g' /etc/dovecot/conf.d/10-ssl.conf
  sed -i 's|#ssl_dh_parameters_length = 1024|ssl_dh_parameters_length = 1024|g' /etc/dovecot/conf.d/10-ssl.conf
  sed -i 's/#ssl_prefer_server_ciphers = no/ssl_prefer_server_ciphers = yes/g' /etc/dovecot/conf.d/10-ssl.conf
  echo "ssl_cipher_list = '$SSL_CIPHERS'" >> /etc/dovecot/conf.d/10-ssl.conf


  sed -i 's/#listen = *, ::/listen = */g' /etc/dovecot/dovecot.conf
  sed -i 's/#disable_plaintext_auth = yes/disable_plaintext_auth = no/g' /etc/dovecot/conf.d/10-auth.conf
  sed -i 's/auth_mechanisms = plain/auth_mechanisms = plain login/g' /etc/dovecot/conf.d/10-auth.conf
  sed -i 's|#   mail_location = maildir:~/Maildir|   mail_location = maildir:~/Maildir:LAYOUT=fs|g' /etc/dovecot/conf.d/10-mail.conf
  echo 'configure_imap' >> $COMPLETION_FILE
}

function configure_gpg {
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" || $SYSTEM_TYPE == "$VARIANT_NONMAILBOX" ]]; then
      return
  fi
  if grep -Fxq "configure_gpg" $COMPLETION_FILE; then
      return
  fi
  apt-get -y --force-yes install gnupg

  # if gpg keys directory was previously imported from usb
  if [[ $GPG_KEYS_IMPORTED == "yes" && -d /home/$MY_USERNAME/.gnupg ]]; then
      sed -i "s|keyserver hkp://keys.gnupg.net|keyserver $GPG_KEYSERVER|g" /home/$MY_USERNAME/.gnupg/gpg.conf
      echo 'configure_gpg' >> $COMPLETION_FILE
      return
  fi

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

function encrypt_incoming_email {
  # encrypts incoming mail using your GPG public key
  # so even if an attacker gains access to the data at rest they still need
  # to know your GPG key password to be able to read anything
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" || $SYSTEM_TYPE == "$VARIANT_NONMAILBOX" ]]; then
      return
  fi
  if grep -Fxq "encrypt_incoming_email" $COMPLETION_FILE; then
      return
  fi
  if [[ $GPG_ENCRYPT_STORED_EMAIL != "yes" ]]; then
      return
  fi
  if [ ! -f /usr/bin/gpgit.pl ]; then
      apt-get -y --force-yes install git libmail-gnupg-perl
      cd $INSTALL_DIR
      git clone https://github.com/mikecardwell/gpgit
      cd gpgit
      cp gpgit.pl /usr/bin
  fi

  # add a procmail rule
  if ! grep -q "/usr/bin/gpgit.pl" /home/$MY_USERNAME/.procmailrc; then
      echo '  :0 f' >> /home/$MY_USERNAME/.procmailrc
      echo "  | /usr/bin/gpgit.pl $MY_USERNAME@$DOMAIN_NAME" >> /home/$MY_USERNAME/.procmailrc
      chown $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/.procmailrc
  fi
  echo 'encrypt_incoming_email' >> $COMPLETION_FILE
}


function email_client {
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" || $SYSTEM_TYPE == "$VARIANT_NONMAILBOX" ]]; then
      return
  fi
  if grep -Fxq "email_client" $COMPLETION_FILE; then
      return
  fi
  apt-get -y --force-yes install mutt-patched lynx abook

  if [ ! -f /etc/Muttrc ]; then
      echo "ERROR: Mutt does not appear to have installed. $CHECK_MESSAGE"
      exit 49
  fi

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
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" || $SYSTEM_TYPE == "$VARIANT_NONMAILBOX" ]]; then
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
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" || $SYSTEM_TYPE == "$VARIANT_NONMAILBOX" ]]; then
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
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" || $SYSTEM_TYPE == "$VARIANT_NONMAILBOX" ]]; then
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
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" || $SYSTEM_TYPE == "$VARIANT_NONMAILBOX" ]]; then
      return
  fi
  EMAIL_COMPLETE_MSG='  *** Freedombone mailbox installation is complete ***'
  if grep -Fxq "import_email" $COMPLETION_FILE; then
      if [[ $SYSTEM_TYPE == "$VARIANT_MAILBOX" ]]; then
          echo ''
          echo "$EMAIL_COMPLETE_MSG"
          if [ -d $USB_MOUNT ]; then
              umount $USB_MOUNT
              rm -rf $USB_MOUNT
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
  if [[ $SYSTEM_TYPE == "$VARIANT_MAILBOX" ]]; then
      apt-get -y --force-yes autoremove
      # unmount any attached usb drive
      echo ''
      echo "$EMAIL_COMPLETE_MSG"
      echo ''
      if [ -d $USB_MOUNT ]; then
          umount $USB_MOUNT
          rm -rf $USB_MOUNT
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

  if [ ! -d /etc/nginx ]; then
      echo "ERROR: nginx does not appear to have installed. $CHECK_MESSAGE"
      exit 51
  fi

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
  sed -i "s/memory_limit = 128M/memory_limit = ${MAX_PHP_MEMORY}M/g" /etc/php5/fpm/php.ini
  sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php5/fpm/php.ini
  sed -i "s/memory_limit = -1/memory_limit = ${MAX_PHP_MEMORY}M/g" /etc/php5/cli/php.ini
  sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 50M/g" /etc/php5/fpm/php.ini
  sed -i "s/post_max_size = 8M/post_max_size = 50M/g" /etc/php5/fpm/php.ini
}

function install_owncloud {
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" ]]; then
      return
  fi
  OWNCLOUD_COMPLETION_MSG1=" *** Freedombone $SYSTEM_TYPE is now installed ***"
  OWNCLOUD_COMPLETION_MSG2="Open $OWNCLOUD_DOMAIN_NAME in a web browser to complete the setup"
  if grep -Fxq "install_owncloud" $COMPLETION_FILE; then
      if [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" ]]; then
          # unmount any attached usb drive
          if [ -d $USB_MOUNT ]; then
              umount $USB_MOUNT
              rm -rf $USB_MOUNT
          fi
          echo ''
          echo "$OWNCLOUD_COMPLETION_MSG1"
          echo "$OWNCLOUD_COMPLETION_MSG2"
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
  echo "    ssl_protocols $SSL_PROTOCOLS; # not possible to do exclusive" >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
  echo "    ssl_ciphers '$SSL_CIPHERS';" >> /etc/nginx/sites-available/$OWNCLOUD_DOMAIN_NAME
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
      echo $CHECKSUM
      echo $OWNCLOUD_HASH
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
  if [ $OWNCLOUD_FREEDNS_SUBDOMAIN_CODE ]; then
      if [[ $OWNCLOUD_FREEDNS_SUBDOMAIN_CODE != $FREEDNS_SUBDOMAIN_CODE ]]; then
          if ! grep -q "$OWNCLOUD_DOMAIN_NAME" /usr/bin/dynamicdns; then
              echo "# $OWNCLOUD_DOMAIN_NAME" >> /usr/bin/dynamicdns
              echo "wget -O - https://freedns.afraid.org/dynamic/update.php?$OWNCLOUD_FREEDNS_SUBDOMAIN_CODE== >> /dev/null 2>&1" >> /usr/bin/dynamicdns
          fi
      fi
  else
      echo 'WARNING: No freeDNS subdomain code given for Owncloud. It is assumed that you are using some other dynamic DNS provider.'
  fi

  echo 'install_owncloud' >> $COMPLETION_FILE

  if [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" ]]; then
      # unmount any attached usb drive
      if [ -d $USB_MOUNT ]; then
          umount $USB_MOUNT
          rm -rf $USB_MOUNT
      fi
      echo ''
      echo "$OWNCLOUD_COMPLETION_MSG1"
      echo "$OWNCLOUD_COMPLETION_MSG2"
      exit 0
  fi
}

function install_xmpp {
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" ]]; then
      return
  fi
  if grep -Fxq "install_xmpp" $COMPLETION_FILE; then
      return
  fi
  apt-get -y --force-yes install prosody

  if [ ! -d /etc/prosody ]; then
      echo "ERROR: prosody does not appear to have installed. $CHECK_MESSAGE"
      exit 52
  fi

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
  if [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" ]]; then
      return
  fi
  if grep -Fxq "install_irc_server" $COMPLETION_FILE; then
      return
  fi
  apt-get -y --force-yes install ngircd

  if [ ! -d /etc/ngircd ]; then
      echo "ERROR: ngircd does not appear to have installed. $CHECK_MESSAGE"
      exit 53
  fi

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
  if [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" ]]; then
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
      echo $CHECKSUM
      echo $WIKI_HASH
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
  echo "    ssl_protocols $SSL_PROTOCOLS; # not possible to do exclusive" >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo "    ssl_ciphers '$SSL_CIPHERS';" >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
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
  echo '        try_files $uri $uri/ /index.php;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
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
  echo '    location ~ /(data|conf|bin|inc)/ {' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '      deny all;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    location ~ /\.ht {' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '      deny  all;' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME
  echo '}' >> /etc/nginx/sites-available/$WIKI_DOMAIN_NAME

  configure_php

  nginx_ensite $WIKI_DOMAIN_NAME
  service php5-fpm restart
  service nginx restart

  # update the dynamic DNS
  if [ $WIKI_FREEDNS_SUBDOMAIN_CODE ]; then
      if [[ $WIKI_FREEDNS_SUBDOMAIN_CODE != $FREEDNS_SUBDOMAIN_CODE ]]; then
          if ! grep -q "$WIKI_DOMAIN_NAME" /usr/bin/dynamicdns; then
              echo "# $WIKI_DOMAIN_NAME" >> /usr/bin/dynamicdns
              echo "wget -O - https://freedns.afraid.org/dynamic/update.php?$WIKI_FREEDNS_SUBDOMAIN_CODE== >> /dev/null 2>&1" >> /usr/bin/dynamicdns
          fi
      fi
  else
      echo 'WARNING: No freeDNS subdomain code given for wiki installation. It is assumed that you are using some other dynamic DNS provider.'
  fi

  # add some post-install instructions
  if ! grep -q "Once you have set up the wiki" /home/$MY_USERNAME/README; then
      echo '' >> /home/$MY_USERNAME/README
      echo 'Once you have set up the wiki then remove the install file:' >> /home/$MY_USERNAME/README
      echo '' >> /home/$MY_USERNAME/README
      echo "  rm /var/www/$WIKI_DOMAIN_NAME/htdocs/install.php" >> /home/$MY_USERNAME/README
      chown $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/README
  fi

  echo 'install_wiki' >> $COMPLETION_FILE
}

function install_blog {
  if [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" ]]; then
      return
  fi
  if grep -Fxq "install_blog" $COMPLETION_FILE; then
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

  apt-get -y --force-yes install unzip

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
      echo $CHECKSUM
      echo $WIKI_MNML_BLOG_ADDON_HASH
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
      echo $CHECKSUM
      echo $WIKI_BLOGTNG_ADDON_HASH
      exit 24
  fi

  # download dokuwiki sqlite plugin
  wget $WIKI_SQLITE_ADDON
  if [ ! -f "$INSTALL_DIR/master" ]; then
      echo 'Dokuwiki sqlite addon could not be downloaded. Check the Dokuwiki web site and alter WIKI_SQLITE_ADDON at the top of this script as needed.'
      exit 25
  fi
  mv master $WIKI_SQLITE_ADDON_ARCHIVE

  # Check that the sqlite plugin hash is correct
  CHECKSUM=$(sha256sum $WIKI_SQLITE_ADDON_ARCHIVE | awk -F ' ' '{print $1}')
  if [[ $CHECKSUM != $WIKI_SQLITE_ADDON_HASH ]]; then
      echo 'The sha256 hash of the Dokuwiki sqlite download is incorrect. Possibly the file may have been tampered with. Check the hash on the Dokuwiki sqlite plugin web site and alter WIKI_SQLITE_ADDON_HASH if needed.'
      echo $CHECKSUM
      echo $WIKI_SQLITE_ADDON_HASH
      exit 26
  fi

  # install dokuwiki sqlite plugin
  tar -xzvf $WIKI_SQLITE_ADDON_ARCHIVE
  if [ -d "$INSTALL_DIR/sqlite" ]; then
      rm -rf $INSTALL_DIR/sqlite
  fi
  mv $WIKI_SQLITE_ADDON_NAME sqlite
  cp -r sqlite /var/www/$WIKI_DOMAIN_NAME/htdocs/lib/plugins/

  # install blogTNG
  if [ -d "$INSTALL_DIR/$WIKI_BLOGTNG_ADDON_NAME" ]; then
      rm -rf $INSTALL_DIR/$WIKI_BLOGTNG_ADDON_NAME
  fi
  unzip $WIKI_BLOGTNG_ADDON_ARCHIVE
  if [ -d "$INSTALL_DIR/blogtng" ]; then
      rm -rf $INSTALL_DIR/blogtng
  fi
  mv $WIKI_BLOGTNG_ADDON_NAME blogtng
  cp -r blogtng /var/www/$WIKI_DOMAIN_NAME/htdocs/lib/plugins/

  # install mnml-blog
  tar -xzvf $WIKI_MNML_BLOG_ADDON_ARCHIVE
  cp -r mnml-blog /var/www/$WIKI_DOMAIN_NAME/htdocs/lib/tpl
  cp -r /var/www/$WIKI_DOMAIN_NAME/htdocs/lib/tpl/mnml-blog/blogtng-tpl/* /var/www/$WIKI_DOMAIN_NAME/htdocs/lib/plugins/blogtng/tpl/default/

  # make a "freedombone" template so that if the default template gets
  # changed after an upgrade to blogTNG this doesn't necessarily change the appearance
  cp -r /var/www/$WIKI_DOMAIN_NAME/htdocs/lib/plugins/blogtng/tpl/default /var/www/$WIKI_DOMAIN_NAME/htdocs/lib/plugins/blogtng/tpl/freedombone

  if ! grep -q "To set up your blog" /home/$MY_USERNAME/README; then
      echo '' >> /home/$MY_USERNAME/README
      echo "To set up your blog go to" >> /home/$MY_USERNAME/README
      echo "https://$WIKI_DOMAIN_NAME/doku.php?id=start&do=admin&page=config" >> /home/$MY_USERNAME/README
      echo 'and set the template to mnml-blog' >> /home/$MY_USERNAME/README
      echo '' >> /home/$MY_USERNAME/README
      echo 'To edit things on the right hand sidebar (links, blogroll, etc) go to' >> /home/$MY_USERNAME/README
      echo "https://$WIKI_DOMAIN_NAME/doku.php?id=wiki:navigation_sidebar" >> /home/$MY_USERNAME/README
      echo 'and edit the page' >> /home/$MY_USERNAME/README
      echo '' >> /home/$MY_USERNAME/README
      echo 'To edit things to a header bar (home, contacts, etc) go to' >> /home/$MY_USERNAME/README
      echo "https://$WIKI_DOMAIN_NAME/doku.php?id=wiki:navigation_header" >> /home/$MY_USERNAME/README
      echo 'and select the "create this page" at the bottom.' >> /home/$MY_USERNAME/README
      echo 'You can then add somethething like:' >> /home/$MY_USERNAME/README
      echo '  * [[:start|Home]]' >> /home/$MY_USERNAME/README
      echo '  * [[:wiki|Wiki]]' >> /home/$MY_USERNAME/README
      echo '  * [[:contact|Contact]]' >> /home/$MY_USERNAME/README
      echo "Go to https://$WIKI_DOMAIN_NAME/doku.php?id=start&do=admin&page=config" >> /home/$MY_USERNAME/README
      echo 'and check "Show header navigation" to ensure that the header shows' >> /home/$MY_USERNAME/README
      chown $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/README
  fi

  echo 'install_blog' >> $COMPLETION_FILE
}

function get_mariadb_password {
  if [ -f /home/$MY_USERNAME/README ]; then
      if grep -q "MariaDB password" /home/$MY_USERNAME/README; then
          MARIADB_PASSWORD=$(cat /home/$MY_USERNAME/README | grep "MariaDB password" | awk -F ':' '{print $2}' | sed 's/^ *//')
      fi
  fi
}

function get_mariadb_gnusocial_admin_password {
  if [ -f /home/$MY_USERNAME/README ]; then
      if grep -q "MariaDB gnusocial admin password" /home/$MY_USERNAME/README; then
          MICROBLOG_ADMIN_PASSWORD=$(cat /home/$MY_USERNAME/README | grep "MariaDB gnusocial admin password" | awk -F ':' '{print $2}' | sed 's/^ *//')
      fi
  fi
}

function get_mariadb_redmatrix_admin_password {
  if [ -f /home/$MY_USERNAME/README ]; then
      if grep -q "MariaDB Red Matrix admin password" /home/$MY_USERNAME/README; then
          REDMATRIX_ADMIN_PASSWORD=$(cat /home/$MY_USERNAME/README | grep "MariaDB Red Matrix admin password" | awk -F ':' '{print $2}' | sed 's/^ *//')
      fi
  fi
}

function install_mariadb {
  if grep -Fxq "install_mariadb" $COMPLETION_FILE; then
      return
  fi
  apt-get -y --force-yes install python-software-properties debconf-utils
  apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db
  add-apt-repository 'deb http://mariadb.biz.net.id//repo/10.1/debian sid main'
  apt-get -y --force-yes install software-properties-common
  apt-get -y update

  get_mariadb_password
  if [ ! $MARIADB_PASSWORD ]; then
      MARIADB_PASSWORD=$(openssl rand -base64 32)
      echo '' >> /home/$MY_USERNAME/README
      echo "Your MariaDB password is: $MARIADB_PASSWORD" >> /home/$MY_USERNAME/README
      echo '' >> /home/$MY_USERNAME/README
      chown $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/README
  fi

  debconf-set-selections <<< "mariadb-server mariadb-server/root_password password $MARIADB_PASSWORD"
  debconf-set-selections <<< "mariadb-server mariadb-server/root_password_again password $MARIADB_PASSWORD"
  apt-get -y --force-yes install mariadb-server

  if [ ! -d /etc/mysql ]; then
      echo "ERROR: mariadb-server does not appear to have installed. $CHECK_MESSAGE"
      exit 54
  fi

  mysqladmin -u root password "$MARIADB_PASSWORD"
  echo 'install_mariadb' >> $COMPLETION_FILE
}

function install_gnu_social {
  if grep -Fxq "install_gnu_social" $COMPLETION_FILE; then
      return
  fi
  if [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_MEDIA" ]]; then
      return
  fi
  if [ ! $MICROBLOG_DOMAIN_NAME ]; then
      return
  fi

  install_mariadb
  get_mariadb_password

  apt-get -y --force-yes install php-gettext php5-curl php5-gd php5-mysql git

  if [ ! -d /var/www/$MICROBLOG_DOMAIN_NAME ]; then
      mkdir /var/www/$MICROBLOG_DOMAIN_NAME
  fi
  if [ ! -d /var/www/$MICROBLOG_DOMAIN_NAME/htdocs ]; then
      mkdir /var/www/$MICROBLOG_DOMAIN_NAME/htdocs
  fi

  if [ ! -f /var/www/$MICROBLOG_DOMAIN_NAME/htdocs/index.php ]; then
      cd $INSTALL_DIR
      git clone $MICROBLOG_REPO gnusocial

      rm -rf /var/www/$MICROBLOG_DOMAIN_NAME/htdocs
      mv gnusocial /var/www/$MICROBLOG_DOMAIN_NAME/htdocs
      chmod a+w /var/www/$MICROBLOG_DOMAIN_NAME/htdocs
      chown www-data:www-data /var/www/$MICROBLOG_DOMAIN_NAME/htdocs
      chmod a+w /var/www/$MICROBLOG_DOMAIN_NAME/htdocs/avatar
      chmod a+w /var/www/$MICROBLOG_DOMAIN_NAME/htdocs/background
      chmod a+w /var/www/$MICROBLOG_DOMAIN_NAME/htdocs/file
      chmod +x /var/www/$MICROBLOG_DOMAIN_NAME/htdocs/scripts/maildaemon.php
  fi

  get_mariadb_gnusocial_admin_password
  if [ ! $MICROBLOG_ADMIN_PASSWORD ]; then
      MICROBLOG_ADMIN_PASSWORD=$(openssl rand -base64 32)
      echo '' >> /home/$MY_USERNAME/README
      echo "Your MariaDB gnusocial admin password is: $MICROBLOG_ADMIN_PASSWORD" >> /home/$MY_USERNAME/README
      echo '' >> /home/$MY_USERNAME/README
      chown $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/README
  fi

  echo "create database gnusocial;
CREATE USER 'gnusocialadmin'@'localhost' IDENTIFIED BY '$MICROBLOG_ADMIN_PASSWORD';
GRANT ALL PRIVILEGES ON gnusocial.* TO 'gnusocialadmin'@'localhost';
quit" > $INSTALL_DIR/batch.sql
  chmod 600 $INSTALL_DIR/batch.sql
  mysql -u root --password="$MARIADB_PASSWORD" < $INSTALL_DIR/batch.sql
  shred -zu $INSTALL_DIR/batch.sql

  if [ ! -f "/etc/aliases" ]; then
      touch /etc/aliases
  fi
  if grep -q "www-data: root" /etc/aliases; then
      echo 'www-data: root' >> /etc/aliases
  fi
  if grep -q "/var/www/$MICROBLOG_DOMAIN_NAME/htdocs/scripts/maildaemon.php" /etc/aliases; then
      echo "*: /var/www/$MICROBLOG_DOMAIN_NAME/htdocs/scripts/maildaemon.php" >> /etc/aliases
  fi
  newaliases

  # update the dynamic DNS
  if [ $MICROBLOG_FREEDNS_SUBDOMAIN_CODE ]; then
      if [[ $MICROBLOG_FREEDNS_SUBDOMAIN_CODE != $FREEDNS_SUBDOMAIN_CODE ]]; then
          if ! grep -q "$MICROBLOG_DOMAIN_NAME" /usr/bin/dynamicdns; then
              echo "# $MICROBLOG_DOMAIN_NAME" >> /usr/bin/dynamicdns
              echo "wget -O - https://freedns.afraid.org/dynamic/update.php?$MICROBLOG_FREEDNS_SUBDOMAIN_CODE== >> /dev/null 2>&1" >> /usr/bin/dynamicdns
          fi
      fi
  else
      echo 'WARNING: No freeDNS subdomain code given for microblog. It is assumed that you are using some other dynamic DNS provider.'
  fi

  echo 'server {' > /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    listen 80;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo "    server_name $MICROBLOG_DOMAIN_NAME;" >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo "    root /var/www/$MICROBLOG_DOMAIN_NAME/htdocs;" >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo "    error_log /var/www/$MICROBLOG_DOMAIN_NAME/error.log;" >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    index index.php;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    rewrite ^ https://$server_name$request_uri? permanent;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '}' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo 'server {' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    listen 443 ssl;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo "    root /var/www/$MICROBLOG_DOMAIN_NAME/htdocs;" >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo "    server_name $MICROBLOG_DOMAIN_NAME;" >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo "    error_log /var/www/$MICROBLOG_DOMAIN_NAME/error_ssl.log;" >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    index index.php;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    charset utf-8;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    client_max_body_size 20m;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    client_body_buffer_size 128k;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    ssl on;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo "    ssl_certificate /etc/ssl/certs/$MICROBLOG_DOMAIN_NAME.crt;" >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo "    ssl_certificate_key /etc/ssl/private/$MICROBLOG_DOMAIN_NAME.key;" >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo "    ssl_dhparam /etc/ssl/certs/$MICROBLOG_DOMAIN_NAME.dhparam;" >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    ssl_session_timeout 5m;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    ssl_prefer_server_ciphers on;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    ssl_session_cache  builtin:1000  shared:SSL:10m;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo "    ssl_protocols $SSL_PROTOCOLS; # not possible to do exclusive" >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo "    ssl_ciphers '$SSL_CIPHERS';" >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    add_header X-Frame-Options DENY;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    add_header X-Content-Type-Options nosniff;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    add_header Strict-Transport-Security max-age=15768000;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    # rewrite to front controller as default rule' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    location / {' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '        rewrite ^/(.*) /index.php?q=$uri&$args last;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo "    # make sure webfinger and other well known services aren't blocked" >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    # by denying dot files and rewrite request to the front controller' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    location ^~ /.well-known/ {' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '        allow all;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '        rewrite ^/(.*) /index.php?q=$uri&$args last;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    # statically serve these file types when possible' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    # otherwise fall back to front controller' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    # allow browser to cache them' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    # added .htm for advanced source code editor library' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    location ~* \.(jpg|jpeg|gif|png|ico|css|js|htm|html|ttf|woff|svg)$ {' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '        expires 30d;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '        try_files $uri /index.php?q=$uri&$args;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    # block these file types' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    location ~* \.(tpl|md|tgz|log|out)$ {' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '        deny all;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    # or a unix socket' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    location ~* \.php$ {' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '        # Zero-day exploit defense.' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '        # http://forum.nginx.org/read.php?2,88845,page=3' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo "        # Won't work properly (404 error) if the file is not stored on this" >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo "        # server, which is entirely possible with php-fpm/php-fcgi." >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo "        # Comment the 'try_files' line out if you set up php-fpm/php-fcgi on" >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo "        # another machine. And then cross your fingers that you won't get hacked." >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '        try_files $uri $uri/ /index.php;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '        # NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '        fastcgi_split_path_info ^(.+\.php)(/.+)$;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '        # With php5-cgi alone:' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '        # fastcgi_pass 127.0.0.1:9000;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '        # With php5-fpm:' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '        fastcgi_pass unix:/var/run/php5-fpm.sock;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '        include fastcgi_params;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '        fastcgi_index index.php;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    # deny access to all dot files' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    location ~ /\. {' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '        deny all;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    location ~ /\.ht {' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '      deny  all;' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME
  echo '}' >> /etc/nginx/sites-available/$MICROBLOG_DOMAIN_NAME

  configure_php

  if [ ! -f /etc/ssl/private/$MICROBLOG_DOMAIN_NAME.key ]; then
      makecert $MICROBLOG_DOMAIN_NAME
  fi

  nginx_ensite $MICROBLOG_DOMAIN_NAME
  service php5-fpm restart
  service nginx restart

  # some post-install instructions for the user
  if ! grep -q "To set up your microblog" /home/$MY_USERNAME/README; then
      echo '' >> /home/$MY_USERNAME/README
      echo "To set up your microblog go to" >> /home/$MY_USERNAME/README
      echo "https://$MICROBLOG_DOMAIN_NAME/install.php" >> /home/$MY_USERNAME/README
      echo 'and enter the following settings:' >> /home/$MY_USERNAME/README
      echo ' - Set a name for the site' >> /home/$MY_USERNAME/README
      echo ' - Server SSL: enable' >> /home/$MY_USERNAME/README
      echo ' - Hostname: localhost' >> /home/$MY_USERNAME/README
      echo ' - Type: MySql/MariaDB' >> /home/$MY_USERNAME/README
      echo ' - Name: gnusocial' >> /home/$MY_USERNAME/README
      echo ' - DB username: gnusocialadmin' >> /home/$MY_USERNAME/README
      echo " - DB Password; $MICROBLOG_ADMIN_PASSWORD" >> /home/$MY_USERNAME/README
      echo " - Administrator nickname: $MY_USERNAME" >> /home/$MY_USERNAME/README
      echo " - Administrator password: $MICROBLOG_ADMIN_PASSWORD" >> /home/$MY_USERNAME/README
      echo ' - Subscribe to announcements: ticked' >> /home/$MY_USERNAME/README
      echo ' - Site profile: Community' >> /home/$MY_USERNAME/README
      echo '' >> /home/$MY_USERNAME/README
      echo "Navigate to https://$MICROBLOG_DOMAIN_NAME and you can then " >> /home/$MY_USERNAME/README
      echo 'complete the configuration via the *Admin* section on the header' >> /home/$MY_USERNAME/README
      echo 'bar.  Some recommended admin settings are:' >> /home/$MY_USERNAME/README
      echo '' >> /home/$MY_USERNAME/README
      echo 'Under the *Site* settings:' >> /home/$MY_USERNAME/README
      echo '    Text limit: 140' >> /home/$MY_USERNAME/README
      echo '    Dupe Limit: 60000' >> /home/$MY_USERNAME/README
      echo '' >> /home/$MY_USERNAME/README
      echo 'Under the *User* settings:' >> /home/$MY_USERNAME/README
      echo '    Bio limit: 1000' >> /home/$MY_USERNAME/README
      echo '' >> /home/$MY_USERNAME/README
      echo 'Under the *Access* settings:' >> /home/$MY_USERNAME/README
      echo '    /Invite only/ ticked' >> /home/$MY_USERNAME/README
      echo '' >> /home/$MY_USERNAME/README
      chown $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/README
  fi

  echo 'install_gnu_social' >> $COMPLETION_FILE
}

function install_redmatrix {
  if grep -Fxq "install_redmatrix" $COMPLETION_FILE; then
      return
  fi
  if [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_MEDIA" ]]; then
      return
  fi
  # if this is exclusively a writer setup
  if [[ $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      REDMATRIX_DOMAIN_NAME=$DOMAIN_NAME
      REDMATRIX_FREEDNS_SUBDOMAIN_CODE=$FREEDNS_SUBDOMAIN_CODE
  fi
  if [ ! $REDMATRIX_DOMAIN_NAME ]; then
      return
  fi

  install_mariadb
  get_mariadb_password

  apt-get -y --force-yes install php5-common php5-cli php5-curl php5-gd php5-mysql php5-mcrypt git git

  if [ ! -d /var/www/$REDMATRIX_DOMAIN_NAME ]; then
      mkdir /var/www/$REDMATRIX_DOMAIN_NAME
  fi
  if [ ! -d /var/www/$REDMATRIX_DOMAIN_NAME/htdocs ]; then
      mkdir /var/www/$REDMATRIX_DOMAIN_NAME/htdocs
  fi

  if [ ! -f /var/www/$REDMATRIX_DOMAIN_NAME/htdocs/index.php ]; then
      cd $INSTALL_DIR
      git clone $REDMATRIX_REPO redmatrix

      rm -rf /var/www/$REDMATRIX_DOMAIN_NAME/htdocs
      mv redmatrix /var/www/$REDMATRIX_DOMAIN_NAME/htdocs
      chown -R www-data:www-data /var/www/$REDMATRIX_DOMAIN_NAME/htdocs
      git clone $REDMATRIX_ADDONS_REPO /var/www/$REDMATRIX_DOMAIN_NAME/htdocs/addon
  fi

  get_mariadb_redmatrix_admin_password
  if [ ! $REDMATRIX_ADMIN_PASSWORD ]; then
      REDMATRIX_ADMIN_PASSWORD=$(openssl rand -base64 32)
      echo '' >> /home/$MY_USERNAME/README
      echo "Your MariaDB Red Matrix admin password is: $REDMATRIX_ADMIN_PASSWORD" >> /home/$MY_USERNAME/README
      echo '' >> /home/$MY_USERNAME/README
      chown $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/README
  fi

  echo "create database redmatrix;
CREATE USER 'redmatrixadmin'@'localhost' IDENTIFIED BY '$REDMATRIX_ADMIN_PASSWORD';
GRANT ALL PRIVILEGES ON redmatrix.* TO 'redmatrixadmin'@'localhost';
quit" > $INSTALL_DIR/batch.sql
  chmod 600 $INSTALL_DIR/batch.sql
  mysql -u root --password="$MARIADB_PASSWORD" < $INSTALL_DIR/batch.sql
  shred -zu $INSTALL_DIR/batch.sql

  if ! grep -q "/var/www/$REDMATRIX_DOMAIN_NAME/htdocs" /etc/crontab; then
      echo "12,22,32,42,52 * *   *   *   root cd /var/www/$REDMATRIX_DOMAIN_NAME/htdocs; /usr/bin/timeout 240 /usr/bin/php include/poller.php" >> /etc/crontab
  fi

  # update the dynamic DNS
  if [ $REDMATRIX_FREEDNS_SUBDOMAIN_CODE ]; then
      if [[ $REDMATRIX_FREEDNS_SUBDOMAIN_CODE != $FREEDNS_SUBDOMAIN_CODE ]]; then
          if ! grep -q "$REDMATRIX_DOMAIN_NAME" /usr/bin/dynamicdns; then
              echo "# $REDMATRIX_DOMAIN_NAME" >> /usr/bin/dynamicdns
              echo "wget -O - https://freedns.afraid.org/dynamic/update.php?$REDMATRIX_FREEDNS_SUBDOMAIN_CODE== >> /dev/null 2>&1" >> /usr/bin/dynamicdns
          fi
      fi
  else
      echo 'WARNING: No freeDNS code given for Red Matrix. It is assumed that you are using some other dynamic DNS provider.'
  fi

  echo 'server {' > /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    listen 80;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo "    server_name $REDMATRIX_DOMAIN_NAME;" >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo "    root /var/www/$REDMATRIX_DOMAIN_NAME/htdocs;" >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo "    error_log /var/www/$REDMATRIX_DOMAIN_NAME/error.log;" >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    index index.php;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    rewrite ^ https://$server_name$request_uri? permanent;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '}' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo 'server {' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    listen 443 ssl;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo "    root /var/www/$REDMATRIX_DOMAIN_NAME/htdocs;" >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo "    server_name $REDMATRIX_DOMAIN_NAME;" >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo "    error_log /var/www/$REDMATRIX_DOMAIN_NAME/error_ssl.log;" >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    index index.php;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    charset utf-8;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    client_max_body_size 20m;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    client_body_buffer_size 128k;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    ssl on;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo "    ssl_certificate /etc/ssl/certs/$REDMATRIX_DOMAIN_NAME.crt;" >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo "    ssl_certificate_key /etc/ssl/private/$REDMATRIX_DOMAIN_NAME.key;" >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo "    ssl_dhparam /etc/ssl/certs/$REDMATRIX_DOMAIN_NAME.dhparam;" >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    ssl_session_timeout 5m;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    ssl_prefer_server_ciphers on;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    ssl_session_cache  builtin:1000  shared:SSL:10m;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo "    ssl_protocols $SSL_PROTOCOLS; # not possible to do exclusive" >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo "    ssl_ciphers '$SSL_CIPHERS';" >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    add_header X-Frame-Options DENY;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    add_header X-Content-Type-Options nosniff;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    add_header Strict-Transport-Security max-age=15768000;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    # rewrite to front controller as default rule' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    location / {' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '        rewrite ^/(.*) /index.php?q=$uri&$args last;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo "    # make sure webfinger and other well known services aren't blocked" >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    # by denying dot files and rewrite request to the front controller' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    location ^~ /.well-known/ {' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '        allow all;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '        rewrite ^/(.*) /index.php?q=$uri&$args last;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    # statically serve these file types when possible' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    # otherwise fall back to front controller' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    # allow browser to cache them' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    # added .htm for advanced source code editor library' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    location ~* \.(jpg|jpeg|gif|png|ico|css|js|htm|html|ttf|woff|svg)$ {' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '        expires 30d;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '        try_files $uri /index.php?q=$uri&$args;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    # block these file types' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    location ~* \.(tpl|md|tgz|log|out)$ {' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '        deny all;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    # or a unix socket' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    location ~* \.php$ {' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '        # Zero-day exploit defense.' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '        # http://forum.nginx.org/read.php?2,88845,page=3' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo "        # Won't work properly (404 error) if the file is not stored on this" >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo "        # server, which is entirely possible with php-fpm/php-fcgi." >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo "        # Comment the 'try_files' line out if you set up php-fpm/php-fcgi on" >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo "        # another machine. And then cross your fingers that you won't get hacked." >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '        try_files $uri $uri/ /index.php;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '        # NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '        fastcgi_split_path_info ^(.+\.php)(/.+)$;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '        # With php5-cgi alone:' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '        # fastcgi_pass 127.0.0.1:9000;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '        # With php5-fpm:' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '        fastcgi_pass unix:/var/run/php5-fpm.sock;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '        include fastcgi_params;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '        fastcgi_index index.php;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '        fastcgi_read_timeout 300;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    # deny access to all dot files' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    location ~ /\. {' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '        deny all;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    location ~ /\.ht {' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '      deny  all;' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '    }' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME
  echo '}' >> /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME

  configure_php

  if [ ! -f /etc/ssl/private/$REDMATRIX_DOMAIN_NAME.key ]; then
      makecert $REDMATRIX_DOMAIN_NAME
  fi

  if [ ! -d /var/www/$REDMATRIX_DOMAIN_NAME/htdocs/view/tpl/smarty3 ]; then
      mkdir /var/www/$REDMATRIX_DOMAIN_NAME/htdocs/view/tpl/smarty3
  fi
  if [ ! -d /var/www/$REDMATRIX_DOMAIN_NAME/htdocs/store/[data] ]; then
      mkdir /var/www/$REDMATRIX_DOMAIN_NAME/htdocs/store/[data]
  fi
  if [ ! -d /var/www/$REDMATRIX_DOMAIN_NAME/htdocs/store/[data]/smarty3 ]; then
      mkdir /var/www/$REDMATRIX_DOMAIN_NAME/htdocs/store/[data]/smarty3
      chmod 777 /var/www/$REDMATRIX_DOMAIN_NAME/htdocs/store/[data]/smarty3
  fi
  chmod 777 /var/www/$REDMATRIX_DOMAIN_NAME/htdocs/view/tpl
  chmod 777 /var/www/$REDMATRIX_DOMAIN_NAME/htdocs/view/tpl/smarty3

  nginx_ensite $REDMATRIX_DOMAIN_NAME
  service php5-fpm restart
  service nginx restart
  service cron restart

  # some post-install instructions for the user
  if ! grep -q "To set up your Red Matrix" /home/$MY_USERNAME/README; then
      echo '' >> /home/$MY_USERNAME/README
      echo "To set up your Red Matrix site go to" >> /home/$MY_USERNAME/README
      echo "https://$REDMATRIX_DOMAIN_NAME" >> /home/$MY_USERNAME/README
      echo 'You will need to have a non self-signed SSL certificate in order' >> /home/$MY_USERNAME/README
      echo "to use Red Matrix. Put the public certificate in /etc/ssl/certs/$REDMATRIX_DOMAIN_NAME.crt" >> /home/$MY_USERNAME/README
      echo "and the private certificate in /etc/ssl/private/$REDMATRIX_DOMAIN_NAME.key." >> /home/$MY_USERNAME/README
      echo 'If there is an intermediate certificate needed (such as with StartSSL) then' >> /home/$MY_USERNAME/README
      echo 'this will need to be concatenated onto the end of the crt file, like this:' >> /home/$MY_USERNAME/README
      echo '' >> /home/$MY_USERNAME/README
      echo "  cat /etc/ssl/certs/$REDMATRIX_DOMAIN_NAME.crt /etc/ssl/chains/startssl-sub.class1.server.ca.pem > /etc/ssl/certs/$REDMATRIX_DOMAIN_NAME.bundle.crt" >> /home/$MY_USERNAME/README
      echo '' >> /home/$MY_USERNAME/README
      echo "Then change ssl_certificate to /etc/ssl/certs/$REDMATRIX_DOMAIN_NAME.bundle.crt" >> /home/$MY_USERNAME/README
      echo "within /etc/nginx/sites-available/$REDMATRIX_DOMAIN_NAME" >> /home/$MY_USERNAME/README
      echo '' >> /home/$MY_USERNAME/README
      chown $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/README
  fi

  echo 'install_redmatrix' >> $COMPLETION_FILE
}

function script_for_attaching_usb_drive {
  if grep -Fxq "script_for_attaching_usb_drive" $COMPLETION_FILE; then
      return
  fi
  echo '#!/bin/bash' > /usr/bin/attach-music
  echo "if [ -d $USB_MOUNT ]; then" >> /usr/bin/attach-music
  echo "  umount $USB_MOUNT" >> /usr/bin/attach-music
  echo 'fi' >> /usr/bin/attach-music
  echo "if [ ! -d $USB_MOUNT ]; then" >> /usr/bin/attach-music
  echo "  mkdir $USB_MOUNT" >> /usr/bin/attach-music
  echo 'fi' >> /usr/bin/attach-music
  echo "mount /dev/sda1 $USB_MOUNT" >> /usr/bin/attach-music
  echo "chown root:root $USB_MOUNT" >> /usr/bin/attach-music
  echo "chown -R minidlna:minidlna $USB_MOUNT/*" >> /usr/bin/attach-music
  echo 'minidlnad -R' >> /usr/bin/attach-music
  chmod +x /usr/bin/attach-music
  ln -s /usr/bin/attach-music /usr/bin/attach-usb
  ln -s /usr/bin/attach-music /usr/bin/attach-videos
  ln -s /usr/bin/attach-music /usr/bin/attach-pictures
  ln -s /usr/bin/attach-music /usr/bin/attach-media

  echo '#!/bin/bash' > /usr/bin/remove-music
  echo "if [ -d $USB_MOUNT ]; then" >> /usr/bin/remove-music
  echo "  umount $USB_MOUNT" >> /usr/bin/remove-music
  echo "  rm -rf $USB_MOUNT" >> /usr/bin/remove-music
  echo 'fi' >> /usr/bin/remove-music
  chmod +x /usr/bin/remove-music
  ln -s /usr/bin/remove-music /usr/bin/detach-music
  ln -s /usr/bin/remove-music /usr/bin/detach-usb
  ln -s /usr/bin/remove-music /usr/bin/remove-usb
  ln -s /usr/bin/remove-music /usr/bin/detach-media
  ln -s /usr/bin/remove-music /usr/bin/remove-media
  ln -s /usr/bin/remove-music /usr/bin/detach-videos
  ln -s /usr/bin/remove-music /usr/bin/remove-videos
  ln -s /usr/bin/remove-music /usr/bin/detach-pictures
  ln -s /usr/bin/remove-music /usr/bin/remove-pictures

  echo 'script_for_attaching_usb_drive' >> $COMPLETION_FILE
}

function install_dlna_server {
  if grep -Fxq "install_dlna_server" $COMPLETION_FILE; then
      return
  fi
  if [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      return
  fi
  apt-get -y --force-yes install minidlna

  if [ ! -f /etc/minidlna.conf ]; then
      echo "ERROR: minidlna does not appear to have installed. $CHECK_MESSAGE"
      exit 55
  fi

  sed -i "s|media_dir=/var/lib/minidlna|media_dir=A,/home/$MY_USERNAME/Music|g" /etc/minidlna.conf
  if ! grep -q "/home/$MY_USERNAME/Pictures" /etc/minidlna.conf; then
    echo "media_dir=P,/home/$MY_USERNAME/Pictures" >> /etc/minidlna.conf
  fi
  if ! grep -q "/home/$MY_USERNAME/Videos" /etc/minidlna.conf; then
      echo "media_dir=V,/home/$MY_USERNAME/Videos" >> /etc/minidlna.conf
  fi
  if ! grep -q "$USB_MOUNT/Music" /etc/minidlna.conf; then
      echo "media_dir=A,$USB_MOUNT/Music" >> /etc/minidlna.conf
  fi
  if ! grep -q "$USB_MOUNT/Pictures" /etc/minidlna.conf; then
      echo "media_dir=P,$USB_MOUNT/Pictures" >> /etc/minidlna.conf
  fi
  if ! grep -q "$USB_MOUNT/Videos" /etc/minidlna.conf; then
      echo "media_dir=V,$USB_MOUNT/Videos" >> /etc/minidlna.conf
  fi
  sed -i 's/#root_container=./root_container=B/g' /etc/minidlna.conf
  sed -i 's/#network_interface=/network_interface=eth0/g' /etc/minidlna.conf
  sed -i 's/#friendly_name=/friendly_name="Freedombone Media"/g' /etc/minidlna.conf
  sed -i 's|#db_dir=/var/cache/minidlna|db_dir=/var/cache/minidlna|g' /etc/minidlna.conf
  sed -i 's/#inotify=yes/inotify=yes/g' /etc/minidlna.conf
  sed -i "s|#presentation_url=/|presentation_url=http://localhost:8200|g" /etc/minidlna.conf
  service minidlna force-reload
  service minidlna reload

  echo 'install_dlna_server' >> $COMPLETION_FILE
}

function install_mediagoblin {
  # These instructions don't work and need fixing
  return
  if grep -Fxq "install_mediagoblin" $COMPLETION_FILE; then
      return
  fi
  if [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      return
  fi
  # if this is exclusively a writer setup
  if [[ $SYSTEM_TYPE == "$VARIANT_MEDIA" ]]; then
      MEDIAGOBLIN_DOMAIN_NAME=$DOMAIN_NAME
      MEDIAGOBLIN_FREEDNS_SUBDOMAIN_CODE=$FREEDNS_SUBDOMAIN_CODE
  fi
  if [ ! $MEDIAGOBLIN_DOMAIN_NAME ]; then
      return
  fi
  apt-get -y --force-yes install git-core python python-dev python-lxml python-imaging python-virtualenv
  apt-get -y --force-yes install python-gst-1.0 libjpeg8-dev sqlite3 libapache2-mod-fcgid gstreamer1.0-plugins-base gstreamer1.0-plugins-bad gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-libav python-numpy python-scipy libsndfile1-dev
  apt-get -y --force-yes install postgresql postgresql-client python-psycopg2 python-pip autotools-dev automake

  sudo -u postgres createuser -A -D mediagoblin
  sudo -u postgres createdb -E UNICODE -O mediagoblin mediagoblin

  adduser --system mediagoblin

  MEDIAGOBLIN_DOMAIN_ROOT="/srv/$MEDIAGOBLIN_DOMAIN_NAME"
  MEDIAGOBLIN_PATH="$MEDIAGOBLIN_DOMAIN_ROOT/mediagoblin"
  MEDIAGOBLIN_PATH_BIN="$MEDIAGOBLIN_PATH/mediagoblin/bin"

  if [ ! -d $MEDIAGOBLIN_DOMAIN_ROOT ]; then
      mkdir -p $MEDIAGOBLIN_DOMAIN_ROOT
  fi
  cd $MEDIAGOBLIN_DOMAIN_ROOT
  chown -hR mediagoblin: $MEDIAGOBLIN_DOMAIN_ROOT
  su -c "cd $MEDIAGOBLIN_DOMAIN_ROOT; git clone git://gitorious.org/mediagoblin/mediagoblin.git" - mediagoblin
  su -c "cd $MEDIAGOBLIN_PATH; git submodule init" - mediagoblin
  su -c "cd $MEDIAGOBLIN_PATH; git submodule update" - mediagoblin

  #su -c 'cd $MEDIAGOBLIN_PATH; ./experimental-bootstrap.sh' - mediagoblin
  #su -c 'cd $MEDIAGOBLIN_PATH; ./configure' - mediagoblin
  #su -c 'cd $MEDIAGOBLIN_PATH; make' - mediagoblin

  su -c "cd $MEDIAGOBLIN_PATH; virtualenv --system-site-packages ." - mediagoblin
  su -c "cd $MEDIAGOBLIN_PATH_BIN; python setup.py develop" - mediagoblin

  su -c "cp $MEDIAGOBLIN_PATH/mediagoblin.ini $MEDIAGOBLIN_PATH/mediagoblin_local.ini" - mediagoblin
  su -c "cp $MEDIAGOBLIN_PATH/paste.ini $MEDIAGOBLIN_PATH/paste_local.ini" - mediagoblin

  # update the dynamic DNS
  if [ $MEDIAGOBLIN_FREEDNS_SUBDOMAIN_CODE ]; then
      if [[ $MEDIAGOBLIN_FREEDNS_SUBDOMAIN_CODE != $FREEDNS_SUBDOMAIN_CODE ]]; then
          if ! grep -q "$MEDIAGOBLIN_DOMAIN_NAME" /usr/bin/dynamicdns; then
              echo "# $MEDIAGOBLIN_DOMAIN_NAME" >> /usr/bin/dynamicdns
              echo "wget -O - https://freedns.afraid.org/dynamic/update.php?$MEDIAGOBLIN_FREEDNS_SUBDOMAIN_CODE== >> /dev/null 2>&1" >> /usr/bin/dynamicdns
          fi
      fi
  else
      echo 'WARNING: No freeDNS subdomain code given for mediagoblin. It is assumed that you are using some other dynamic DNS provider.'
  fi

  # see https://wiki.mediagoblin.org/Deployment / uwsgi with configs
  apt-get -y --force-yes install uwsgi uwsgi-plugin-python nginx-full supervisor

  echo 'server {' > /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        include /etc/nginx/mime.types;' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        autoindex off;' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        default_type  application/octet-stream;' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        sendfile on;' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        # Gzip' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        gzip on;' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        gzip_min_length 1024;' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        gzip_buffers 4 32k;' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        gzip_types text/plain text/html application/x-javascript text/javascript text/xml text/css;' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo "        server_name $MEDIAGOBLIN_DOMAIN_NAME;" >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        access_log /var/log/nginx/mg.access.log;' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        error_log /var/log/nginx/mg.error.log error;' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        #include global/common.conf;' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        client_max_body_size 100m;' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        add_header X-Content-Type-Options nosniff;' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo "        root $MEDIAGOBLIN_PATH/;" >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        location /mgoblin_static/ {' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo "                alias $MEDIAGOBLIN_PATH/static/;" >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        }' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        location /mgoblin_media/ {' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo "                alias $MEDIAGOBL_PATH/media/public/;" >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        }' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        location /theme_static/ {' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        }' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        location /plugin_static/ {' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        }' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        location / {' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '                uwsgi_pass unix:///tmp/mg.uwsgi.sock;' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '                uwsgi_param SCRIPT_NAME "/";' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '                include uwsgi_params;' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '        }' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME
  echo '}' >> /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME

  echo 'uwsgi:' > /etc/uwsgi/apps-available/mg.yaml
  echo ' uid: mediagoblin' >> /etc/uwsgi/apps-available/mg.yaml
  echo ' gid: mediagoblin' >> /etc/uwsgi/apps-available/mg.yaml
  echo ' socket: /tmp/mg.uwsgi.sock' >> /etc/uwsgi/apps-available/mg.yaml
  echo ' chown-socket: www-data:www-data' >> /etc/uwsgi/apps-available/mg.yaml
  echo ' plugins: python' >> /etc/uwsgi/apps-available/mg.yaml
  echo " home: $MEDIAGOBLIN_PATH/" >> /etc/uwsgi/apps-available/mg.yaml
  echo " chdir: $MEDIAGOBLIN_PATH/" >> /etc/uwsgi/apps-available/mg.yaml
  echo " ini-paste: $MEDIAGOBLIN_PATH/paste_local.ini" >> /etc/uwsgi/apps-available/mg.yaml

  echo '[program:celery]' > /etc/supervisor/conf.d/mediagoblin.conf
  echo "command=$MEDIAGOBLIN_PATH_BIN/celery worker -l debug" >> /etc/supervisor/conf.d/mediagoblin.conf
  echo '' >> /etc/supervisor/conf.d/mediagoblin.conf
  echo '; Set PYTHONPATH to the directory containing celeryconfig.py' >> /etc/supervisor/conf.d/mediagoblin.conf
  echo "environment=PYTHONPATH='$MEDIAGOBLIN_PATH',MEDIAGOBLIN_CONFIG='$MEDIAGOBLIN_PATH/mediagoblin_local.ini',CELERY_CONFIG_MODULE='mediagoblin.init.celery.from_celery'" >> /etc/supervisor/conf.d/mediagoblin.conf
  echo '' >> /etc/supervisor/conf.d/mediagoblin.conf
  echo "directory=$MEDIAGOBLIN_PATH/" >> /etc/supervisor/conf.d/mediagoblin.conf
  echo 'user=mediagoblin' >> /etc/supervisor/conf.d/mediagoblin.conf
  echo 'numprocs=1' >> /etc/supervisor/conf.d/mediagoblin.conf
  echo '; uncomment below to enable logs saving' >> /etc/supervisor/conf.d/mediagoblin.conf
  echo ";stdout_logfile=/var/log/nginx/celeryd_stdout.log" >> /etc/supervisor/conf.d/mediagoblin.conf
  echo ";stderr_logfile=/var/log/nginx/celeryd_stderr.log" >> /etc/supervisor/conf.d/mediagoblin.conf
  echo 'autostart=true' >> /etc/supervisor/conf.d/mediagoblin.conf
  echo 'autorestart=false' >> /etc/supervisor/conf.d/mediagoblin.conf
  echo 'startsecs=10' >> /etc/supervisor/conf.d/mediagoblin.conf
  echo '' >> /etc/supervisor/conf.d/mediagoblin.conf
  echo '; Need to wait for currently executing tasks to finish at shutdown.' >> /etc/supervisor/conf.d/mediagoblin.conf
  echo '; Increase this if you have very long running tasks.' >> /etc/supervisor/conf.d/mediagoblin.conf
  echo 'stopwaitsecs = 600' >> /etc/supervisor/conf.d/mediagoblin.conf

  ln -s /etc/nginx/sites-available/$MEDIAGOBLIN_DOMAIN_NAME /etc/nginx/sites-enabled/
  ln -s /etc/uwsgi/apps-available/mg.yaml /etc/uwsgi/apps-enabled/

  # change settings
  sed -i "s/notice@mediagoblin.example.org/$MY_USERNAME@$DOMAIN_NAME/g" $MEDIAGOBLIN_PATH/mediagoblin_local.ini
  sed -i 's/email_debug_mode = true/email_debug_mode = false/g' $MEDIAGOBLIN_PATH/mediagoblin_local.ini
  sed -i 's|# sql_engine = postgresql:///mediagoblin|sql_engine = postgresql:///mediagoblin|g' $MEDIAGOBLIN_PATH/mediagoblin_local.ini

  # add extra media types
  if grep -q "media_types.audio" $MEDIAGOBLIN_PATH/mediagoblin_local.ini; then
      echo '[[mediagoblin.media_types.audio]]' >> $MEDIAGOBLIN_PATH/mediagoblin_local.ini
  fi
  if grep -q "media_types.video" $MEDIAGOBLIN_PATH/mediagoblin_local.ini; then
      echo '[[mediagoblin.media_types.video]]' >> $MEDIAGOBLIN_PATH/mediagoblin_local.ini
  fi
  if grep -q "media_types.stl" $MEDIAGOBLIN_PATH/mediagoblin_local.ini; then
      echo '[[mediagoblin.media_types.stl]]' >> $MEDIAGOBLIN_PATH/mediagoblin_local.ini
  fi

  su -c "cd $MEDIAGOBLIN_PATH_BIN; pip install scikits.audiolab" - mediagoblin
  su -c "cd $MEDIAGOBLIN_PATH_BIN; gmg dbupdate" - mediagoblin

  # systemd init scripts

  echo '[Unit]' > /etc/systemd/system/gmg.service
  echo 'Description=Mediagoblin' >> /etc/systemd/system/gmg.service
  echo '' >> /etc/systemd/system/gmg.service
  echo '[Service]' >> /etc/systemd/system/gmg.service
  echo 'Type=forking' >> /etc/systemd/system/gmg.service
  echo 'User=mediagoblin' >> /etc/systemd/system/gmg.service
  echo 'Group=mediagoblin' >> /etc/systemd/system/gmg.service
  echo '#Environment=CELERY_ALWAYS_EAGER=true' >> /etc/systemd/system/gmg.service
  echo 'Environment=CELERY_ALWAYS_EAGER=false' >> /etc/systemd/system/gmg.service
  echo "WorkingDirectory=$MEDIAGOBLIN_PATH" >> /etc/systemd/system/gmg.service
  echo "ExecStart=$MEDIAGOBLIN_PATH_BIN/paster serve $MEDIAGOBLIN_PATH/paste_local.ini --pid-file=/var/run/mediagoblin/paster.pid --log-file=/var/log/nginx/mediagoblin_paster.log --daemon --server-name=fcgi fcgi_host=127.0.0.1 fcgi_port=26543" >> /etc/systemd/system/gmg.service
  echo "ExecStop=$MEDIAGOBLIN_PATH_BIN/paster serve --pid-file=/var/run/mediagoblin/paster.pid $MEDIAGOBLIN_PATH/paste_local.ini stop" >> /etc/systemd/system/gmg.service
  echo 'PIDFile=/var/run/mediagoblin/mediagoblin.pid' >> /etc/systemd/system/gmg.service
  echo '' >> /etc/systemd/system/gmg.service
  echo '[Install]' >> /etc/systemd/system/gmg.service
  echo 'WantedBy=multi-user.target' >> /etc/systemd/system/gmg.service


  echo '[Unit]' > /etc/systemd/system/gmg-celeryd.service
  echo 'Description=Mediagoblin Celeryd' >> /etc/systemd/system/gmg-celeryd.service
  echo '' >> /etc/systemd/system/gmg-celeryd.service
  echo '[Service]' >> /etc/systemd/system/gmg-celeryd.service
  echo 'User=mediagoblin' >> /etc/systemd/system/gmg-celeryd.service
  echo 'Group=mediagoblin' >> /etc/systemd/system/gmg-celeryd.service
  echo 'Type=simple' >> /etc/systemd/system/gmg-celeryd.service
  echo "WorkingDirectory=$MEDIAGOBLIN_PATH" >> /etc/systemd/system/gmg-celeryd.service
  echo "Environment='MEDIAGOBLIN_CONFIG=$MEDIAGOBLIN_PATH/mediagoblin_local.ini' CELERY_CONFIG_MODULE=mediagoblin.init.celery.from_celery" >> /etc/systemd/system/gmg-celeryd.service
  echo "ExecStart=$MEDIAGOBLIN_PATH_BIN/celeryd" >> /etc/systemd/system/gmg-celeryd.service
  echo 'PIDFile=/var/run/mediagoblin/mediagoblin-celeryd.pid' >> /etc/systemd/system/gmg-celeryd.service
  echo '' >> /etc/systemd/system/gmg-celeryd.service
  echo '[Install]' >> /etc/systemd/system/gmg-celeryd.service
  echo 'WantedBy=multi-user.target' >> /etc/systemd/system/gmg-celeryd.service

  systemctl start gmg.service
  systemctl start gmg-celeryd.service

  echo 'install_mediagoblin' >> $COMPLETION_FILE
}

function create_backup_script {
  if grep -Fxq "create_backup_script" $COMPLETION_FILE; then
      return
  fi

  apt-get -y --force-yes install rsyncrypto

  if [ ! -f /usr/bin/rsyncrypto ]; then
      echo "ERROR: rsyncrypto may not have installed correctly. $CHECK_MESSAGE"
      exit 46
  fi

  echo '#!/bin/bash' > /usr/bin/$BACKUP_SCRIPT_NAME
  echo '' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "if [ ! -f /etc/ssl/private/rsync.key ]; then" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo '  echo "Generating an rsync encryption certificate"' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "  openssl req -nodes -newkey rsa:2048 -x509 -sha256 -keyout /etc/ssl/private/rsync.key -out /etc/ssl/certs/rsync.crt" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo '  chmod 400 /etc/ssl/private/rsync.key' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo '  rm /etc/ssl/certs/rsync.crt' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "fi" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo '' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo 'if [ ! -d ~/rr ]; then' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo '  mkdir ~/rr' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo 'fi' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo 'if [ ! -d ~/rr/keys ]; then' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "  mkdir ~/rr/keys" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo 'fi' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo '' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "if [ -b $USB_DRIVE ]; then" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "  if [ ! -d $USB_MOUNT ]; then" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "    mkdir $USB_MOUNT" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "    mount $USB_DRIVE $USB_MOUNT" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo '  fi' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "  if [ ! -d $USB_MOUNT/backup ]; then" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "    mkdir $USB_MOUNT/backup" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo '  fi' >> /usr/bin/$BACKUP_SCRIPT_NAME
  # email
  if ! [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" || $SYSTEM_TYPE == "$VARIANT_NONMAILBOX" ]]; then
      echo "  if [ ! -d $USB_MOUNT/backup/Maildir ]; then" >> /usr/bin/$BACKUP_SCRIPT_NAME
      echo "    mkdir $USB_MOUNT/backup/Maildir" >> /usr/bin/$BACKUP_SCRIPT_NAME
      echo '  fi' >> /usr/bin/$BACKUP_SCRIPT_NAME
      echo "  rsyncrypto --ne-nesting=2 --trim=3 -n ~/rr/map -cvr /home/$MY_USERNAME/Maildir $USB_MOUNT/backup/Maildir ~/rr/keys /etc/ssl/private/rsync.key" >> /usr/bin/$BACKUP_SCRIPT_NAME
      echo "  if [ ! -d $USB_MOUNT/backup/gpg ]; then" >> /usr/bin/$BACKUP_SCRIPT_NAME
      echo "    mkdir $USB_MOUNT/backup/gpg" >> /usr/bin/$BACKUP_SCRIPT_NAME
      echo '  fi' >> /usr/bin/$BACKUP_SCRIPT_NAME
      echo "  rsyncrypto --ne-nesting=2 --trim=3 -n ~/rr/map -cvr /home/$MY_USERNAME/.gnupg $USB_MOUNT/backup/gpg ~/rr/keys /etc/ssl/private/rsync.key" >> /usr/bin/$BACKUP_SCRIPT_NAME
      echo "  cp -f /home/$MY_USERNAME/.muttrc $USB_MOUNT/backup/gpg" >> /usr/bin/$BACKUP_SCRIPT_NAME
      echo "  cp -f /home/$MY_USERNAME/.procmailrc $USB_MOUNT/backup/gpg" >> /usr/bin/$BACKUP_SCRIPT_NAME
  fi
  # personal directory
  echo "  if [ -d /home/$MY_USERNAME/personal ]; then" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "    if [ ! -d $USB_MOUNT/backup/personal ]; then" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "      mkdir $USB_MOUNT/backup/personal" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo '    fi' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "    rsyncrypto --ne-nesting=2 --trim=3 -n ~/rr/map -cvr /home/$MY_USERNAME/personal $USB_MOUNT/backup/personal ~/rr/keys /etc/ssl/private/rsync.key" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo '  fi' >> /usr/bin/$BACKUP_SCRIPT_NAME
  # SSL certificates
  echo "  if [ ! -d $USB_MOUNT/backup/ssl ]; then" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "    mkdir $USB_MOUNT/backup/ssl" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo '  fi' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "  rsyncrypto --ne-nesting=2 --trim=3 -n ~/rr/map -cvr /etc/ssl $USB_MOUNT/backup/ssl ~/rr/keys /etc/ssl/private/rsync.key" >> /usr/bin/$BACKUP_SCRIPT_NAME
  # dynamic dns
  echo "  if [ -f /usr/bin/dynamicdns ]; then" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "    cp -f /usr/bin/dynamicdns $USB_MOUNT/backup/dynamicdns" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo '  fi' >> /usr/bin/$BACKUP_SCRIPT_NAME
  # web server
  echo "  if [ -d /etc/nginx ]; then" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "    if [ ! -d $USB_MOUNT/backup/webserver ]; then" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "        mkdir $USB_MOUNT/backup/webserver" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo '    fi' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "    rsyncrypto --ne-nesting=2 --trim=3 -n ~/rr/map -cvr /etc/nginx/sites-available $USB_MOUNT/backup/webserver ~/rr/keys /etc/ssl/private/rsync.key" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo '  fi' >> /usr/bin/$BACKUP_SCRIPT_NAME
  # owncloud
  if ! [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" ]]; then
      if [ $OWNCLOUD_DOMAIN_NAME ]; then
          echo "  if [ ! -d $USB_MOUNT/backup/owncloud ]; then" >> /usr/bin/$BACKUP_SCRIPT_NAME
          echo "    mkdir $USB_MOUNT/backup/owncloud" >> /usr/bin/$BACKUP_SCRIPT_NAME
          echo '  fi' >> /usr/bin/$BACKUP_SCRIPT_NAME
          echo "  rsyncrypto --ne-nesting=2 --trim=3 -n ~/rr/map -cvr /var/www/$OWNCLOUD_DOMAIN_NAME $USB_MOUNT/backup/owncloud ~/rr/keys /etc/ssl/private/rsync.key" >> /usr/bin/$BACKUP_SCRIPT_NAME
      fi
  fi
  # prosody
  echo '  if [ -d /var/lib/prosody ]; then' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "    if [ ! -d $USB_MOUNT/backup/prosody ]; then" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "      mkdir $USB_MOUNT/backup/prosody" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo '    fi' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo "    rsyncrypto --ne-nesting=2 --trim=3 -n ~/rr/map -cvr /var/lib/prosody $USB_MOUNT/backup/prosody ~/rr/keys /etc/ssl/private/rsync.key" >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo '  fi' >> /usr/bin/$BACKUP_SCRIPT_NAME
  # wiki / blog
  if ! [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" ]]; then
      if [ $WIKI_DOMAIN_NAME ]; then
          echo "  if [ ! -d $USB_MOUNT/backup/wiki-blog ]; then" >> /usr/bin/$BACKUP_SCRIPT_NAME
          echo "    mkdir $USB_MOUNT/backup/wiki-blog" >> /usr/bin/$BACKUP_SCRIPT_NAME
          echo '  fi' >> /usr/bin/$BACKUP_SCRIPT_NAME
          echo "  rsyncrypto --ne-nesting=2 --trim=3 -n ~/rr/map -cvr /var/www/$WIKI_DOMAIN_NAME $USB_MOUNT/backup/wiki-blog ~/rr/keys /etc/ssl/private/rsync.key" >> /usr/bin/$BACKUP_SCRIPT_NAME
      fi
  fi
  # microblog
  if ! [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_MEDIA" ]]; then
      if [ $MICROBLOG_DOMAIN_NAME ]; then
          echo "  if [ ! -d $USB_MOUNT/backup/gnusocial ]; then" >> /usr/bin/$BACKUP_SCRIPT_NAME
          echo "    mkdir $USB_MOUNT/backup/gnusocial" >> /usr/bin/$BACKUP_SCRIPT_NAME
          echo '  fi' >> /usr/bin/$BACKUP_SCRIPT_NAME
          echo "  mysqldump --password=$MARIADB_PASSWORD gnusocial > $USB_MOUNT/backup/gnusocial/database.sql" >> /usr/bin/$BACKUP_SCRIPT_NAME
      fi
  fi
  # redmatrix
  if ! [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_MEDIA" ]]; then
      if [ $REDMATRIX_DOMAIN_NAME ]; then
          echo "  if [ ! -d $USB_MOUNT/backup/redmatrix ]; then" >> /usr/bin/$BACKUP_SCRIPT_NAME
          echo "    mkdir $USB_MOUNT/backup/redmatrix" >> /usr/bin/$BACKUP_SCRIPT_NAME
          echo '  fi' >> /usr/bin/$BACKUP_SCRIPT_NAME
          echo "  mysqldump --password=$MARIADB_PASSWORD redmatrix > $USB_MOUNT/backup/redmatrix/database.sql" >> /usr/bin/$BACKUP_SCRIPT_NAME
      fi
  fi
  # dlna
  if [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      echo "  if [ ! -d $USB_MOUNT/backup/dlna ]; then" >> /usr/bin/$BACKUP_SCRIPT_NAME
      echo "    mkdir $USB_MOUNT/backup/dlna" >> /usr/bin/$BACKUP_SCRIPT_NAME
      echo '  fi' >> /usr/bin/$BACKUP_SCRIPT_NAME
      echo "  rsyncrypto --ne-nesting=2 --trim=3 -n ~/rr/map -cvr /var/cache/minidlna $USB_MOUNT/backup/dlna ~/rr/keys /etc/ssl/private/rsync.key" >> /usr/bin/$BACKUP_SCRIPT_NAME
  fi
  echo 'else' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo '  echo "Please insert a USB drive to create the backup."' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo '  exit 1' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo 'fi' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo 'echo "Backup completed"' >> /usr/bin/$BACKUP_SCRIPT_NAME
  echo 'exit 0' >> /usr/bin/$BACKUP_SCRIPT_NAME
  chmod 600 /usr/bin/$BACKUP_SCRIPT_NAME
  chmod +x /usr/bin/$BACKUP_SCRIPT_NAME

  echo 'create_backup_script' >> $COMPLETION_FILE
}

function create_restore_script {
  if grep -Fxq "create_restore_script" $COMPLETION_FILE; then
      return
  fi
  apt-get -y --force-yes install rsyncrypto

  if [ ! -f /usr/bin/rsyncrypto ]; then
      echo "ERROR: rsyncrypto may not have installed correctly. $CHECK_MESSAGE"
      exit 47
  fi

  DIR_TRIM=3
  echo '#!/bin/bash' > /usr/bin/$RESTORE_SCRIPT_NAME
  echo '' >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo 'if [ ! -f /etc/ssl/private/rsync.key ]; then' >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo '  echo "No rsync certificate found"' >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo '  exit 2' >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo 'fi' >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo '' >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo "if [ -b $USB_DRIVE ]; then" >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo "  if [ ! -d $USB_MOUNT ]; then" >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo "    mkdir $USB_MOUNT" >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo "    mount $USB_DRIVE $USB_MOUNT" >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo '  fi' >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo "  if [ ! -d $USB_MOUNT/backup ]; then" >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo '    echo "No backup directory was found on the USB drive"' >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo "    exit 1" >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo '  fi' >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo '' >> /usr/bin/$RESTORE_SCRIPT_NAME
  # email
  if ! [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" || $SYSTEM_TYPE == "$VARIANT_NONMAILBOX" ]]; then
      echo "  if [ -d $USB_MOUNT/backup/Maildir ]; then" >> /usr/bin/$RESTORE_SCRIPT_NAME
      echo "    rsyncrypto --trim=${DIR_TRIM} -vrd $USB_MOUNT/backup/Maildir /home/$MY_USERNAME/Maildir ~/rr/keys /etc/ssl/private/rsync.key" >> /usr/bin/$RESTORE_SCRIPT_NAME
      echo "    rsyncrypto --trim=${DIR_TRIM} -vrd $USB_MOUNT/backup/gpg /home/$MY_USERNAME/.gnupg ~/rr/keys /etc/ssl/private/rsync.key" >> /usr/bin/$RESTORE_SCRIPT_NAME
      echo "    cp -f $USB_MOUNT/backup/gpg/.muttrc /home/$MY_USERNAME" >> /usr/bin/$RESTORE_SCRIPT_NAME
      echo "    cp -f $USB_MOUNT/backup/gpg/.procmailrc /home/$MY_USERNAME" >> /usr/bin/$RESTORE_SCRIPT_NAME
      echo '  fi' >> /usr/bin/$RESTORE_SCRIPT_NAME
  fi
  # personal directory
  echo "  if [ -d $USB_MOUNT/backup/personal ]; then" >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo "    rsyncrypto --trim=${DIR_TRIM} -vrd $USB_MOUNT/backup/personal /home/$MY_USERNAME/personal ~/rr/keys /etc/ssl/private/rsync.key" >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo '  fi' >> /usr/bin/$RESTORE_SCRIPT_NAME
  # SSL certificates
  echo "  if [ -d $USB_MOUNT/backup/ssl ]; then" >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo "    rsyncrypto --trim=${DIR_TRIM} -vrd $USB_MOUNT/backup/ssl /etc/ssl ~/rr/keys /etc/ssl/private/rsync.key" >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo '  fi' >> /usr/bin/$RESTORE_SCRIPT_NAME
  # dynamic dns
  echo "  if [ -f $USB_MOUNT/backup/dynamicdns ]; then" >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo "    cp -f $USB_MOUNT/backup/dynamicdns /usr/bin/dynamicdns" >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo '  fi' >> /usr/bin/$RESTORE_SCRIPT_NAME
  # web server
  echo "  if [ -d /etc/nginx ]; then" >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo "    if [ -d $USB_MOUNT/backup/webserver ]; then" >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo "      rsyncrypto --trim=${DIR_TRIM} -vrd $USB_MOUNT/backup/webserver /etc/nginx ~/rr/keys /etc/ssl/private/rsync.key" >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo '    fi' >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo '  fi' >> /usr/bin/$RESTORE_SCRIPT_NAME
  # owncloud
  if ! [[ $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" ]]; then
      if [ $OWNCLOUD_DOMAIN_NAME ]; then
          echo "  if [ -d $USB_MOUNT/backup/owncloud ]; then" >> /usr/bin/$RESTORE_SCRIPT_NAME
          echo "    rsyncrypto --trim=${DIR_TRIM} -vrd $USB_MOUNT/backup/owncloud /var/www/$OWNCLOUD_DOMAIN_NAME ~/rr/keys /etc/ssl/private/rsync.key" >> /usr/bin/$RESTORE_SCRIPT_NAME
          echo '  fi' >> /usr/bin/$RESTORE_SCRIPT_NAME
      fi
  fi
  # prosody
  echo '  if [ -d /var/lib/prosody ]; then' >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo "    if [ -d $USB_MOUNT/backup/prosody ]; then" >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo "      rsyncrypto --trim=${DIR_TRIM} -vrd $USB_MOUNT/backup/prosody /var/lib/prosody ~/rr/keys /etc/ssl/private/rsync.key" >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo '    fi' >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo '  fi' >> /usr/bin/$RESTORE_SCRIPT_NAME
  # wiki / blog
  if ! [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" || $SYSTEM_TYPE == "$VARIANT_MEDIA" ]]; then
      if [ $WIKI_DOMAIN_NAME ]; then
          echo "  if [ -d $USB_MOUNT/backup/wiki-blog ]; then" >> /usr/bin/$RESTORE_SCRIPT_NAME
          echo "    rsyncrypto --trim=${DIR_TRIM} -vrd $USB_MOUNT/backup/wiki-blog /var/www/$WIKI_DOMAIN_NAME ~/rr/keys /etc/ssl/private/rsync.key" >> /usr/bin/$RESTORE_SCRIPT_NAME
          echo '  fi' >> /usr/bin/$RESTORE_SCRIPT_NAME
      fi
  fi
  # microblog
  if ! [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_MEDIA" ]]; then
      if [ $MICROBLOG_DOMAIN_NAME ]; then
          echo "  if [ -d $USB_MOUNT/backup/gnusocial ]; then" >> /usr/bin/$RESTORE_SCRIPT_NAME
          echo "    mysql -u root --password=$MARIADB_PASSWORD gnusocial -o < $USB_MOUNT/backup/gnusocial/database.sql" >> /usr/bin/$RESTORE_SCRIPT_NAME
          echo '  fi' >> /usr/bin/$RESTORE_SCRIPT_NAME

      fi
  fi
  # redmatrix
  if ! [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_MEDIA" ]]; then
      if [ $REDMATRIX_DOMAIN_NAME ]; then
          echo "  if [ -d $USB_MOUNT/backup/redmatrix ]; then" >> /usr/bin/$RESTORE_SCRIPT_NAME
          echo "    mysql -u root --password=$MARIADB_PASSWORD redmatrix -o < $USB_MOUNT/backup/redmatrix/database.sql" >> /usr/bin/$RESTORE_SCRIPT_NAME
          echo '  fi' >> /usr/bin/$RESTORE_SCRIPT_NAME
IPT_NAME
      fi
  fi
  # dlna
  if [[ $SYSTEM_TYPE == "$VARIANT_CLOUD" || $SYSTEM_TYPE == "$VARIANT_MAILBOX" || $SYSTEM_TYPE == "$VARIANT_CHAT" || $SYSTEM_TYPE == "$VARIANT_WRITER" || $SYSTEM_TYPE == "$VARIANT_SOCIAL" ]]; then
      echo "  if [ -d $USB_MOUNT/backup/dlna ]; then" >> /usr/bin/$RESTORE_SCRIPT_NAME
      echo "    rsyncrypto --trim=${DIR_TRIM} -vrd $USB_MOUNT/backup/minidlna /var/cache/minidlna ~/rr/keys /etc/ssl/private/rsync.key" >> /usr/bin/$RESTORE_SCRIPT_NAME
      echo '  fi' >> /usr/bin/$RESTORE_SCRIPT_NAME
  fi
  echo 'else' >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo '  echo "Please insert a USB drive containing the backup."' >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo '  exit 1' >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo 'fi' >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo 'Restore completed' >> /usr/bin/$RESTORE_SCRIPT_NAME
  echo 'exit 0' >> /usr/bin/$RESTORE_SCRIPT_NAME
  chmod 600 /usr/bin/$RESTORE_SCRIPT_NAME
  chmod +x /usr/bin/$RESTORE_SCRIPT_NAME

  echo 'create_restore_script' >> $COMPLETION_FILE
}

function install_final {
  if grep -Fxq "install_final" $COMPLETION_FILE; then
      return
  fi
  # unmount any attached usb drive
  if [ -d $USB_MOUNT ]; then
      umount $USB_MOUNT
      rm -rf $USB_MOUNT
  fi
  apt-get -y --force-yes autoremove
  echo 'install_final' >> $COMPLETION_FILE
  echo ''
  echo '  *** Freedombone installation is complete. Rebooting... ***'
  echo ''
  if [ -f "/home/$MY_USERNAME/README" ]; then
      echo "See /home/$MY_USERNAME/README for post-installation instructions."
      echo ''
  fi
  reboot
}

argument_checks
remove_default_user
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
enforce_good_passwords
install_editor
change_login_message
update_the_kernel
enable_zram
random_number_generator
set_your_domain_name
create_backup_script
create_restore_script
time_synchronisation
configure_internet_protocol
configure_ssh
check_hwrng
search_for_attached_usb_drive
regenerate_ssh_keys
script_to_make_self_signed_certificates
configure_email
#spam_filtering
configure_imap
configure_gpg
encrypt_incoming_email
email_client
configure_firewall_for_email
folders_for_mailing_lists
folders_for_email_addresses
dynamic_dns_freedns
#create_private_mailing_list
import_email
script_for_attaching_usb_drive
install_web_server
configure_firewall_for_web_server
install_owncloud
install_xmpp
configure_firewall_for_xmpp
install_irc_server
configure_firewall_for_irc
install_wiki
install_blog
install_gnu_social
install_redmatrix
install_dlna_server
install_mediagoblin
install_final
echo 'Freedombone installation is complete'
exit 0
