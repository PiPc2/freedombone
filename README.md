<img src="https://github.com/bashrc/freedombone/blob/master/ads/freedombone_ad2.png?raw=true" width=640/>

The Freedombone system can be installed onto a Beaglebone Black, or any system capable of running Debian Jessie, and allows you to host your own email and web services. With Freedombone you can enjoy true freedom and independence in the cloud. It comes in a variety of flavours.

 - **Full install**: Installs eveything
 - **Mailbox**: An email server with GPG encryption and mailing list
 - **Cloud**: Share files, maintain a calendar and collaborate on document editing
 - **Social**: Social networking with Red Matrix and GNU Social
 - **Media**: Runs media services such as DLNA to play music or videos on your devices
 - **Writer**: Host your blog and wiki
 - **Chat**: Encrypted IRC, XMPP and VoIP services for one-to-one and many-to-many chat
 - **Nonmailbox**: Installs eveything except for the email server

Freedombone has an emphasis on security and privacy, and when installed on a Beaglebone Black it uses the built-in hardware random number generator as an entropy source.  All communications with the box are encrypted by default using the recommendations from https://bettercrypto.org. The firewall is configured to only allow communications on the necessary ports and to drop all other packets, icmp is disabled by default, emails are stored in encrypted form using your public key and time synchronisation occurs via TLS only.  Backups are also encrypted and can be local or remote.

Freedombone is, and shall remain, 100% free software. Non-free repositories are removed automatically upon installation.

Preparation for the Beaglebone Black
====================================
This section is specific to the Beaglebone Black hardware. If you're not using that hardware then just skip to the next section.

To get started you will need:

 - A Beaglebone Black
 - A MicroSD card
 - Ethernet cable
 - Optionally a 5V 2A power supply for the Beaglebone Black
 - Access to the internet via a router with ethernet sockets
 - USB thumb drive (for backups or storing media)
 - One or more domains available via a dynamic DNS provider, such as https://freedns.afraid.org
 - A purchased domain name and SSL certificate (only needed for Red Matrix)
 - A laptop or desktop machine with the ability to write to a microSD card (might need an adaptor)

You will also need to know, or find out, the IP address of your internet router and have a suitable static IP address for the Beaglebone on your local network. The router should allow you to forward ports to the Beaglebone (often this is under firewall or "advanced" settings).

You can either install from a debian package or manually as follows:

    sudo apt-get install git dialog build-essential
    git clone https://github.com/bashrc/freedombone
    cd freedombone
    sudo make install

Plug the microSD card into your laptop/desktop and then run the *freedombone-prep* command. For example:

    freedombone-prep -d /dev/sdX --ip freedombone_IP_address --iprouter router_IP_address

where /dev/sdX is the device name for the microSD card. Often it's /dev/sdb or /dev/sdc, depending upon how many drives there are on your system. The script will download the Debian installer and update the microSD card. It can take a while, so be patient.

When the initial setup is done follow the instructions on screen to run the main freedombone command.

Checklist
=========
Before running the freedombone command you will need a few things.

  * Have some domains, or subdomains, registered with a dynamic DNS service
  * System with a new installation of Debian Jessie
  * Ethernet connection to an internet router
  * It is possible to forward ports from the internet router to the system
  * If you want to set up a social network or microblog then you will need SSL certificates corresponding to those domains
  * Have ssh access to the system

GPG Keys
========
If you have existing GPG keys then copy the .gnupg directory onto the system.

    scp -r ~/.gnupg username@freedombone_IP_address:/home/username

Interactive Setup
=================
The interactive server configuration setup is recommended for most users. On the system where freedombone is to be installed create a configuration file.

    ssh username@freedombone_IP_address
    su
    apt-get install git dialog
    git clone https://github.com/bashrc/freedombone
    cd freedombone
    make install

Now the easiest way to install the system is via the interactive setup.

    freedombone menuconfig

You can select which variant you wish to install and then enter the details as requested.

Non-Interactive Setup
=====================
If you don't want to install interactively then it's possible to manually create a configuration file as follows:

On the system where freedombone is to be installed create a configuration file.

    ssh username@freedombone_IP_address
    su
    apt-get install git
    git clone https://github.com/bashrc/freedombone
    cd freedombone
    make install
    nano /home/username/freedombone/freedombone.cfg

Add the following, and set the values as needed.

    MY_EMAIL_ADDRESS=
    MY_NAME=
    MY_BLOG_TITLE=
    MY_BLOG_SUBTITLE=
    FULLBLOG_DOMAIN_NAME=
    MICROBLOG_DOMAIN_NAME=
    REDMATRIX_DOMAIN_NAME=
    OWNCLOUD_DOMAIN_NAME=
    WIKI_DOMAIN_NAME=
    WIKI_TITLE=
    ENABLE_CJDNS=no
    LOCAL_NETWORK_STATIC_IP_ADDRESS=
    ROUTER_IP_ADDRESS=

Both of the IP addresses are local IP addresses, typically of the form 192.168.x.x, with one being for the system and the other being for the internet router.

Save the configuration file and exit from your editor.

Now you can begin the installation. If you are doing this on a Beaglebone Black:

    freedombone --bbb -d [default domain name] -u [username] --ddns [dynamic DNS provider domain] --ddnsuser [dynamic DNS username] --ddnspass [dynamic DNS password]

Or on any other system don't include the *--bbb* option.

    freedombone -d [default domain name] -u [username] --ddns [dynamic DNS provider domain] --ddnsuser [dynamic DNS username] --ddnspass [dynamic DNS password]

The above command should be run in the same directory in which your configuration file exists. You can use any of your domains as the default one, but typically the default domain is the same as the one for your wiki.

Also see the manpage for additional options which can be used instead of a configuration file. If you don't specify a variant type with the final option then everything will be installed. If you have a *freedombone.cfg* file then it should be in the same directory from which the *freedombone* command is run.

Post-Setup
==========
Setup of the server and installation of all the relevant packages is not quick, and depends upon which variant you choose and your internet bandwidth. Allow about three hours for a full installation on the Beaglebone Black. On the Beaglebone installation is in two parts, since a reboot is needed to enable the hardware random number generator and zram.

When done you can ssh into the Freedombone with:

    ssh username@domain -p 2222

Any manual post-installation setup instructions or passwords can be found in /home/username/README. You should remove any passwords from that file and store them within a password manager such as KeepassX.

On your internet router, typically under firewall settings, open the following ports and forward them to your server.

    | Service |      Ports |
    |---------+------------|
    | HTTP    |         80 |
    | HTTPS   |        443 |
    | SSH     |       2222 |
    | DLNA    |       1900 |
    | DLNA    |       8200 |
    | XMPP    | 5222..5223 |
    | XMPP    |       5269 |
    | XMPP    | 5280..5281 |
    | IRC     |       6697 |
    | IRC     |       9999 |
    | Git     |       9418 |
    | Email   |         25 |
    | Email   |        587 |
    | Email   |        465 |
    | Email   |        993 |
    | VoIP    |      64738 |

On Client Machines
==================
You can configure laptops or desktop machines which connect to the Freedombone server in the following way. This alters encryption settings to improve overall security.

    sudo apt-get install git dialog
    git clone https://github.com/bashrc/freedombone
    cd freedombone
    sudo make install
    freedombone-client
