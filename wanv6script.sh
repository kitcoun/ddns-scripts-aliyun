#!/bin/sh

# 指定接口，比如wan
INTERFACE="wan"
# ip -6 addr show dev $INTERFACE scope global | grep -oE '2409:[0-9a-f:]+' | head -n 1
ifstatus wan6 | jsonfilter -e '@["ipv6-address"][*]["address"]' | grep -E '^2[0-9a-f][0-9a-f]?[0-9a-f]?' | grep -v '::'
