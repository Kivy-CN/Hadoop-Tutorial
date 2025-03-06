# 通过 winget 安装 WSL2 和 Ubuntu 24.04

你可以使用 PowerShell 通过 winget 命令来安装 WSL2 和 Ubuntu 24.04。以下是完整的步骤：

1. 首先安装 WSL2：

```powershell
winget install Microsoft.WSL
```

2. 安装 Ubuntu 24.04：

```powershell
winget install Canonical.Ubuntu.2404
```

3. 重启你的计算机以确保 WSL 正确启用。

4. 启动 Ubuntu 24.04（可以从开始菜单找到），首次启动时会要求你创建用户名和密码。

如果你需要验证安装和检查版本，可以使用以下命令：

```powershell
wsl --list --verbose
```

这将显示已安装的 Linux 发行版及其使用的 WSL 版本。

如果想将 Ubuntu 24.04 设为默认发行版：

```powershell
wsl --set-default Ubuntu-24.04
```