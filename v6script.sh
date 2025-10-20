#!/bin/ash
INTERF=br-lan
SUFFIX="30:9c:23:68:db:28"
ip -6 addr show dev $INTERF | awk '/inet6/ && !/fe80::|deprecated/ {print $2}' | cut -d':' -f1-4 | sed "s/$/:$SUFFIX/"
