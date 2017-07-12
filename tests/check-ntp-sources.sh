#!/bin/bash

if [ -f /etc/ntp.conf ];then
        if ! sed -e '/^#/d' -e '/^[ \t][ \t]*#/d' -e 's/#.*$//' -e '/^$/d' /etc/ntp.conf | grep pool;then
                exit 1
        fi
else
        exit 1
fi
