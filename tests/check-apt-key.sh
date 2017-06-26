#!/bin/bash
#Verify with the key fatch from https://ftp-master.debian.org/keys.html

#---------------------------------------------------------------------------
#"Debian Archive Automatic Signing Key (9/stretch) <ftpmaster@debian.org>"

STRETCHARCHIVEKEY=" E1CF 20DD FFE4 B89E 8026  58F1 E0B1 1894 F66A EC98"
CHECKTMP=$(apt-key finger | grep -B 1 "Debian Archive Automatic Signing Key (9/stretch) <ftpmaster@debian.org>" | head -n1 | awk -F '=' '{printf $2}')

if [ "$CHECKTMP" == "$STRETCHARCHIVEKEY" ];then
       echo Good
       :
else
       echo bad
       exit 1
fi

#---------------------------------------------------------------------------
#"Debian Security Archive Automatic Signing Key (9/stretch) <ftpmaster@debian.org>"

STRETCHSECURITYKEY=" 6ED6 F5CB 5FA6 FB2F 460A  E88E EDA0 D238 8AE2 2BA9"
CHECKTMP=$(apt-key finger | grep -B 1 "Debian Security Archive Automatic Signing Key (9/stretch) <ftpmaster@debian.org>" | head -n1 | awk -F '=' '{printf $2}')

if [ "$CHECKTMP" == "$STRETCHSECURITYKEY" ];then
       echo Good
       :
else
       echo bad
       exit 1
fi

#---------------------------------------------------------------------------
#"Debian Stable Release Key (9/stretch) <debian-release@lists.debian.org>"

STRETCHSTABLEKEY=" 067E 3C45 6BAE 240A CEE8  8F6F EF0F 382A 1A7B 6500"
CHECKTMP=$(apt-key finger | grep -B 1 "Debian Stable Release Key (9/stretch) <debian-release@lists.debian.org>" | head -n1 | awk -F '=' '{printf $2}')

if [ "$CHECKTMP" == "$STRETCHSTABLEKEY" ];then
       echo Good
       :
else
       echo bad
       exit 1
fi

#---------------------------------------------------------------------------
#"Debian Archive Automatic Signing Key (8/jessie) <ftpmaster@debian.org>"

JESSIEARCHIVEKEY=" 126C 0D24 BD8A 2942 CC7D  F8AC 7638 D044 2B90 D010"
CHECKTMP=$(apt-key finger | grep -B 1 "Debian Archive Automatic Signing Key (8/jessie) <ftpmaster@debian.org>" | head -n1 | awk -F '=' '{printf $2}')

if [ "$CHECKTMP" == "$JESSIEARCHIVEKEY" ];then
       echo Good
       :
else
       echo bad
       exit 1
fi

#---------------------------------------------------------------------------
#"Debian Security Archive Automatic Signing Key (8/jessie) <ftpmaster@debian.org>"

JESSIESECURITYKEY=" D211 6914 1CEC D440 F2EB  8DDA 9D6D 8F6B C857 C906"
CHECKTMP=$(apt-key finger | grep -B 1 "Debian Security Archive Automatic Signing Key (8/jessie) <ftpmaster@debian.org>" | head -n1 | awk -F '=' '{printf $2}')

if [ "$CHECKTMP" == "$JESSIESECURITYKEY" ];then
       echo Good
       :
else
       echo bad
       exit 1
fi

#---------------------------------------------------------------------------
#"Jessie Stable Release Key <debian-release@lists.debian.org>"

JESSIESTABLEKEY=" 75DD C3C4 A499 F1A1 8CB5  F3C8 CBF8 D6FD 518E 17E1"
CHECKTMP=$(apt-key finger | grep -B 1 "Jessie Stable Release Key <debian-release@lists.debian.org>" | head -n1 | awk -F '=' '{printf $2}')

if [ "$CHECKTMP" == "$JESSIESTABLEKEY" ];then
       echo Good
       :
else
       echo bad
       exit 1
fi

#---------------------------------------------------------------------------
#"Debian Archive Automatic Signing Key (7.0/wheezy) <ftpmaster@debian.org>"

WHEEZYARCHIVEKEY=" A1BD 8E9D 78F7 FE5C 3E65  D8AF 8B48 AD62 4692 5553"
CHECKTMP=$(apt-key finger | grep -B 1 "Debian Archive Automatic Signing Key (7.0/wheezy) <ftpmaster@debian.org>" | head -n1 | awk -F '=' '{printf $2}')

if [ "$CHECKTMP" == "$WHEEZYARCHIVEKEY" ];then
       echo Good
       :
else
       echo bad
       exit 1
fi

#---------------------------------------------------------------------------
#"Wheezy Stable Release Key <debian-release@lists.debian.org>"

WHEEZYSTABLEKEY=" ED6D 6527 1AAC F0FF 15D1  2303 6FB2 A1C2 65FF B764"
CHECKTMP=$(apt-key finger | grep -B 1 "Wheezy Stable Release Key <debian-release@lists.debian.org>" | head -n1 | awk -F '=' '{printf $2}')

if [ "$CHECKTMP" == "$WHEEZYSTABLEKEY" ];then
       echo Good
       :
else
       echo bad
       exit 1
fi
