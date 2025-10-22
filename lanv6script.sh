#!/bin/ash
INTERF=br-lan
SUFFIX="30:9c:23:68:db:28"
# 只获取状态为REACHABLE或STALE的邻居（表示设备在线）
ip -6 neigh show dev br-lan | grep -i "$SUFFIX" | awk '/^2409:[0-9a-f]+:/ && /REACHABLE|STALE/ {print $1}' | grep -v '::' |  head -1
