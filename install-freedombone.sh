#!/bin/bash
# Freedombone install script intended for use with Debian Jessie

DOMAIN_NAME=$1
MY_USERNAME=$2

SSH_PORT=2222
KERNEL_VERSION="v3.15.10-bone7"
USE_HWRNG="yes"

# Directory where source code is downloaded and compiled
INSTALL_DIR=/root/build

export DEBIAN_FRONTEND=noninteractive

# File which keeps track of what has already been installed
COMPLETION_FILE=/root/freedombone-completed.txt
if [ ! -f $COMPLETION_FILE ]; then
	touch $COMPLETION_FILE
fi

function argument_checks {
  if [ ! $DOMAIN_NAME ]; then
	  echo "Please specify your domain name"
	  exit
  fi
  if [ ! $MY_USERNAME ]; then
	  echo "Please specify your username"
	  exit
  fi
}

function remove_proprietary_repos {
  if [ grep -Fxq "remove_proprietary_repos" $COMPLETION_FILE ]; then
	  return
  fi
  sed -i 's/ non-free//g' /etc/apt/sources.list
  echo 'remove_proprietary_repos' >> $COMPLETION_FILE
}

function initial_setup {
  if [ grep -Fxq "initial_setup" $COMPLETION_FILE ]; then
	  return
  fi
  apt-get -y update
  apt-get -y dist-upgrade
  apt-get -y install ca-certificates emacs24
  echo 'initial_setup' >> $COMPLETION_FILE
}

function install_editor {
  if [ grep -Fxq "install_editor" $COMPLETION_FILE ]; then
	  return
  fi
  update-alternatives --set editor /usr/bin/emacs24
  echo 'install_editor' >> $COMPLETION_FILE
}

function enable_backports {
  if [ grep -Fxq "enable_backports" $COMPLETION_FILE ]; then
	  return
  fi
  echo "deb http://ftp.us.debian.org/debian jessie-backports main" >> /etc/apt/sources.list
  echo 'enable_backports' >> $COMPLETION_FILE
}

function update_the_kernel {
  if [ grep -Fxq "update_the_kernel" $COMPLETION_FILE ]; then
	  return
  fi
  cd /opt/scripts/tools
  ./update_kernel.sh --kernel $KERNEL_VERSION
  echo 'update_the_kernel' >> $COMPLETION_FILE
}

function enable_zram {
  if [ grep -Fxq "enable_zram" $COMPLETION_FILE ]; then
	  return
  fi
  echo "options zram num_devices=1" >> /etc/modprobe.d/zram.conf
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
  if [ grep -Fxq "random_number_generator" $COMPLETION_FILE ]; then
	  return
  fi
  if [ $USE_HWRNG == "yes" ]; then
    apt-get -y install rng-tools
    sed -i 's|#HRNGDEVICE=/dev/hwrng|HRNGDEVICE=/dev/hwrng|g' /etc/default/rng-tools
    echo 'random_number_generator' >> $COMPLETION_FILE
    reboot
  else
	apt-get -y install haveged
  fi
  echo 'random_number_generator' >> $COMPLETION_FILE
}

function configure_ssh {
  if [ grep -Fxq "configure_ssh" $COMPLETION_FILE ]; then
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
  service ssh restart
  apt-get -y install fail2ban
  echo 'configure_ssh' >> $COMPLETION_FILE
}

function regenerate_ssh_keys {
  if [ grep -Fxq "regenerate_ssh_keys" $COMPLETION_FILE ]; then
	  return
  fi
  rm -f /etc/ssh/ssh_host_*
  dpkg-reconfigure openssh-server
  service ssh restart
  echo 'regenerate_ssh_keys' >> $COMPLETION_FILE
}

function set_your_domain_name {
  if [ grep -Fxq "set_your_domain_name" $COMPLETION_FILE ]; then
	  return
  fi
  echo "$DOMAIN_NAME" > /etc/hostname
  hostname $DOMAIN_NAME
  echo "127.0.1.1  $DOMAIN_NAME" >> /etc/hosts
  echo 'set_your_domain_name' >> $COMPLETION_FILE
}

