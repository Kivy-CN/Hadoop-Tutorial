# Docker 和 Docker Compose 的安装

在Ubuntu 24.04上直接安装Docker和Docker Compose的步骤如下：

1. 更新现有的包列表：
```bash
sudo apt-get update
```

2. 安装Docker：
```bash
sudo apt-get install docker.io
```

3. 启动Docker服务并设置为开机启动：
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

4. 验证Docker是否成功安装：
```bash
docker --version
```

5. 安装Docker Compose：
```bash
sudo apt-get install docker-compose
```

6. 验证Docker Compose是否成功安装：
```bash
docker-compose --version
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
 "registry-mirrors": ["https://registry.docker-cn.com"]
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