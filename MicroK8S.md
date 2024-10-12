MicroK8s 和 Docker 可能会发生冲突，因为 MicroK8s 自带了一个轻量级的容器运行时。如果你已经安装了 Docker，可能会导致 MicroK8s 启动时出现问题。以下是一些步骤来解决这个问题：

### 检查 Docker 是否正在运行

1. **检查 Docker 服务状态**:
    ```sh
    sudo systemctl status docker
    ```

2. **停止 Docker 服务**:
    ```sh
    sudo systemctl stop docker
    ```

### 卸载 Docker（如果需要）

如果你不需要 Docker，可以选择卸载它：

1. **卸载 Docker**:
    ```sh
    sudo apt-get remove docker docker-engine docker.io containerd runc
    ```

2. **清理残留数据**:
    ```sh
    sudo apt-get purge docker-ce docker-ce-cli containerd.io
    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd
    ```

### 重新启动 MicroK8s

1. **启动 MicroK8s**:
    ```sh
    sudo microk8s start
    ```

2. **检查 MicroK8s 状态**:
    ```sh
    sudo microk8s status --wait-ready
    ```

### 示例命令

```sh
# 检查 Docker 服务状态
sudo systemctl status docker

# 停止 Docker 服务
sudo systemctl stop docker

# 卸载 Docker
sudo apt-get remove docker docker-engine docker.io containerd runc

# 清理残留数据
sudo apt-get purge docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# 启动 MicroK8s
sudo microk8s start

# 检查 MicroK8s 状态
sudo microk8s status --wait-ready
```



The error message indicates that the `localnode.yaml` file is missing, which might be required for MicroK8s to function correctly. This file is typically generated during the initialization of the MicroK8s cluster. If it is missing, it could be due to an incomplete or failed installation.

Here are some steps to ensure that MicroK8s is properly configured and to regenerate the necessary files:

### Step-by-Step Guide

1. **Ensure MicroK8s is Fully Installed**:
    ```sh
    sudo snap install microk8s --classic
    ```

2. **Reset MicroK8s**:
    ```sh
    sudo microk8s reset
    ```

3. **Start MicroK8s**:
    ```sh
    sudo microk8s start
    ```

4. **Check MicroK8s Status**:
    ```sh
    sudo microk8s status --wait-ready
    ```

5. **Enable Required Add-ons**:
    ```sh
    sudo microk8s enable dns dashboard
    ```

6. **Inspect MicroK8s Again**:
    ```sh
    sudo microk8s inspect
    ```

### Example Commands

```sh
# Ensure MicroK8s is fully installed
sudo snap install microk8s --classic

# Reset MicroK8s
sudo microk8s reset

# Start MicroK8s
sudo microk8s start

# Check MicroK8s status
sudo microk8s status --wait-ready

# Enable required add-ons
sudo microk8s enable dns dashboard storage

# Inspect MicroK8s again
sudo microk8s inspect

sudo microk8s kubectl get all --all-namespaces

token=$(microk8s kubectl -n kube-system get secret | grep default-token | cut -d " " -f1)
microk8s kubectl -n kube-system describe secret $token
```

These steps should help regenerate the necessary configuration files, including `localnode.yaml`. If the problem persists, it might be helpful to check the MicroK8s logs for more detailed error messages:

```sh
sudo journalctl -u snap.microk8s.daemon-kubelite
```

This command will show the logs for the `kubelite` service, which might provide more insight into why the `localnode.yaml` file is not being generated.


要从物理机（IP 地址为 192.168.0.152）访问 Kubernetes Dashboard 网页，你需要将 Kubernetes Dashboard 服务暴露出来，使其可以通过物理机的 IP 地址访问。以下是详细步骤：

### 1. 启用 Kubernetes Dashboard

如果还没有启用 Kubernetes Dashboard，可以使用以下命令启用：

```sh
sudo microk8s enable dashboard
```

### 2. 创建访问权限

创建一个服务账户和集群角色绑定，以便能够访问 Kubernetes Dashboard：

```sh
sudo microk8s kubectl create serviceaccount dashboard-admin -n kube-system
sudo microk8s kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
```

### 3. 获取访问令牌

获取服务账户的访问令牌：

```sh
sudo microk8s kubectl -n kube-system describe secret $(sudo microk8s kubectl -n kube-system get secret | grep dashboard-admin | awk '{print $1}')
```

记下输出中的 `token` 值，这将在登录 Dashboard 时使用。

### 4. 暴露 Kubernetes Dashboard 服务

将 Kubernetes Dashboard 服务暴露为 NodePort，使其可以通过物理机的 IP 地址访问：

```sh
sudo microk8s kubectl -n kube-system edit service kubernetes-dashboard
```

在编辑器中，将 `type: ClusterIP` 修改为 `type: NodePort`，然后保存并退出。

### 5. 获取 NodePort

获取 Kubernetes Dashboard 服务的 NodePort：

```sh
sudo microk8s kubectl -n kube-system get service kubernetes-dashboard
```

你会看到类似以下的输出：

```
NAME                   TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)         AGE
kubernetes-dashboard   NodePort   10.152.183.168   <none>        443:XXXXX/TCP   8s
```

记下 `443:XXXXX/TCP` 中的 `XXXXX`，这就是 NodePort。

