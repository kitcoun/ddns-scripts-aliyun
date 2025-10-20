#!/bin/ash
INTERF=br-lan
SUFFIX="30:9c:23:68:db:28"
ip -6 neigh show dev $INTERF | grep "2409.*$SUFFIX" | awk '{print $1}'