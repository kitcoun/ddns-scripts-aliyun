# ddns-scripts-aliyun

ddns-scripts-aliyun是OpenWrt软件包ddns-scripts的扩展, 实现阿里云域名的动态DNS解析。

从官方而来，修复了签名问题

## 使用前提

在使用该脚本之前，需要满足以下前提

- 请确保拥有公网IPv4或IPv6地址，不确定可以[点击这里](http://www.test-ipv6.com/)进行检查。
- 在阿里云拥有一个域名，并在阿里云后台配置了相应的A或AAAA记录。详见[配置使用](#配置使用)
- 已申请好阿里云的AccessKey，推荐使用子账户进行配置
- 为子账户配置了`AliyunDNSReadOnlyAccess`和`AliyunDNSFullAccess`的权限策略

## 安装

- 手动安装
```sh
cd /usr/lib/ddns
rm /usr/lib/ddns/update_aliyun_com.sh
vim /usr/lib/ddns/update_aliyun_com.sh
# 按 "I" 键
# 复制本项目的update_aliyun_com.sh代码到其中
# 按 "esc" 键
# 输入 ":wq "
# 按回车键
```

## 配置使用

下面以主域名`example.com`为例，介绍如何配置使用：

由于ddns-scripts暂时无法自动创建域名解析记录，所以使用之前，需要先在阿里云DNS控制台配置一条解析记录：

- 记录类型：如果配置IPv4解析记录，选择A，如果配置IPv6，则选择AAAA
- 主机记录：如果想直接解析主域名`example.com`，则填写`@`；如果想配置子域名解析记录，如`host.example.com`，则填写`host`,
- 记录值：可随意填写，只要符合IP地址格式即可，之后DDNS服务启动后会被修改掉。

**注意：对同一域名的同一记录类型可以配置多条记录，但是这里只推荐配置一条。如果检测到了多条记录，脚本只会使用第一条。**

进入LuCI后台，选择「服务」>「动态DNS」，选择「添加新服务」或直接编辑原有的服务：

- 主机名填写要进行动态DNS的域名，如`example.com`、`host.example.com`
- DNS提供商选择`aliyun.com`，并切换服务
- 填写域名，以`host@yourdomain.LTD`格式进行填写：
    - 如果为主域名`example.com`配置，则填写`@example.com`，注意前面有`@`
    - 如果为子域名配置，如`host.example.com`, 则填写`host@example.com`
    - 对一些多级域名如`host.example.com.cn`, 请确保`@`后为你购买的主域名，如`host@example.com.cn`、`@example.com.cn`
- 用户名填写阿里云AccessKey ID，密码填写AccessKey Secret

其他一些配置依据自己的需求配置即可，配置完保存并应用，过一会后即可在阿里云DNS控制台看到已更新的记录值。

来源:https://github.com/openwrt/packages/blob/master/net/ddns-scripts/files/usr/lib/ddns/update_aliyun_com.sh
签名:https://help.aliyun.com/zh/sdk/product-overview/v3-request-structure-and-signature?spm=a2c4g.11186623.help-menu-262060.d_0_4_2.63da3261HlgOyd