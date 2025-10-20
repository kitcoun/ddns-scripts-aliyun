#!/bin/ash
INTERF=br-lan
SUFFIX="6dcb:1863:2bd1:b28f"
ip -6 neigh show dev $INTERF | grep "2409.*$SUFFIX" | awk '{print $1}'