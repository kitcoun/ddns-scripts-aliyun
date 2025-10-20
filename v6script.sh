#!/bin/ash
INTERF=br-lan
SUFFIX="30:9c:23:68:db:28"
ip -6 neigh show dev br-lan | grep -i "$SUFFIX" | awk '/^2409:[0-9a-f]+:/ {print $1}' | head -1
