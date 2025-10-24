#!/bin/sh
# interface and MAC suffix to match (尾部MAC地址，可按需修改)
INTERF=br-lan
SUFFIX="30:9c:23:68:db:28"
# 重试间隔设置
IP_Desired="60" # 有IP
NO_IP_Desired="1800" # 无IP

# 缓存文件：当目标设备离线时返回上次有效IP，避免 ddns-scripts 连续报错
CACHE="/tmp/lanv6_ip_cache"

# 获取当前邻居IP（只有 REACHABLE 或 STALE 被认为在线）
get_ip() {
	ip -6 neigh show dev "$INTERF" | grep -i "$SUFFIX" | awk '/REACHABLE|STALE/ {print $1}' | grep -v '::' | head -1
}

# 设置 retry_interval 的方法：
# - 没有缓存时（设备可能离线）将间隔设为 600秒
# - 存在缓存时将间隔设为 1800秒
set_retry_interval() {
	local desired current changed=0
	if [ -s "$CACHE" ]; then
		desired=$IP_Desired
	else
		desired=$NO_IP_Desired
	fi

	current=$(uci get ddns.lan1_ipv6.retry_interval 2>/dev/null || echo "")
	if [ "$current" != "$desired" ]; then
		uci set ddns.lan1_ipv6.retry_interval="$desired" && changed=1
	fi

	if [ "$changed" -eq 1 ]; then
		uci commit ddns
	fi
}

# 1) 先尝试立即获取
cur_ip=$(get_ip)
if [ -n "$cur_ip" ]; then
	echo "$cur_ip"
	echo "$cur_ip" > "$CACHE" 2>/dev/null || true
	exit 0
fi

# 2) 如果没有当前IP，但有缓存，返回缓存（避免 ddns-scripts 将其视为脚本失败并不停重试）
if [ -s "$CACHE" ]; then
	cat "$CACHE"
	exit 0
fi

# 3) 没有缓存。
# 调用方法，根据缓存设置 retry_interval（无缓存=600，有缓存=60）
set_retry_interval

# 若因某些原因仍未获取到IP，则安全退出（不打印错误），让 ddns-scripts 处理边界情况。
exit 0
