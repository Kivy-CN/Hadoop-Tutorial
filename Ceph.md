# Ubuntu Server 24.04 上的 Ceph 集群部署指南

## 前提条件
- 最少3台 Ubuntu Server 24.04 节点（在同一网络中）
- 每个节点配置要求：
  - 内存：至少 8GB
  - CPU：至少 2核
  - 存储空间：最少 50GB
  - 已配置静态 IP 地址
  - 互联网连接（用于下载软件包）

## 1. 初始环境配置（所有节点）

### 1.1 系统更新
```bash
sudo apt update
sudo apt upgrade -y
```

### 1.2 配置主机名
在每个节点上编辑 `/etc/hosts`：
```bash
sudo nano /etc/hosts

# 添加所有节点信息
192.168.56.100 ceph-admin
192.168.56.101 ceph-mon1
192.168.56.102 ceph-osd1
```

### 1.3 安装必要软件包
```bash
sudo apt install -y python3 chrony curl
```

## 2. 在管理节点安装 cephadm

### 2.1 添加 Ceph 仓库
```bash
curl --silent https://download.ceph.com/keys/release.asc | sudo apt-key add -
sudo add-apt-repository 'deb https://download.ceph.com/debian-18.0 jammy main'
```

### 2.2 安装 cephadm
```bash
sudo apt update
sudo apt install -y cephadm
```

### 2.3 引导 Ceph 集群
```bash
sudo cephadm bootstrap --mon-ip 192.168.56.100
```

### 2.4 安装 Ceph 命令行工具
```bash
sudo apt install -y ceph-common
```

## 3. 添加其他节点

### 3.1 复制 SSH 密钥到其他节点
```bash
# 在管理节点执行
sudo ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph-mon1
sudo ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph-osd1
```

### 3.2 添加主机到集群
```bash
sudo ceph orch host add ceph-mon1
sudo ceph orch host add ceph-osd1
```

### 3.3 部署监控服务
```bash
sudo ceph orch apply mon ceph-mon1
```

### 3.4 添加 OSD（存储节点）
```bash
sudo ceph orch daemon add osd ceph-osd1:/dev/sdb
```

## 4. 验证集群状态

### 4.1 检查集群健康状态
```bash
sudo ceph -s
```

### 4.2 查看 OSD 状态
```bash
sudo ceph osd tree
```

## 5. 存储池配置

### 5.1 创建存储池
```bash
sudo ceph osd pool create mypool 32
```

### 5.2 设置副本数
```bash
sudo ceph osd pool set mypool size 2
```

## 6. 故障排除

### 6.1 常用命令
```bash
# 检查集群健康状态
sudo ceph health

# 查看详细健康信息
sudo ceph health detail

# 检查服务状态
sudo ceph orch ls
```

### 6.2 日志位置
- Ceph 日志：`/var/log/ceph/`
- 监控服务日志：`/var/log/ceph/ceph-mon.*.log`
- OSD 日志：`/var/log/ceph/ceph-osd.*.log`

## 安全建议
1. 使用强密码
2. 配置防火墙规则
3. 及时更新系统
4. 使用独立网络进行集群通信

## 日常维护
- 定期监控集群健康状态
- 定期更新 Ceph 软件
- 定期备份重要数据
- 监控磁盘使用率和性能

## 补充资源
- Ceph 官方文档：https://docs.ceph.com/
- Ceph 中文社区：https://ceph.org.cn/
- Ceph 问题排查指南