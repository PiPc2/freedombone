Freedombone
===========
The Freedombone system can be installed onto a Beaglebone Black, or any system capable of running Debian Jessie, and allows you to host your own email and web services. With Freedombone you can enjoy true freedom and independence in the cloud. It comes in a variety of flavours.

 - **Full install**: Installs eveything
 - **Mailbox**: An email server with GPG encryption and mailing list
 - **Cloud**: Share files, maintain a calendar and collaborate on document editing
 - **Social**: Social networking with Red Matrix and GNU Social
 - **Media**: Runs media services such as DLNA to play music or videos on your devices
 - **Writer**: Host your blog and wiki
 - **Chat**: Encrypted IRC and XMPP services for one-to-one and many-to-many chat
 - **Nonmailbox**: Installs eveything except for the email server

Unlike certain other self-hosting projects Freedombone has more emphasis on security and privacy. When installed on a Beaglebone Black it uses the built-in hardware random number generator as an entropy source and all communications with the box are encrypted by default using the recommendations from https://bettercrypto.org. The firewall is configured to only allow communications on the necessary ports and to drop all other packets, icmp is disabled by default, emails are stored in encrypted form using your public key and time synchronisation occurs via TLS only.  Backups are also encrypted.

Freedombone is, and shall remain, 100% free software. Non-free repositories are removed automatically upon installation.

Installation
============
To get started you will need:

 - A Beaglebone Black
 - A MicroSD card
 - Ethernet cable
 - Optionally a 5V 2A power supply for the Beaglebone Black
 - Access to the internet via a router with ethernet sockets
 - USB thumb drive (for backups or storing media)
 - One or more subdomains created on https://freedns.afraid.org
 - A purchased domain name and SSL certificate (only needed for Red Matrix)
 - A laptop or desktop machine with the ability to write to a microSD card (might need an adaptor)

You will also need to know, or find out, the IP address of your internet router and have a suitable static IP address for the Beaglebone on your local network. The router should allow you to forward ports to the Beaglebone (often this is under firewall or "advanced" settings).

Plug the microSD card into your laptop/desktop and then run the *freedombone-prep* command. For example:

    freedombone-prep -d /dev/sdX --ip <static LAN IP> --iprouter <router LAN IP>

where /dev/sdX is the device name for the microSD card. Often it's /dev/sdb or /dev/sdc, depending upon how many drives there are on your system. The script will download the Debian installer and update the microSD card. It can take a while, so be patient.

When the initial setup is done follow the instructions on screen to run the main Freedombone script. You can create a separate configuration file called *freedombone.cfg* which contains those variables. Variables which you might want to put into a *freedombone.cfg* file are:

    MY_EMAIL_ADDRESS=
    MY_NAME=
    MY_BLOG_TITLE=
    MY_BLOG_SUBTITLE=
    SSH_PORT=
    FULLBLOG_DOMAIN_NAME=
    FULLBLOG_FREEDNS_SUBDOMAIN_CODE=
    MICROBLOG_DOMAIN_NAME=
    MICROBLOG_FREEDNS_SUBDOMAIN_CODE=
    REDMATRIX_DOMAIN_NAME=
    OWNCLOUD_DOMAIN_NAME=
    OWNCLOUD_FREEDNS_SUBDOMAIN_CODE=
    WIKI_TITLE=
    WIKI_DOMAIN_NAME=
    WIKI_FREEDNS_SUBDOMAIN_CODE=
    MY_GPG_PUBLIC_KEY=
    MY_GPG_PRIVATE_KEY=
    ROUTE_THROUGH_TOR=no
    ENABLE_CJDNS=no
    LOCAL_NETWORK_STATIC_IP_ADDRESS=192.168.1.60

The GPG public/private key variables are for the filenames of exported GPG keys, and if a private key filename is given then it will be automatically shredded after import.

The FreeDNS subdomain codes can be found under "Dynamic DNS" and "quick cron example". On the last line it will be the string located between the '?' and the '==' characters.

The syntax of the *freedombone* command is:

    freedombone --bbb -d [domain name] -u [username] -c [FreeDNS subdomain code] -s [optional variant type]

Also see the manpage for additional options which can be used instead of a configuration file. If you don't specify a variant type with the final option then everything will be installed. If you have a *freedombone.cfg* file then it should be in the same directory from which the *freedombone* command is run.

Installation is not quick, and depends upon which variant you choose and your internet bandwidth. Allow about three hours for a full installation on the Beaglebone Black. On the Beaglebone installation is in two parts, since a reboot is needed to enable the hardware random number generator and zram.

When done you can ssh into the Freedombone with:

    ssh username@domain -p 2222

Any manual post-installation setup instructions or passwords can be found in /home/username/README. You should remove any passwords from that file and store them within a password manager such as KeepassX.

Non-Beaglebone hardware
=======================
It's also possible to install Freedombone onto other hardware. Any system with a fresh installation of Debian Jessie will do. Just make sure that you change the variable INSTALLING_ON_BBB to "no" within *freedombone.cfg* or do not include the *--bbb* option within the *freedombone* command. Obviously, you don't need to run the *freedombone-prep* command on non-Beaglebone systems.
