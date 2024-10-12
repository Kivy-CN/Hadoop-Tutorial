在安装 K3s 时，由于网络限制，可能需要手动下载的 K3s 二进制文件进行安装，可以按照以下步骤操作：

1. **下载 K3s 二进制文件**：
   访问 GitHub Releases 页面，下载指定版本的 K3s 二进制文件。例如，下载 v1.31.1+k3s1 版本：

   ```sh
   curl -Lo k3s https://github.com/k3s-io/k3s/releases/download/v1.31.1%2Bk3s1/k3s
   ```

2. **赋予执行权限**：
   下载完成后，赋予二进制文件执行权限。

   ```sh
   chmod +x k3s
   ```

3. **移动二进制文件到系统路径**：
   将二进制文件移动到系统路径，例如 `/usr/local/bin`。

   ```sh
   sudo mv k3s /usr/local/bin/
   ```

4. **创建 K3s 服务文件**：
   创建一个 systemd 服务文件来管理 K3s 服务。

   ```sh
   sudo tee /etc/systemd/system/k3s.service <<EOF
   [Unit]
   Description=Lightweight Kubernetes
   Documentation=https://k3s.io
   Wants=network-online.target
   After=network-online.target

   [Service]
   Type=exec
   ExecStart=/usr/local/bin/k3s server
   Restart=on-failure
   RestartSec=5s

   [Install]
   WantedBy=multi-user.target
   EOF
   ```

5. **启动并启用 K3s 服务**：
   启动 K3s 服务并设置开机自启动。

   ```sh
   sudo systemctl daemon-reload
   sudo systemctl enable k3s
   sudo systemctl start k3s
   ```

6. **验证安装**：
   验证 K3s 是否安装成功并运行正常。

   ```sh
   kubectl get nodes
   ```


这个错误表明 [`kubectl`](command:_github.copilot.openSymbolFromReferences?%5B%22%22%2C%5B%7B%22uri%22%3A%7B%22scheme%22%3A%22file%22%2C%22authority%22%3A%22%22%2C%22path%22%3A%22%2FC%3A%2FUsers%2FHP%2FDocuments%2FGitHub%2FHadoop-Tutorial%2FK3S.md%22%2C%22query%22%3A%22%22%2C%22fragment%22%3A%22%22%7D%2C%22pos%22%3A%7B%22line%22%3A58%2C%22character%22%3A3%7D%7D%5D%2C%227f469268-e672-48f4-bbdf-6b10331655c5%22%5D "Go to definition") 无法连接到 Kubernetes API 服务器，并且你在尝试访问 Kubeconfig 文件时遇到了权限问题。以下是解决步骤：

1. **检查 Kubeconfig 文件权限**：
   确认 `/etc/rancher/k3s/k3s.yaml` 文件的权限，确保当前用户有读取权限。

   ```sh
   sudo chmod 644 /etc/rancher/k3s/k3s.yaml
   ```

2. **设置 KUBECONFIG 环境变量**：
   设置 `KUBECONFIG` 环境变量指向 K3s 的 Kubeconfig 文件。

   ```sh
   export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
   ```

   你可以将这行命令添加到你的 shell 配置文件（例如 `.bashrc` 或 `.zshrc`）中，以便每次启动 shell 时自动设置。

3. **验证 API 服务器连接**：
   使用 [`kubectl`](command:_github.copilot.openSymbolFromReferences?%5B%22%22%2C%5B%7B%22uri%22%3A%7B%22scheme%22%3A%22file%22%2C%22authority%22%3A%22%22%2C%22path%22%3A%22%2FC%3A%2FUsers%2FHP%2FDocuments%2FGitHub%2FHadoop-Tutorial%2FK3S.md%22%2C%22query%22%3A%22%22%2C%22fragment%22%3A%22%22%7D%2C%22pos%22%3A%7B%22line%22%3A58%2C%22character%22%3A3%7D%7D%5D%2C%227f469268-e672-48f4-bbdf-6b10331655c5%22%5D "Go to definition") 验证是否可以连接到 API 服务器。

   ```sh
   kubectl cluster-info
   ```

   如果连接成功，你应该会看到类似以下的输出：

   ```
   Kubernetes control plane is running at https://127.0.0.1:6443
   CoreDNS is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
   ```

