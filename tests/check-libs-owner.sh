#!/bin/bash

if [ -d "/lib" ];then

    COUNT=$(find -L /lib  \! -user root  -exec ls -l {} \; | grep -v '> /dev/null' | wc -l)

    if [ $COUNT -eq 0 ];then
        :
    else
        find -L /lib  \! -user root  -exec ls -l {} \; | grep -v '> /dev/null'
        exit 1
    fi
fi
if [ -d "/lib64" ];then

    COUNT=$(find -L /lib64  \! -user root  -exec ls -l {} \; |wc -l)

    if [ $COUNT -eq 0 ];then
        :
    else
        find -L /lib64  \! -user root  -exec ls -l {} \;
        exit 1
    fi
fi
if [ -d "/usr/lib" ];then

    COUNT=$(find -L /usr/lib  \! -user root  -exec ls -l {} \; |wc -l)

    if [ $COUNT -eq 0 ];then
        :
    else
        find -L /usr/lib  \! -user root  -exec ls -l {} \;
        exit 1
    fi
fi
if [ -d "/usr/lib64" ];then

    COUNT=$(find -L /usr/lib64  \! -user root  -exec ls -l {} \; |wc -l)

    if [ $COUNT -eq 0 ];then
        :
    else
        find -L /usr/lib64  \! -user root  -exec ls -l {} \;
        exit 1
    fi
fi
