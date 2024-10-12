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
minikube dashboard --url
```
运行上述命令后，会输出一个 URL，例如 `http://127.0.0.1:XXXXX`，这是本地访问的地址。

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