#!/bin/bash

APP=freedombone
PREV_VERSION=1.00
VERSION=1.00
ARCH_TYPE="all"
DIR=${APP}-${VERSION}

#update version numbers automatically - so you don't have to
sed -i 's/VERSION='${PREV_VERSION}'/VERSION='${VERSION}'/g' Makefile
sed -i 's/VERSION="'${PREV_VERSION}'"/VERSION="'${VERSION}'"/g' src/freedombone
sed -i 's/VERSION="'${PREV_VERSION}'"/VERSION="'${VERSION}'"/g' src/freedombone-prep
sed -i 's/VERSION="'${PREV_VERSION}'"/VERSION="'${VERSION}'"/g' src/freedombone-client

# change the parent directory name to debian format
mv ../${APP} ../${DIR}

# Create a source archive
make clean
make source

# Build the package
dpkg-buildpackage -F

# sign files
gpg -ba ../${APP}_${VERSION}-1_${ARCH_TYPE}.deb
gpg -ba ../${APP}_${VERSION}.orig.tar.gz

# restore the parent directory name
mv ../${DIR} ../${APP}
