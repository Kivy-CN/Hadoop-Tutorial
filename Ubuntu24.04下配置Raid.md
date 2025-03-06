# Ubuntu 24.04 中创建 RAID 0 和 RAID 1 的简易指南

在 VirtualBox 虚拟机下为已安装的 Ubuntu 24.04 系统创建 RAID 阵列的步骤如下：

## 准备工作

首先，为虚拟机添加额外的虚拟硬盘：

1. 关闭虚拟机
2. 在 VirtualBox 管理器中，选择虚拟机 → 设置 → 存储
3. 在存储控制器下点击"添加硬盘"按钮
4. 选择"创建新磁盘"，创建至少 2 个相同大小的虚拟硬盘（如每个 2TB）
5. 启动虚拟机

## 安装必要软件

```bash
sudo apt update
sudo apt install mdadm -y
```

## 创建 RAID 0（条带化）

1. 确认新添加的磁盘：

```bash
sudo fdisk -l
```

假设新磁盘为 `/dev/sdb` 和 `/dev/sdc`

2. 创建 RAID 0：

```bash
sudo mdadm --create --verbose /dev/md0 --level=0 --raid-devices=2 /dev/sdb /dev/sdc
```

3. 格式化阵列：

```bash
sudo mkfs.ext4 /dev/md0
```

4. 创建挂载点并挂载：

```bash
sudo mkdir -p /mnt/raid0
sudo mount /dev/md0 /mnt/raid0
```

5. 配置开机自动挂载：

```bash
sudo bash -c 'echo "/dev/md0 /mnt/raid0 ext4 defaults 0 0" >> /etc/fstab'
```

6. 保存 RAID 配置：

```bash
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
sudo update-initramfs -u
```

## 创建 RAID 1（镜像）

假设有另外两个磁盘 `/dev/sdd` 和 `/dev/sde`：

1. 创建 RAID 1：

```bash
sudo mdadm --create --verbose /dev/md1 --level=1 --raid-devices=2 /dev/sdd /dev/sde
```

2. 格式化阵列：

```bash
sudo mkfs.ext4 /dev/md1
```

3. 创建挂载点并挂载：

```bash
sudo mkdir -p /mnt/raid1
sudo mount /dev/md1 /mnt/raid1
```

4. 配置开机自动挂载：

```bash
sudo bash -c 'echo "/dev/md1 /mnt/raid1 ext4 defaults 0 0" >> /etc/fstab'
```

5. 保存 RAID 配置：

```bash
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
sudo update-initramfs -u
```

## 检查 RAID 状态

```bash
cat /proc/mdstat
sudo mdadm --detail /dev/md0
sudo mdadm --detail /dev/md1
```

注意：以上步骤假设添加的是全新未使用的磁盘。如果磁盘已有数据或分区，需要先清除分区表：

```bash
sudo dd if=/dev/zero of=/dev/sdb bs=512 count=1
sudo dd if=/dev/zero of=/dev/sdc bs=512 count=1
```

