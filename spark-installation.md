# Spark的安装

如果你的系统已经运行了 Hadoop 3，你可以按照以下步骤下载并安装 Spark：
如果你想将 Spark 安装在 `/usr/local/spark` 目录下，你可以按照以下步骤操作：

1. **下载 Spark**：你可以使用 `wget` 命令来下载 Spark。以下是在终端中运行的命令：

```bash
wget -c https://mirrors.tuna.tsinghua.edu.cn/apache/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz
```

2. **解压 Spark**：下载完成后，你需要使用 `tar` 命令来解压 Spark。然后，你可以使用 `mv` 命令将 Spark 移动到 `/usr/local/spark` 目录下。以下是在终端中运行的命令：

```bash
tar -xzf spark-3.5.1-bin-hadoop3.tgz
sudo mv spark-3.5.1-bin-hadoop3 /usr/local/spark
```

3. **配置 Spark**：解压并移动完成后，你需要配置 Spark 的环境变量。你可以在你的 `~/.bashrc` 文件中添加以下行：

```bash
export SPARK_HOME=/usr/local/spark
export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
export PYSPARK_PYTHON=/usr/bin/python3
```

然后，运行 `source ~/.bashrc` 来应用这些更改。

4. **启动 Spark**：最后，你可以使用 `start-master.sh` 和 `start-worker.sh` 脚本来启动 Spark 的 master 和 worker 节点。以下是在终端中运行的命令：

```bash
start-master.sh
start-worker.sh spark://localhost:7077
```

现在，你应该可以在你的浏览器中访问 `http://localhost:8080` 来查看 Spark 的 Web UI。
