# 下载 Ubuntu Noble Cloud 镜像并在 Windows 下的 VirtualBox 中导入

本文档将引导你如何下载 [noble-server-cloudimg-amd64.ova](https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.ova) 镜像，然后在 Windows 下使用 VirtualBox 导入该镜像，并配置用户名、密码、SSH 密钥以及网络参数等设置。

---

## 1. 下载镜像文件

1. 打开浏览器，访问以下链接：
   [https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.ova](https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.ova)
2. 下载 `.ova` 文件到你常用的目录（例如：`C:\Downloads`）。

---

## 2. 导入镜像到 VirtualBox

1. 启动 VirtualBox。
2. 点击菜单栏中的 `文件` -> `导入虚拟设备`。
3. 在弹出的对话框中：
   - 点击 `选择` 按钮，找到刚才下载的 `.ova` 文件（例如：`C:\Downloads\noble-server-cloudimg-amd64.ova`）。
   - 点击 `下一步`，系统将显示设备的配置信息。
   - 如有需要，可修改配置（例如内存、CPU 分配、网络方式等）。
   - 点击 `导入` 以完成镜像导入。

---

## 3. 启动虚拟机并设置基本参数

### 3.1 启动虚拟机

- 在 VirtualBox 主界面中选中刚导入的虚拟机，然后点击 `启动`。

### 3.2 初始账户设置

镜像导入后，可能需要设置账户及初始密码，具体操作如下：

- **默认用户名和密码：**  
  部分云镜像会预先配置默认的用户名和密码（如 `ubuntu` 用户）。你可以尝试使用默认账号登录。如果你想修改，请继续下述步骤。

- **修改用户名和密码：**  
  1. 登录到虚拟机后，打开终端。
  2. 如果想修改密码，请执行：
     ```bash
     passwd
     ```
  3. 按照提示输入当前和新密码。

- **创建新用户（可选）：**  
  如果需要创建一个新用户，可以执行：
  ```bash
  sudo adduser 新用户名
  sudo usermod -aG sudo 新用户名
  ```
  然后按照提示输入用户信息和密码。

---

## 4. 配置 SSH 密钥

为了安全起见，建议使用 SSH 密钥进行登录认证，操作步骤如下：

1. **在本地生成 SSH 密钥对（如果尚未创建）：**  
   在 Windows 下可以使用 Git Bash 或 PowerShell：
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/ubuntu_key
   ```
   根据提示操作，建议不要设置密码（或根据安全性启用）。

2. **将公钥复制到虚拟机：**  
   登录虚拟机后，执行以下命令：
   ```bash
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   nano ~/.ssh/authorized_keys
   ```
   然后将本地生成的 `ubuntu_key.pub` 内容复制粘贴到该文件内，保存后退出编辑器，再执行：
   ```bash
   chmod 600 ~/.ssh/authorized_keys
   ```
   这样就完成了 SSH 公钥认证设置。

3. **验证 SSH 登录：**  
   从本地终端尝试使用 SSH 链接虚拟机（确保虚拟机网络配置允许 SSH 连接）：
   ```bash
   ssh -i ~/.ssh/ubuntu_key 新用户名@虚拟机IP地址
   ```

---

## 5. 配置网络参数

在 VirtualBox 中，你可以通过如下步骤配置网络参数：

1. 在 VirtualBox 主界面中，右键点击虚拟机并选择 `设置`。
2. 在 `网络` 选项卡下，你可以选择以下几种模式之一：
   - **NAT：** 通常适用于外网访问，虚拟机可以访问 Internet，但外部无法直接访问虚拟机。
   - **桥接模式：** 虚拟机直接连接到宿主机所在的物理网络内，适合需要局域网环境通信的场景。
   - **仅主机模式：** 仅宿主机与虚拟机可互相通信，适合测试环境。
3. 根据实际需求选择网络模式，并调整高级设置（如端口转发）：
   - 若使用 NAT 模式，并且需要 SSH 外部访问，可设置端口转发：
     1. 点击 `高级` -> `端口转发`。
     2. 添加一条新规则，例如：宿主机端口 `2222` 映射到虚拟机端口 `22`。
     3. 保存设置后，可使用 `ssh -p 2222 ...` 连接虚拟机。

---

## 6. 总结

1. 先下载 `.ova` 镜像。
2. 使用 VirtualBox 导入镜像并启动虚拟机。
3. 配置默认或新建用户的登录密码。
4. 配置并验证 SSH 密钥认证。
5. 根据需要调整虚拟机的网络参数。

按照以上步骤，你就能在 Windows 下使用 VirtualBox 成功部署并配置 Ubuntu Noble Cloud 镜像。

如有任何问题，可查阅 VirtualBox 官方文档或 Ubuntu 社区论坛获取更多帮助。