function time_synchronisation {
  if [ grep -Fxq "time_synchronisation" $COMPLETION_FILE ]; then
	  return
  fi
  apt-get -y install build-essential automake git pkg-config autoconf libtool libssl-dev
  apt-get -y remove ntpdate
  mkdir $INSTALL_DIR
  cd $INSTALL_DIR
  git clone https://github.com/ioerror/tlsdate.git
  cd $INSTALL_DIR/tlsdate
  ./autogen.sh
  ./configure
  make
  make install

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
  if [ grep -Fxq "configure_firewall" $COMPLETION_FILE ]; then
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

function configure_firewall_for_ssh {
  if [ grep -Fxq "configure_firewall_for_ssh" $COMPLETION_FILE ]; then
	  return
  fi
  iptables -A INPUT -i eth0 -p tcp --dport $SSH_PORT -j ACCEPT
  save_firewall_settings
  echo 'configure_firewall_for_ssh' >> $COMPLETION_FILE
}

function configure_firewall_for_email {
  if [ grep -Fxq "configure_firewall_for_email" $COMPLETION_FILE ]; then
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
  if [ grep -Fxq "configure_internet_protocol" $COMPLETION_FILE ]; then
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
  if [ grep -Fxq "script_to_make_self_signed_certificates" $COMPLETION_FILE ]; then
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
  echo '/etc/init.d/nginx reload' >> /usr/bin/makecert
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
  if [ grep -Fxq "configure_email" $COMPLETION_FILE ]; then
	  return
  fi
  apt-get -y remove postfix
  apt-get -y install exim4 sasl2-bin swaks libnet-ssleay-perl procmail
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
  sed -i '/03_exim4-config_tlsoptions/a\tls_on_connect_ports=465' /etc/exim4/exim4.conf.template

  adduser $MY_USERNAME sasl
  addgroup Debian-exim sasl
  /etc/init.d/exim4 restart
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
  if [ grep -Fxq "spam_filtering" $COMPLETION_FILE ]; then
	  return
  fi
  apt-get -y install spamassassin exim4-daemon-heavy
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

  echo "*/3 * * * * root /usr/bin/timeout 120 /usr/bin/filterspam $MY_USERNAME" >> /etc/crontab
  echo "*/3 * * * * root /usr/bin/timeout 120 /usr/bin/filterham $MY_USERNAME" >> /etc/crontab
  chmod 655 /usr/bin/filterspam /usr/bin/filterham
  sed -i 's/# use_bayes 1/use_bayes 1/g' /etc/mail/spamassassin/local.cf
  sed -i 's/# bayes_auto_learn 1/bayes_auto_learn 1/g' /etc/mail/spamassassin/local.cf

  service spamassassin restart
  service exim4 restart
  service cron restart
  echo 'spam_filtering' >> $COMPLETION_FILE
}

function configure_imap {
  if [ grep -Fxq "configure_imap" $COMPLETION_FILE ]; then
	  return
  fi
  apt-get -y install dovecot-common dovecot-imapd
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
  if [ grep -Fxq "configure_gpg" $COMPLETION_FILE ]; then
	  return
  fi
  apt-get -y install gnupg
  echo 'configure_gpg' >> $COMPLETION_FILE
}

function email_client {
  if [ grep -Fxq "email_client" $COMPLETION_FILE ]; then
	  return
  fi
  apt-get -y install mutt-patched lynx abook
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
  echo 'set pgp_replyencrypt     # autocrypt replies to crypted' >> /etc/Muttrc
  echo 'set pgp_replysign        # autosign replies to signed' >> /etc/Muttrc
  echo 'set pgp_auto_decode=yes  # decode attachments' >> /etc/Muttrc
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
  if [ grep -Fxq "folders_for_mailing_lists" $COMPLETION_FILE ]; then
	  return
  fi
  echo '#!/bin/bash' > /usr/bin/mailinglistrule
  echo 'MYUSERNAME=$1' >> /usr/bin/mailinglistrule
  echo 'MAILINGLIST=$2' >> /usr/bin/mailinglistrule
  echo 'SUBJECTTAG=$3' >> /usr/bin/mailinglistrule
  echo 'MUTTRC=/home/$MYUSERNAME/.muttrc' >> /usr/bin/mailinglistrule
  echo 'PM=/home/$MYUSERNAME/.procmailrc' >> /usr/bin/mailinglistrule
  echo 'LISTDIR=/home/$MYUSERNAME/Maildir/$MAILINGLIST' >> /usr/bin/mailinglistrule
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
  chmod +x /usr/bin/mailinglistrule
  echo 'folders_for_mailing_lists' >> $COMPLETION_FILE
}

function folders_for_email_addresses {
  if [ grep -Fxq "folders_for_email_addresses" $COMPLETION_FILE ]; then
	  return
  fi
  echo '#!/bin/bash' > /usr/bin/emailrule
  echo 'MYUSERNAME=$1' >> /usr/bin/emailrule
  echo 'EMAILADDRESS=$2' >> /usr/bin/emailrule
  echo 'MAILINGLIST=$3' >> /usr/bin/emailrule
  echo 'MUTTRC=/home/$MYUSERNAME/.muttrc' >> /usr/bin/emailrule
  echo 'PM=/home/$MYUSERNAME/.procmailrc' >> /usr/bin/emailrule
  echo 'LISTDIR=/home/$MYUSERNAME/Maildir/$MAILINGLIST' >> /usr/bin/emailrule
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
  chmod +x /usr/bin/emailrule
  echo 'folders_for_email_addresses' >> $COMPLETION_FILE
}

argument_checks
remove_proprietary_repos
initial_setup
install_editor
enable_backports
update_the_kernel
enable_zram
random_number_generator
configure_ssh
regenerate_ssh_keys
set_your_domain_name
time_synchronisation
configure_firewall
configure_firewall_for_ssh
configure_firewall_for_email
configure_internet_protocol
script_to_make_self_signed_certificates
configure_email
spam_filtering
configure_imap
configure_gpg
email_client
folders_for_mailing_lists
folders_for_email_addresses