### 6. 访问 Kubernetes Dashboard

在浏览器中访问以下 URL：

```
https://192.168.0.152:XXXXX
```

其中 `XXXXX` 是你在上一步中获取的 NodePort。

### 7. 登录 Kubernetes Dashboard

在登录页面中，选择 `Token` 选项，并输入在步骤 3 中获取的 `token` 值，然后点击登录。

### 示例命令

```sh
# 启用 Kubernetes Dashboard
sudo microk8s enable dashboard

# 创建服务账户和集群角色绑定
sudo microk8s kubectl create serviceaccount dashboard-admin -n kube-system
sudo microk8s kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin

# 获取访问令牌
sudo microk8s kubectl -n kube-system describe secret $(sudo microk8s kubectl -n kube-system get secret | grep dashboard-admin | awk '{print $1}')

# 编辑 Kubernetes Dashboard 服务
sudo microk8s kubectl -n kube-system edit service kubernetes-dashboard

# 获取 NodePort
sudo microk8s kubectl -n kube-system get service kubernetes-dashboard
```


token:      eyJhbGciOiJSUzI1NiIsImtpZCI6IlFvMlIzUFdfeWdNYjZyMW1KcFZOX1pXeXExV0YyZHNmNFJKbmVwMzFYalEifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJtaWNyb2s4cy1kYXNoYm9hcmQtdG9rZW4iLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoiZGVmYXVsdCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6Ijg0ZmQ2YjdiLWM1ZmUtNGZhNi1hNzQzLTU2ZmU4YzhhODljYiIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlLXN5c3RlbTpkZWZhdWx0In0.gT49jKG-rRqhky0GcKq6loj9P69HjkVFgtoCKo915yjPTO2aP_6x5zVH2MLgIMJyTBz2zD6tKt4bygusllmuanev5Pxe0QNYXQdi6ppzPqC_fwgyFJdlG77sMVGxkmWo1wWws2tLs_R6EAoZ4GaT224_qq3awOvtberGnA5-IjYcU-KimO4xiccmQP8RviHjRtar-LKqDOCZfigBGqWGgsjGmBkuERWmGFPGCpw70juGiUzxFpKHxOdhLc-jX0E_xLvPX5F_fAsf4pMBj04xSaSk54X0O88Fcrxl16IHJg7ops9yGfXh4sNERN2mE0diEoNiLlChms_yfZV7G5GMQw


要从物理机（IP 地址为 192.168.0.152）访问 Kubernetes Dashboard 网页，你需要将 Kubernetes Dashboard 服务暴露出来，使其可以通过物理机的 IP 地址访问。以下是详细步骤：

### 1. 启用 Kubernetes Dashboard

如果还没有启用 Kubernetes Dashboard，可以使用以下命令启用：

```sh
sudo microk8s enable dashboard
```

### 2. 创建访问权限

创建一个服务账户和集群角色绑定，以便能够访问 Kubernetes Dashboard：

```sh
sudo microk8s kubectl create serviceaccount dashboard-admin -n kube-system
sudo microk8s kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
```

### 3. 获取访问令牌

获取服务账户的访问令牌：

```sh
sudo microk8s kubectl -n kube-system describe secret $(sudo microk8s kubectl -n kube-system get secret | grep dashboard-admin | awk '{print $1}')
```

记下输出中的 `token` 值，这将在登录 Dashboard 时使用。

### 4. 暴露 Kubernetes Dashboard 服务

将 Kubernetes Dashboard 服务暴露为 NodePort，使其可以通过物理机的 IP 地址访问：

```sh
sudo microk8s kubectl -n kube-system edit service kubernetes-dashboard
```

在编辑器中，将 `type: ClusterIP` 修改为 `type: NodePort`，然后保存并退出。

### 5. 获取 NodePort

获取 Kubernetes Dashboard 服务的 NodePort：

```sh
sudo microk8s kubectl -n kube-system get service kubernetes-dashboard
```

你会看到类似以下的输出：

```
NAME                   TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)         AGE
kubernetes-dashboard   NodePort   10.152.183.168   <none>        443:XXXXX/TCP   8s
```

记下 `443:XXXXX/TCP` 中的 `XXXXX`，这就是 NodePort。

### 6. 访问 Kubernetes Dashboard

在浏览器中访问以下 URL：

```
https://192.168.0.152:XXXXX
```

其中 `XXXXX` 是你在上一步中获取的 NodePort。

### 7. 登录 Kubernetes Dashboard

在登录页面中，选择 `Token` 选项，并输入在步骤 3 中获取的 `token` 值，然后点击登录。

### 示例命令

```sh
# 启用 Kubernetes Dashboard
sudo microk8s enable dashboard

# 创建服务账户和集群角色绑定
sudo microk8s kubectl create serviceaccount dashboard-admin -n kube-system
sudo microk8s kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin

# 获取访问令牌
sudo microk8s kubectl -n kube-system describe secret $(sudo microk8s kubectl -n kube-system get secret | grep dashboard-admin | awk '{print $1}')

# 编辑 Kubernetes Dashboard 服务
sudo microk8s kubectl -n kube-system edit service kubernetes-dashboard

# 获取 NodePort
sudo microk8s kubectl -n kube-system get service kubernetes-dashboard

sudo ufw allow 31617/tcp
```


