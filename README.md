# OpenWRT 官方 DDNS 阿里云 配置指南

## 适用场景

本指南适用于基于 OpenWRT 系统，通过 `ddns-scripts` 组件结合阿里云 DNS API 实现动态 DNS 解析的场景，支持 IPv6 地址自动更新。

测试版本动态 DNS 版本
2.8.2-r64

## 环境准备

### 基础组件

确保已安装以下组件：
- `ddns-scripts`：DDNS 核心组件
- `ddns-scripts-aliyun`：阿里云 DNS 专用脚本

### 脚本路径

阿里云 DNS 更新脚本路径：
```
/usr/lib/ddns/update_aliyun_com.sh
```

**来源**：[openwrt/packages](https://github.com/openwrt/packages/blob/master/net/ddns-scripts/files/usr/lib/ddns/update_aliyun_com.sh)

### 脚本语法验证

执行以下命令检查脚本语法正确性：

```bash
sh -n /usr/lib/ddns/update_aliyun_com.sh
```

- **无输出**：表示语法正常
- **有错误提示**：请检查脚本完整性或重新安装组件

## 设备配置

### 1. 上级设备（主路由）设置

#### 通过ui设置(可能有问题)
1. 进入 **DDNS 高级设置**
2. **IP 地址来源**：选择 `接口`
3. **接口**：选择 `wan`（根据实际 WAN 口名称调整）

### 2. 通过脚本
#### 步骤 1：创建 IPv6 地址获取脚本

在下级设备中创建脚本 `wanv6script.sh`（建议路径：`/usr/lib/ddns/wanv6script.sh`）
```bash
#!/bin/sh

# 指定接口，比如wan
INTERFACE="wan"
ip -6 addr show dev $INTERFACE scope global | grep -oE '2409:[0-9a-f:]+' | head -n 1
```

赋予执行权限：

```bash
chmod +x /usr/lib/ddns/wanv6script.sh
```

### 2. 下级设备设置

#### 步骤 1：创建 IPv6 地址获取脚本

在下级设备中创建脚本 `lanv6script.sh`（建议路径：`/usr/lib/ddns/lanv6script.sh`）

```bash
#!/bin/sh
# 替换为下级设备的 MAC 地址（从设备首页查看）
SUFFIX="30:9c:23:68:db:28"
# 从 br-lan 接口的邻居列表中提取匹配的 IPv6 地址
ip -6 neigh show dev br-lan | grep -i "$SUFFIX" | awk '/^2409:[0-9a-f]+:/ {print $1}' | head -1
```

赋予执行权限：

```bash
chmod +x /usr/lib/ddns/lanv6script.sh
```

#### 步骤 2：配置 DDNS 高级设置

1. 进入 **DDNS 高级设置**
2. **IP 地址来源**：选择 `脚本`
3. **脚本位置**：填写上述脚本路径（例如 `/etc/ddns/v6script.sh`）
3. **接口**：选择 `lan`（根据实际 lan 口名称调整）

## 参考资料

- [Per-Device DDNS 配置教程](https://blog.shinoaa.com/2024/08/20/perDDNS/)
- [OpenWRT ddns-scripts 官方文档](https://openwrt.org/docs/guide-user/services/ddns/client)

## 注意事项

1. 确保阿里云 DNS 解析记录已正确创建
2. 检查网络接口名称是否与实际环境匹配
3. 验证脚本执行权限和路径正确性
4. 确保设备能够正常访问阿里云 API
