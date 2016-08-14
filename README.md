<img src="https://github.com/bashrc/freedombone/blob/master/img/logo.png?raw=true" width=640/>

The Freedombone system can be installed onto a Beaglebone Black, or any system capable of running Debian Jessie, and allows you to host your own email and web services. With Freedombone you can enjoy true freedom and independence in the cloud. It comes in a variety of flavours.

 - **Full install**: Installs eveything
 - **Mailbox**: An email server with GPG encryption
 - **Cloud**: Sync and share files. Never lose important files again
 - **Social**: Social networking with Hubzilla and GNU Social
 - **Media**: Runs media services such as DLNA to play music or videos on your devices
 - **Writer**: Host your blog and wiki
 - **Chat**: Encrypted IRC, XMPP, Tox and VoIP services for one-to-one and many-to-many chat
 - **Developer**: Host your own git projects with a Github-like user interface
 - **Mesh**: A wireless mesh network which is like the internet, but not the internet

Except for the mesh variant all web systems installed also have an equivalent [onion address](https://en.wikipedia.org/wiki/.onion) so that they may be accessed via a Tor browser. This can provide some additional defense against unwanted surveillance or metadata gethering. Non-mesh variants also come with an RSS reader which provides strong reading privacy via the use of a Tor onion service.

Freedombone has an emphasis on security and privacy, and when installed on a Beaglebone Black it uses the built-in hardware random number generator as an entropy source.  All communications with the box are encrypted by default using the recommendations from https://bettercrypto.org. The firewall is configured to only allow communications on the necessary ports and to drop all other packets, icmp is disabled by default, emails are stored in encrypted form using your public key and time synchronisation occurs via TLS only.  Backups are also encrypted and can be local or remote.

Freedombone is, and shall remain, 100% free software. Non-free repositories are removed automatically upon installation.

Building an image for an SBC or Virtual Machine
===============================================
You don't have to trust images downloaded from random internet locations signed with untrusted keys. You can build one from scratch yourself, and this is the recommended procedure for maximum security. For guidance on how to build images see the manpage for the **freedombone-image** command.

Install the freedombone commands onto your laptop/desktop:

    sudo apt-get install git build-essential dialog
    git clone https://github.com/bashrc/freedombone
    cd freedombone
    sudo make install

Then install packages needed for building images:


    sudo apt-get -y install build-essential git python-docutils mktorrent
    sudo apt-get -y install vmdebootstrap xz-utils dosfstools btrfs-tools extlinux
    sudo apt-get -y install python-distro-info mbr qemu-user-static binfmt-support
    sudo apt-get -y install u-boot-tools qemu

A typical use case to build an 8GB image for a Beaglebone Black is as follows. You can change the size depending upon the capacity of your microSD card.

    freedombone-image -t beaglebone -s 8G

If you prefer an advanced installation with all of the options available then use:

    freedombone-image -t beaglebone -s 8G --minimal no

To build a 64bit Virtualbox image:

    freedombone-image -t virtualbox-amd64 -s 8G

To build a 64bit Qemu image:

    freedombone-image -t qemu-x86_64 -s 8G

Other supported boards are cubieboard2, cubietruck, olinuxino-lime, olinuxino-lime2 and olinuxino-micro.

If the image build fails with an error such as "/Error reading from server. Remote end closed connection/" then you can specify a debian package mirror repository manually with:

    freedombone-image -t beaglebone -s 8G -m http://ftp.de.debian.org/debian

Checklist
=========
Before installing Freedombone you will need a few things.

  * Have some domains, or subdomains, registered with a dynamic DNS service
  * System with a new installation of Debian Jessie or a downloaded/prepared disk image
  * Ethernet connection between the system and your internet router
  * That it is possible to forward ports from the internet router to the system, typically via firewall settings
  * Have ssh access to the system, typically via fbone@freedombone.local on port 2222

Installation
============
There are three install options: Laptop/Desktop/Netbook, SBC and Virtual Machine.

**On a Laptop, Netbook or Desktop machine**

If you have an existing system, such as an old laptop or netbook which you can leave running as a server, then install a new version of Debian Jessie onto it. During the Debian install you won't need the print server or the desktop environment, and unchecking those will reduce the attack surface. Once Debian enter the following commands:

    su
    apt-get update
    apt-get -y install git dialog build-essential
    git clone https://github.com/bashrc/freedombone
    cd freedombone
    make install
    freedombone menuconfig

**On a single board computer (SBC)**

Currently the following boards are supported:

    Beaglebone Black
    Cubieboard 2
    Cubietruck (Cubieboard 3)
    olinuxino Lime2
    olinuxino Micro

If there is no existing image available then you can build one from scratch. See the section above on how to do that. If an existing image is available then you can download it and check the signature with:

    gpg --verify filename.img.asc

And the hash with:

    sha256sum filename.img

If the image is compressed then decompress it with:

    unxz filename.img.xz

Then copy it to a microSD card. Depending on your system you may need an adaptor to be able to do that.

    sudo dd bs=1M if=filename.img of=/dev/sdX conv=fdatasync

Where **sdX** is the microSD drive. You can check which drive is the microSD drive using:

    ls /dev/sd*

With the drive removed and inserted. Copying to the microSD will take a while, so go and do something less boring instead. When it's complete remove it from your system and insert it into the SBC. Connect an ethernet cable between the SBC and your internet router, then connect the power cable. On the Beaglebone Black you will see some flashing LEDs, but on other SBCs there may not be any visual indication that anything is booting.

With the board connected and running you can ssh into the system with:

    ssh fbone@freedombone.local -p 2222

Using the password 'freedombone'. Take a note of the new login password and then you can proceed through the installation.

**As a Virtual Machine**

Virtualbox and Qemu are supported. You can run a 64 bit Qemu image with:

    qemu-system-x86_64 filename.img

If you are using Virtualbox then add a new VM and select the Freedombone **vdi** image.

The default login will be username 'fbone' and password 'freedombone'. Take a note of the new login password then you can proceed through the installation.

Social Key Management (aka "The Unforgettable Key")
===================================================
During the install procedure you will be asked if you wish to import GPG keys. If you don't already possess GPG keys then just select "Ok" and they will be generated during the install. If you do already have GPG keys then there are a few possibilities

**You have the gnupg keyring on an encrypted USB drive**

If you previously made a master keydrive containing the full keyring (the .gnupg directory). This is the most straightforward case, but not as secure as splitting the key into fragments.

**You have a number of key fragments on USB drives retrieved from friends**

If you previously made some USB drives containing key fragments then retrieve them from your friends and plug them in one after the other. After the last drive has been read then remove it and just select "Ok". The system will then try to reconstruct the key. For this to work you will need to have previously made three or more **Keydrives**.

**You can specify some ssh login details for friends servers containing key fragments**

Enter three or more sets of login details and the installer will try to retrieve key fragments and then assemble them into the full key. This only works if you previously were using remote backups and had social key management enabled.

Final Setup
===========
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
    | Tox     |      33445 |

Keydrives
=========
After installing for the first time it's a good idea to create some keydrives. These will store your gpg key so that if all else fails you will still be able to restore from backup. There are two ways to do this:

**Master Keydrive**

This is the traditional security model in which you carry your full keyring on an encrypted USB drive. To make a master keydrive first format a USB drive as a LUKS encrypted drive. In Ubuntu this can be done from the *Disk Utility* application. Then plug it into the Freedombone system, then from your local machine run:

    ssh myusername@mydomainname -p 2222

Select *Administrator controls* then *Backup and Restore* then *Backup GPG key to USB (master keydrive)*.

**Fragment keydrives**

This breaks your GPG key into a number of fragments and randomly selects one to add to the USB drive. First format a USB drive as a LUKS encrypted drive. In Ubuntu this can be done from the *Disk Utility* application. Plug it into the Freedombone system then from your local machine run the following commands:

    ssh myusername@mydomainname -p 2222

Select *Administrator controls* then *Backup and Restore* then *Backup GPG key to USB (fragment keydrive)*.

Fragments are randomly assigned and so you will need at least three or four keydrives to have enough fragments to reconstruct your original key in a worst case scenario. You can store fragments for different Freedombone systems on the same encrypted USB drive, so you can help to ensure that your friends can also recover their systems. This might be called *"the web of backups"* or *"the web of encryption"*. Since you can only write a single key fragment from your Freedombone system to a given USB drive each friend doesn't have enough information to decrypt your backups or steal your identity, even if they turn evil. This is based on the assumption that it may be difficult to get three or more friends to conspire against you all at once.

Passwords
=========
Passwords for server applications are randomly generated and can be found within **/home/username/README** after the system has fully installed. You should move those passwords into a password manager, such as KeepassX.

Administering the system
========================
To administer the system after installation log in via ssh, become the root user and then launch the control panel.

    ssh fbone@freedombone.local -p 2222

Select *Administrator controls* and from there you will be able to perform various tasks, such as backups, adding and removing users and so on. You can also do this via commands, which are typically installed as /usr/local/bin/freedombone* and the corresponding manpages.
