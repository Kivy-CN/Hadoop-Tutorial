### 安装和配置 Minikube 以及 Web UI 访问

#### 1. 更新系统
```bash
sudo apt update && sudo apt upgrade -y
```

#### 2. 安装必要的依赖
```bash
sudo apt install -y curl apt-transport-https
```

#### 3. 安装 Docker
```bash
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
```

#### 4. 安装 Minikube
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

或者另一种方式：
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
sudo dpkg -i minikube_latest_amd64.deb
```


#### 5. 启动 Minikube
```bash
minikube start --driver=docker
```

#### 6. 安装 kubectl
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

或者用Snap安装：
```bash
sudo snap install kubectl
```

#### 7. 启用 Kubernetes Dashboard
```bash
minikube addons enable metrics-server
minikube addons enable dashboard
minikube addons enable ingress
minikube addons enable storage-provisioner
minikube addons enable default-storageclass
minikube dashboard --url
```
运行上述命令后，会输出一个 URL，例如 `http://127.0.0.1:XXXXX`，这是本地访问的地址。


sudo k3s kubectl -n kubernetes-dashboard create token admin-user
eyJhbGciOiJSUzI1NiIsImtpZCI6IjhsVV84bFMtamNTRGZ4ZFRGNE1qQnpJT2stQzA0SVUyMGU5SjZQU3lBajQifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiLCJrM3MiXSwiZXhwIjoxNzI4NzgzMzMyLCJpYXQiOjE3Mjg3Nzk3MzIsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwianRpIjoiYjQ3MjYyM2UtNzcxNS00YWUxLWEwMGUtZmNhOTEyZjgyNzFhIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsInNlcnZpY2VhY2NvdW50Ijp7Im5hbWUiOiJhZG1pbi11c2VyIiwidWlkIjoiOTk4Yjk4ZDYtODE5ZS00NmE2LThjZjYtMjNkZDVlNTk0NzA1In19LCJuYmYiOjE3Mjg3Nzk3MzIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlcm5ldGVzLWRhc2hib2FyZDphZG1pbi11c2VyIn0.XthBNi0b_OT31QyeWdwapXaRL8IjNXlt-YYRbo5lZQSR4QmRKgwntGrzqDE5gXsseAiKoKrbfSIfMDQ9A1CSSreIqa-8rl7hh8nWudm2xpxukgdKqNKqzv2v5I2r9XkSaRrU2SfmL3QP7IId6g0r_AXhYgSsLynZJxzOnpXynRa0klWZAT6HbWwKnK_o5kMI5X495q1D_U9ZB7VP9bCwpqK2H6It-tR5syRmfOF0HX4D4L_NpI4vj2k7styAEr2IbpdjDhsumkN0FIFIvywBNl-WapzaRRYaoDdqFtpSs0QVNRgTwNz1A1hxC4-rKRXSzKHHNNavhIOeDIMjFbSkPg


#### 8. 配置局域网访问
为了在局域网内通过 IP 和端口访问，需要进行端口转发。

首先，获取 Minikube 的 IP 地址：
```bash
minikube ip
```

然后，使用 `kubectl` 进行端口转发：
```bash
kubectl proxy --address='0.0.0.0' --accept-hosts='^.*$'
```

#### 9. 访问 Web UI
在局域网内的其他机器上，通过浏览器访问 `http://<Minikube_IP>:8001/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/` 即可访问 Kubernetes Dashboard。