4. **检查 K3s 服务状态**：
   确认 K3s 服务是否正在运行。

   ```sh
   sudo systemctl status k3s
   ```

   如果服务没有运行，请启动服务：

   ```sh
   sudo systemctl start k3s
   ```

5. **检查防火墙设置**：
   确认防火墙没有阻止本地访问 API 服务器端口（默认是 6443）。

   ```sh
   sudo ufw allow 6443/tcp
   ```

6. **再次检查节点状态**：
   重新运行 `kubectl get nodes` 命令，查看节点状态。

   ```sh
   kubectl get nodes
   ```


要从局域网访问 K3s API 服务器，你需要进行以下配置：

1. **修改 K3s 启动参数**：
   修改 K3s 的启动参数，使其监听在局域网 IP 地址上。你可以通过修改 K3s 的 systemd 服务文件来实现。

   编辑 `/etc/systemd/system/k3s.service` 文件，找到 `ExecStart` 行，并添加 `--tls-san` 参数，指定你的局域网 IP 地址。例如：

   ```sh
   sudo nano /etc/systemd/system/k3s.service
   ```

   找到 `ExecStart` 行，修改为：

   ```sh
   ExecStart=/usr/local/bin/k3s server --tls-san 192.168.0.152
   ```

2. **重新加载 systemd 配置并重启 K3s 服务**：

   ```sh
   sudo systemctl daemon-reload
   sudo systemctl restart k3s
   ```

3. **更新 Kubeconfig 文件**：
   更新 `/etc/rancher/k3s/k3s.yaml` 文件中的 `server` 字段，使其指向局域网 IP 地址。

   ```sh
   sudo sed -i 's/127.0.0.1/192.168.0.152/g' /etc/rancher/k3s/k3s.yaml
   ```

4. **配置防火墙**：
   确保防火墙允许从局域网访问 API 服务器端口（默认是 6443）。

   ```sh
   sudo ufw allow 6443/tcp
   ```

5. **验证局域网访问**：
   在局域网内的另一台机器上，设置 `KUBECONFIG` 环境变量指向更新后的 Kubeconfig 文件，并验证连接。

   ```sh
   export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
   kubectl cluster-info
   ```

通过以上步骤，你应该能够从局域网访问 K3s API 服务器。

通过以上步骤，你可以手动下载并安装 K3s，避免由于网络问题导致的安装失败。

   然后重启 Docker 服务：

   ```sh
   sudo systemctl daemon-reload
   sudo systemctl restart docker
   ```

   对于 containerd，可以编辑 `/etc/rancher/k3s/registries.yaml` 文件，添加以下内容：

   ```yaml
   mirrors:
     "docker.io":
       endpoint:
         - "https://registry.docker-cn.com"
   ```

   然后重启 K3s 服务：

   ```sh
   sudo systemctl restart k3s
   ```

5. **验证安装**：
   验证 K3s 是否安装成功并运行正常。

   ```sh
   kubectl get nodes
   ```

这样，就可以在成功安装并运行 K3s 了。

可以，K3s 也可以配置 Kubernetes Dashboard。以下是配置步骤：

1. **安装 Kubernetes Dashboard**：
   使用 `kubectl` 命令来部署 Kubernetes Dashboard。

   ```sh
   curl -Lo recommended.yaml https://kubernetes-sigs.github.io/dashboard/v2.5.1/aio/deploy/recommended.yaml

   kubectl apply -f recommended.yaml
   ```

2. **创建服务账户和绑定角色**：
   创建一个服务账户并绑定适当的角色，以便访问 Dashboard。

   ```sh
   kubectl create serviceaccount dashboard-admin-sa
   kubectl create clusterrolebinding dashboard-admin-sa --clusterrole=cluster-admin --serviceaccount=default:dashboard-admin-sa
   ```

3. **获取访问令牌**：
   获取服务账户的访问令牌，用于登录 Dashboard。

   ```sh
   kubectl get secret $(kubectl get serviceaccount dashboard-admin-sa -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"
   ```

4. **访问 Dashboard**：
   启动本地代理以访问 Dashboard。

   ```sh
   kubectl proxy
   ```

   然后在浏览器中访问以下 URL：

   ```
   http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
   ```

5. **登录 Dashboard**：
   使用步骤 3 中获取的访问令牌登录 Dashboard。

这样，就可以在 K3s 集群中使用 Kubernetes Dashboard 了。