来源:https://github.com/openwrt/packages/blob/master/net/ddns-scripts/files/usr/lib/ddns/update_aliyun_com.sh

通过BusyBox执行的sh脚本
测试脚本语法
```
sh -n /usr/lib/ddns/update_aliyun_com.sh
```

本设备设置：
高级设置 → IP 地址来源:接口 → 接口：wan

下级设备设置
在v6script.sh设置设备的MAC地址(SUFFIX),MAC地址可以在首页查看
高级设置 → IP 地址来源:脚本 → 填写脚本位置(v6script.sh)