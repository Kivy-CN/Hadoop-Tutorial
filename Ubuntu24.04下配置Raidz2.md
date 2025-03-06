# 在 Ubuntu 24.04 中创建 RAIDZ2 (ZFS RAID6 等效)

接下来介绍如何在 Ubuntu 24.04 上安装和配置 RAIDZ2，这是 ZFS 的一种 RAID 配置，类似于标准 RAID6，提供双重奇偶校验保护：

## 安装 ZFS

首先安装 ZFS 文件系统支持：

```bash
sudo apt update
sudo apt install zfsutils-linux -y
```

## 创建 RAIDZ2

RAIDZ2 至少需要 4 个硬盘，假设我们有 `/dev/sdf`、`/dev/sdg`、`/dev/sdh` 和 `/dev/sdi` 四个磁盘：

1. 确认可用磁盘：

```bash
sudo fdisk -l
```

2. 清除磁盘分区表（如有必要）：

```bash
sudo dd if=/dev/zero of=/dev/sdf bs=512 count=1
sudo dd if=/dev/zero of=/dev/sdg bs=512 count=1
sudo dd if=/dev/zero of=/dev/sdh bs=512 count=1
sudo dd if=/dev/zero of=/dev/sdi bs=512 count=1
```

3. 创建 RAIDZ2 存储池：

```bash
sudo zpool create -f storage raidz2 /dev/sdf /dev/sdg /dev/sdh /dev/sdi
```

4. 在存储池上创建 ZFS 文件系统：

```bash
sudo zfs create storage/data
```

5. 设置挂载点（默认挂载在 `/storage/data`）：

```bash
sudo zfs set mountpoint=/mnt/raidz2 storage/data
```

## 配置 ZFS 属性

设置一些常用属性：

```bash
# 启用数据压缩
sudo zfs set compression=lz4 storage/data

# 启用数据重复删除（可选，消耗大量内存）
# sudo zfs set dedup=on storage/data

# 设置安全权限
sudo zfs set atime=off storage/data
sudo chown hadoop:hadoop /mnt/raidz2
```

## 检查 ZFS 状态

```bash
# 查看存储池状态
sudo zpool status storage

# 查看存储池详细信息
sudo zpool list

# 查看文件系统信息
sudo zfs list

# 查看 I/O 性能统计
sudo zpool iostat -v storage
```

## 配置定期清理（Scrub）

设置每周自动检查存储池数据完整性：

```bash
sudo bash -c 'echo "0 0 * * 0 root /usr/sbin/zpool scrub storage" >> /etc/crontab'
```

## 出现故障时的恢复

如果有磁盘故障，可以使用以下命令替换故障磁盘（假设 `/dev/sdg` 故障）：

```bash
# 添加新磁盘（假设新磁盘为 /dev/sdj）
sudo zpool replace storage /dev/sdg /dev/sdj

# 检查恢复状态
sudo zpool status storage
```

## 导入/导出 ZFS 池

```bash
# 导出池（卸载）
sudo zpool export storage

# 导入池（挂载）
sudo zpool import storage
```

这种 RAIDZ2 配置提供了比 RAID1 更高的存储效率和比 RAID0 更好的数据保护，能够在不丢失数据的情况下承受两个磁盘同时故障。