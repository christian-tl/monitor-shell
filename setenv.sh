#!/bin/bash

MAIL_TO="tianle@dangdang.com zhanghaihua@dangdang.com yanlei@dangdang.com wangningjs@dangdang.com"

MAIL_LIST=${MAIL_TO//\ /,}
MAIL_SERVICE_URL="http://192.168.89.20:8998/alarm/email?m=${MAIL_LIST}&s="

REDIS_CLIENT_CMD=/usr/local/redis-2.8.13/src/redis-cli

#log dir
if [ ! -e /d1/check/logs ]; then
   mkdir -p /d1/check/logs
fi
LOG_PATH=/d1/check/logs

#text color
txtund=$(tput sgr 0 1)          # Underline
txtbld=$(tput bold)             # Bold
red=$(tput setaf 1)             # red
green=$(tput setaf 2)           # green
blue=$(tput setaf 4)            # blue
white=$(tput setaf 7)           # white
bldred=${txtbld}$(tput setaf 1) # bold red
bldgre=${txtbld}$(tput setaf 2) # bold green
bldblu=${txtbld}$(tput setaf 4) # bold blue
bldwht=${txtbld}$(tput setaf 7) # blod white
reset=$(tput sgr0)              # Reset

