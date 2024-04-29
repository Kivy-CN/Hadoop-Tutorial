
# Hadoop的安装

以下是在 Ubuntu Server 24.04 上安装 Hadoop 的步骤：

1. **更新系统**：首先，更新你的系统到最新状态。

```bash
sudo apt-get update
sudo apt-get upgrade
```

2. **安装 Java**：Hadoop 需要 Java 运行环境，你可以通过以下命令安装 OpenJDK：

```bash
sudo apt-get install openjdk-8-jdk
```

3. **下载 Hadoop**：从 Apache Hadoop 的官方网站下载最新稳定版的 Hadoop。你可以使用 `wget` 命令来下载：

```bash
wget -c https://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz
```

请注意，上述链接可能会随着新版本的发布而改变。

4. **解压 Hadoop**：使用 `tar` 命令解压下载的文件：

```bash
tar xzf hadoop-3.4.0.tar.gz
sudo mv hadoop-3.4.0 /usr/local/hadoop
```

5. **配置 Hadoop**：配置 Hadoop 的环境变量。 `nano ~/.bashrc` 打开配置文件，并在文件末尾添加以下行：

```bash
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:$PATH
export PATH=/usr/local/hadoop/bin:$PATH
export PATH=/usr/local/hadoop/sbin:$PATH
```

然后，运行以下命令使配置生效：

```bash
source ~/.bashrc
sudo hostnamectl set-hostname mini //改一下主机名，避免和其他的重复
```

6. **验证安装**：运行以下命令验证 Hadoop 是否安装成功：

```bash
hadoop version
```

如果安装成功，这个命令应该会输出你安装的 Hadoop 版本信息。

7. **安装SSH、配置SSH无密码登陆**

集群、单节点模式都需要用到 SSH 登陆（类似于远程登陆，你可以登录某台 Linux 主机，并且在上面运行命令），Ubuntu 默认已安装了 SSH client，此外还需要安装 SSH server：

```bash
sudo apt-get install openssh-server
```

安装后，可以使用如下命令登陆本机：
```bash
ssh localhost
```

此时会有如下提示(SSH首次登陆提示)，输入 yes 。然后按提示输入密码 hadoop，这样就登陆到本机了。

但这样登陆是需要每次输入密码的，我们需要配置成SSH无密码登陆比较方便。

首先退出刚才的 ssh，就回到了我们原先的终端窗口，然后利用 ssh-keygen 生成密钥，并将密钥加入到授权中：
```bash
exit         # 退出刚才的 ssh localhost
cd ~/.ssh/   # 若没有该目录，请先执行一次ssh localhost
ssh-keygen -t rsa   # 会有提示，都按回车就可以
cat ./id_rsa.pub >> ./authorized_keys  # 加入授权
```


~的含义: 在 Linux 系统中，~ 代表的是用户的主文件夹，即 "/home/用户名" 这个目录，如你的用户名为 hadoop，则 ~ 就代表 "/home/hadoop/"。 此外，命令中的 # 后面的文字是注释，只需要输入前面命令即可。

此时再用 `ssh localhost` 命令，无需输入密码就可以直接登陆了。

8. **配置 Hadoop 伪分布式**：

修改之前先备份文件：
```Bash
cp /usr/local/hadoop/etc/hadoop/core-site.xml /usr/local/hadoop/etc/hadoop/core-site.xml.back
cp /usr/local/hadoop/etc/hadoop/hdfs-site.xml /usr/local/hadoop/etc/hadoop/hdfs-site.xml.back
```

Hadoop 可以在单节点上以伪分布式的方式运行，Hadoop 进程以分离的 Java 进程来运行，节点既作为 NameNode 也作为 DataNode，同时，读取的是 HDFS 中的文件。

Hadoop 的配置文件位于 `/usr/local/hadoop/etc/hadoop/` 中，伪分布式需要修改2个配置文件 `core-site.xml` 和 `hdfs-site.xml` 。Hadoop的配置文件是 xml 格式，每个配置以声明 property 的 name 和 value 的方式来实现。

修改配置文件 `core-site.xml` (通过 nano 编辑会比较方便: `nano /usr/local/hadoop/etc/hadoop/core-site.xml`)，将当中的

```XML
<configuration>
</configuration>
```

修改为下面配置：

```XML
<configuration>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>file:/usr/local/hadoop/tmp</value>
        <description>Abase for other temporary directories.</description>
    </property>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
```

同样的，修改配置文件 `hdfs-site.xml` (通过 nano 编辑会比较方便: `nano /usr/local/hadoop/etc/hadoop/hdfs-site.xml`)：

```XML
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file:/usr/local/hadoop/tmp/dfs/name</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file:/usr/local/hadoop/tmp/dfs/data</value>
    </property>
</configuration>
```

Hadoop 的运行方式是由配置文件决定的（运行 Hadoop 时会读取配置文件），因此如果需要从伪分布式模式切换回非分布式模式，需要删除 core-site.xml 中的配置项。

此外，伪分布式虽然只需要配置 fs.defaultFS 和 dfs.replication 就可以运行（官方教程如此），不过若没有配置 hadoop.tmp.dir 参数，则默认使用的临时目录为 /tmp/hadoo-hadoop，而这个目录在重启时有可能被系统清理掉，导致必须重新执行 format 才行。所以我们进行了设置，同时也指定 dfs.namenode.name.dir 和 dfs.datanode.data.dir，否则在接下来的步骤中可能会出错。

配置完成后，执行 NameNode 的格式化:
```Bash
cd /usr/local/hadoop
./bin/hdfs namenode -format
```

然后可以使用 `start-all.sh` 脚本来启动 Hadoop 了：

```bash
start-all.sh
```

现在，你的 Hadoop 应该已经以伪分布式模式运行了。你可以使用 `jps` 命令来检查 Hadoop 的进程是否已经启动。如果 Hadoop 已经启动，`jps` 命令应该会显示 `NameNode`、`DataNode`、`SecondaryNameNode`、`NodeManager` 和 `ResourceManager` 这几个进程。


在Hadoop 2.x版本中，NameNode的Web界面默认在50070端口。但是在Hadoop 3.x版本中，这个端口已经改变为9870。
在浏览器中访问`http://localhost:9870/`（对于Hadoop 3.x）或`http://localhost:50070/`（对于Hadoop 2.x）来访问NameNode的Web界面。

