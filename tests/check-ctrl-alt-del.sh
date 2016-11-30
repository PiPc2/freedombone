#!/bin/bash

if [ -f /etc/systemd/system/ctrl-alt-del.target ];then
    ctrl_alt_del=$(ls -l /etc/systemd/system/ctrl-alt-del.target)
    if [[ "$ctrl_alt_del" !=  *"/dev/null" ]]; then
        exit 1
    fi
else
    exit 1
fi
