# Ubuntu 24.04 命令行设置代理服务器

要在 Ubuntu 24.04 的命令行中设置代理服务器为 `192.168.0.25:7890`，你可以使用以下几种方法：

## 临时设置（当前会话有效）

```bash
export http_proxy=http://192.168.0.25:7890
export https_proxy=http://192.168.0.25:7890
export all_proxy=socks5://192.168.0.25:7890
```

## 永久设置（对当前用户）

将代理设置添加到用户的 `.bashrc` 或 `.profile` 文件中：

```bash
echo 'export http_proxy=http://192.168.0.25:7890' >> ~/.bashrc
echo 'export https_proxy=http://192.168.0.25:7890' >> ~/.bashrc
echo 'export all_proxy=socks5://192.168.0.25:7890' >> ~/.bashrc
source ~/.bashrc
```

## 特定命令使用代理

如果只想让特定命令使用代理：

```bash
http_proxy=http://192.168.0.25:7890 https_proxy=http://192.168.0.25:7890 命令
```

例如：

```bash
http_proxy=http://192.168.0.25:7890 https_proxy=http://192.168.0.25:7890 apt update
```

## 验证代理设置

验证代理是否生效：

```bash
curl -I https://www.google.com
```

如果返回 HTTP 状态码而不是连接错误，则代理已成功设置。


export http_proxy=http://192.168.155.151:7890
export https_proxy=http://192.168.155.151:7890
export all_proxy=socks5://192.168.155.151:7890

export http_proxy=http://192.168.31.178:7890
export https_proxy=http://192.168.31.178:7890
export all_proxy=socks5://192.168.31.178:7890