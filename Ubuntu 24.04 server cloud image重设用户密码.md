在Ubuntu系统中，进入recovery模式的步骤如下：

1. 重启你的电脑。在系统启动时，按住`Shift`键（在某些系统中可能是`Esc`键）以进入GRUB菜单。

2. 在GRUB菜单中，使用箭头键选择"Advanced options for Ubuntu"，然后按`Enter`键。

3. 在下一个菜单中，你会看到一系列的启动选项。选择带有"(recovery mode)"字样的选项，然后按`Enter`键。

4. 系统将会以recovery模式启动。在recovery菜单中，你可以选择不同的选项，例如"root Drop to root shell prompt"以获取root权限。


5. 在Ubuntu Server中，你可以使用`passwd`命令来修改当前用户的密码。然后还使用`adduser`命令来创建一个新的用户。以下是创建一个名为"hadoop"的用户的命令：

```bash
sudo adduser hadoop
```

运行这个命令后，系统会提示你输入新用户的密码，以及一些可选的用户信息（如全名、房间号、电话等）。如果你不想输入这些信息，可以直接按`Enter`键跳过。

注意，这个命令需要管理员权限，所以需要使用`sudo`。如果你当前的用户没有管理员权限，你可能需要先切换到一个有管理员权限的用户，或者直接使用root用户。

这样就实现了对 Ubuntu 24.04 server cloud image 重设用户名和密码。

在Ubuntu中，你可以将用户添加到`sudo`组来赋予他们`sudo`权限。以下是将用户`hadoop`添加到`sudo`组的命令：

```bash
sudo usermod -aG sudo hadoop
```

这个命令的含义是：

- `usermod`：修改用户的命令
- `-aG`：将用户添加到一个或多个组，而不影响他们在其他组的成员资格
- `sudo`：要添加的组的名称
- `hadoop`：要修改的用户的名称

注意，这个命令需要管理员权限，所以需要使用`sudo`。如果你当前的用户没有管理员权限，你可能需要先切换到一个有管理员权限的用户，或者直接使用root用户。

在Ubuntu Server 24.04中，你可以使用`ip`命令来显示所有的网卡，然后使用`netplan`来配置它们作为DHCP的客户端。

首先，使用以下命令来显示所有的网卡：

```bash
ip link show
```

然后，你需要创建一个`netplan`配置文件来设置这些网卡作为DHCP的客户端。以下是一个例子：

```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

在这个文件中，输入以下内容：

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      dhcp4: true
```

在这个例子中，`enp0s3`和`enp0s8`是网卡的名称，你需要将它们替换为你实际的网卡名称。

保存并关闭文件后，运行以下命令来应用新的配置：

```bash
sudo netplan apply
```

注意，这个命令需要管理员权限，所以需要使用`sudo`。如果你当前的用户没有管理员权限，你可能需要先切换到一个有管理员权限的用户，或者直接使用root用户。