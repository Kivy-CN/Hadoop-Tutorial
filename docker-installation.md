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