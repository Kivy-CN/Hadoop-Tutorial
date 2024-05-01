# Docker 和 Docker Compose 的安装

在Ubuntu 24.04上直接安装Docker和Docker Compose的步骤如下：

1. 更新现有的包列表：
```bash
sudo apt-get update
```

2. 添加源：
```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

3. 安装：
```bash
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

4. 验证Docker是否成功安装：
```bash
sudo docker --version
sudo docker run hello-world
```

5. 安装Docker Compose：
```bash
sudo apt-get update
sudo apt-get install docker-compose-plugin
```

6. 验证Docker Compose是否成功安装：
```bash
sudo docker compose --version
```

以上命令应该显示Docker和Docker Compose的版本信息，表示它们已经成功安装。


# Docker 源配置

要将Docker默认的镜像源更改为阿里云或TUNA，你需要修改Docker的daemon配置文件。以下是步骤：

1. 创建或修改Docker的daemon配置文件。这个文件通常位于`/etc/docker/daemon.json`。如果文件不存在，你需要创建它。

```bash
sudo nano /etc/docker/daemon.json
```

2. 在这个文件中，你需要添加`registry-mirrors`键，并将其值设置为你想要的镜像源的URL。可以这样设置：

```json
{
 "registry-mirrors": ["http://hub-mirror.c.163.com"]
}
```

3. 保存并关闭文件。

4. 重启Docker服务以使更改生效：

```bash
sudo systemctl restart docker
```

5. 验证更改是否生效：

```bash
sudo docker info
```

在输出的信息中，你应该能看到`Registry Mirrors`部分显示的是你设置的镜像源。