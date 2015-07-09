#!/bin/bash

APP=freedombone
PREV_VERSION=1.00
VERSION=1.01
ARCH_TYPE="all"
DIR=${APP}-${VERSION}

#update version numbers automatically - so you don't have to
sed -i 's/VERSION='${PREV_VERSION}'/VERSION='${VERSION}'/g' Makefile
sed -i 's/VERSION="'${PREV_VERSION}'"/VERSION="'${VERSION}'"/g' src/freedombone
sed -i 's/VERSION="'${PREV_VERSION}'"/VERSION="'${VERSION}'"/g' src/freedombone-prep
sed -i 's/VERSION="'${PREV_VERSION}'"/VERSION="'${VERSION}'"/g' src/freedombone-client

# change the parent directory name to debian format
cp releases/* ..
mv releases /tmp/freedombone
mv ../${APP} ../${DIR}
mkdir /tmp/freedombone

# Create a source archive
make clean
make source

# Build the package
dpkg-buildpackage -F
if [ ! "$?" = "0" ]; then
    mv ../${DIR} ../${APP}
    mv /tmp/freedombone/releases .
    exit 478
fi

# sign files
gpg -ba ../${APP}_${VERSION}-1_${ARCH_TYPE}.deb
if [ ! "$?" = "0" ]; then
    mv ../${DIR} ../${APP}
    mv /tmp/freedombone/releases .
    exit 639
fi

gpg -ba ../${APP}_${VERSION}.orig.tar.gz
if [ ! "$?" = "0" ]; then
    mv ../${DIR} ../${APP}
    mv /tmp/freedombone/releases .
    exit 592
fi

# restore the parent directory name
mv ../${DIR} ../${APP}
mv /tmp/freedombone/releases .

exit 0
