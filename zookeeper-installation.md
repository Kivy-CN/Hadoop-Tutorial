# ZooKeeper的安装


要启动一个独立的ZooKeeper实例供HBase使用，你需要按照以下步骤操作：

1. 从Apache官方网站下载并解压ZooKeeper。你可以使用以下命令：

```bash
wget https://mirrors.tuna.tsinghua.edu.cn/apache/zookeeper/current/apache-zookeeper-3.9.2-bin.tar.gz
```

2. 解压后的目录移动到同一路径以便于访问：

```bash
tar -xzf apache-zookeeper-3.9.2-bin.tar.gz
sudo mv apache-zookeeper-3.9.2-bin /usr/local/zookeeper
```

3. 设置环境变量：

在`~/.bashrc`文件中添加以下内容：

```bash
export ZOOKEEPER_HOME=/usr/local/zookeeper
export PATH=$PATH:$ZOOKEEPER_HOME/bin
```

4. 进入ZooKeeper目录下的`conf`目录，并将`zoo_sample.cfg`文件重命名为`zoo.cfg`：

```bash
cd /usr/local/zookeeper/conf
cp zoo_sample.cfg zoo.cfg
```

5. 通过运行`bin`目录中的`zkServer.sh`脚本来启动ZooKeeper：

```bash
zkServer.sh start
```

现在，你的独立ZooKeeper实例应该已经在运行了。你可以通过运行以下命令来检查其状态：

```bash
zkServer.sh status
```
