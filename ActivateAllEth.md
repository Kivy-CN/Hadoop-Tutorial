下面提供一种思路，利用 Bash 脚本和 Linux 的 ip 命令自动检测系统中所有非回环网卡的基本配置信息，之后可以根据这些信息生成或修改 netplan（或其他）配置文件。例如，可以创建一个 Bash 脚本，遍历 /sys/class/net 下的网卡（过滤掉 lo），然后调用 ip 命令提取详细信息:

```bash
#!/bin/bash
# filepath: /C:/Users/HP/Documents/GitHub/Hadoop-Tutorial/ActivateAllEth.md
# 脚本作用:自动检测所有非回环网卡的名称、IP地址和状态

echo "检测并显示所有非回环网卡的配置:"
for iface in $(ls /sys/class/net | grep -v lo); do
    echo "网卡: $iface"
    ip addr show "$iface" | awk '/inet / {print "  IP地址: " $2}'
    ip link show "$iface" | awk '/state/ {print "  状态: " $9}'
    echo "--------------------------"
done
```

【说明】  
1. 该脚本会列出所有非回环网卡，并显示对应的 IP 地址和状态。  
2. 如果你的系统中 host-only 网卡没有正确显示，可能需要检查该接口是否被正确识别（例如，虚拟机软件设置、驱动等），或者是否已激活。  
3. 针对 Ubuntu Server 24.04，可以考虑通过 netplan 自动配置所有检测到的接口。例如，利用 YAML 模板结合 for 循环动态生成功能，目前 netplan 本身不支持循环配置接口，但你可以在部署前通过脚本生成包含所有接口定义的 YAML 文件，然后将其放入 /etc/netplan 下并执行 sudo netplan apply 来生效。  

这种方法能够保证在系统启动或网络配置变更时动态获取系统中所有网卡的状态和配置，从而便于后续加载正确的网络设置。


下面提供一个更简短的方式，只需手工输入几条命令即可:

1. 显示所有非回环网卡的名字（手动确认所有网卡是否被识别）:
```bash
for iface in $(ls /sys/class/net | grep -v lo); do echo "$iface"; done
```

2. 确认每个网卡的详细信息:
```bash
ip addr show
```

如果发现有网卡没出现在列表中，请检查虚拟机设置和驱动配置。手动编辑 netplan 配置文件（通常在 /etc/netplan 下），确保所有网卡都有对应条目，然后运行:
```bash
sudo netplan apply
```

这样系统就能识别并利用所有现有网卡。

88:00:27:67:4f:53