# HBase的安装

HBase 的安装过程通常包括以下前置步骤：

* **已经安装 Java**：HBase 需要 Java 运行环境，因此首先需要在系统上安装 Java 8。

* **已经安装 Hadoop**：HBase 需要在系统上安装 Hadoop。这一步上一单元已经完成了。。

以下是在已经安装好 Hadoop 的基础上，安装 HBase 的步骤：

1. **下载 HBase**：首先，从 Apache HBase 的官方网站下载最新稳定版的 HBase。你可以使用 `wget` 命令来下载：

```bash
wget -c https://mirrors.tuna.tsinghua.edu.cn/apache/hbase/stable/hbase-2.5.8-bin.tar.gz
```

请注意，上述链接可能会随着新版本的发布而改变。

2. **解压 HBase**：使用 `tar` 命令解压下载的文件：

```bash
tar xzf hbase-2.5.8-bin.tar.gz
sudo mv hbase-2.5.8 /usr/local/hbase
```

3. **配置 HBase**：编辑 HBase 的配置文件 `hbase-site.xml`，设置 HBase 的运行模式和数据存储路径。你可以使用以下命令打开配置文件：

```bash
cp /usr/local/hbase/conf/hbase-site.xml /usr/local/hbase/conf/hbase-site.xml.back
nano /usr/local/hbase/conf/hbase-site.xml
```

然后，添加以下内容到配置文件：

```xml
<configuration>
   <property>
      <name>hbase.rootdir</name>
        <value>hdfs://localhost:9000/hbase</value>
    </property>
    <property>
      <name>hbase.cluster.distributed</name>
        <value>true</value>
    </property>
    <property>
      <name>hbase.unsafe.stream.capability.enforce</name>
        <value>false</value>
    </property>
    <property>
      <name>hbase.wal.provider</name>
        <value>filesystem</value>
    </property>
    <property>
        <name>hbase.master.info.port</name>
        <value>16010</value>
    </property>
    <property>
        <name>hbase.regionserver.info.port</name>
        <value>16020</value>
    </property>
</configuration>
```

4. **配置 HBase 环境变量**：编辑 `~/.bashrc` 文件，添加 HBase 的环境变量。你可以使用以下命令打开配置文件：

```bash
nano ~/.bashrc
```

然后，添加以下内容到文件末尾：

```bash
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:$PATH
export PATH=/usr/local/hadoop/bin:$PATH
export PATH=/usr/local/hadoop/sbin:$PATH
export PATH=$PATH:/usr/local/hbase/bin
```

然后，运行以下命令使环境变量生效：

```bash
source ~/.bashrc
```

5. **启动 HBase**：最后，你可以使用以下命令启动 HBase：

```bash
start-hbase.sh
```

现在，你应该已经成功安装并启动了 HBase。你可以通过访问 `http://localhost:16010` 来查看 HBase 的状态。

## 4.5. HBase的使用

安装好的 HBase 有多种使用方式：

1. **HBase Shell**：HBase 提供了一个交互式的 shell，可以使用它来执行各种 HBase 命令，如创建表、插入数据、查询数据等。可以通过运行 `./bin/hbase shell` 来启动 HBase shell。

2. **Java API**：HBase 提供了一个丰富的 Java API，可以使用它来编写 Java 程序操作 HBase。例如，可以使用 HTable 类来操作 HBase 表，使用 Put 类来插入数据，使用 Get 类来查询数据等。

3. **REST API**：HBase 提供了一个 REST API，可以使用任何支持 HTTP 的编程语言通过 HTTP 请求来操作 HBase。

4. **Thrift API**：HBase 还提供了一个 Thrift API，可以使用任何支持 Thrift 的编程语言来操作 HBase。

5. **JDBC**：HBase 提供了一个 JDBC 驱动，可以使用 JDBC 来操作 HBase。这使得可以使用 SQL 语言来查询 HBase 数据，也可以使用任何支持 JDBC 的工具或框架来操作 HBase。

6. **HBase Admin UI**：HBase 提供了一个 Web UI，可以通过浏览器访问它来查看 HBase 的状态和性能指标，以及执行一些管理操作。


```Bash
# 进入HBase shell
hbase shell

# 创建一个名为'test_table'的表，有一个名为'test_family'的列族
create 'test_table', 'test_family'

# 插入一些随机数据
put 'test_table', 'row1', 'test_family:col1', 'value1'
put 'test_table', 'row2', 'test_family:col2', 'value2'
put 'test_table', 'row3', 'test_family:col3', 'value3'

# 扫描并打印表中的所有数据
scan 'test_table'
```

## 4.6. HBase操作的Python演示

在HBase shell中，可以使用以下命令来删除所有的表：

```bash
hbase shell
list.each { |table| disable table; drop table }
```

这段代码首先列出所有的表，然后对每个表执行`disable`和`drop`操作。`disable`操作是必要的，因为不能删除一个正在使用的表。

请注意，这将删除所有的表，包括任何重要的数据。在执行这个操作之前，请确保已经备份了所有重要的数据。

要在 Python 中使用 HBase，可以使用 `happybase` 库。以下是一个简单的示例，展示如何连接到 HBase，创建表，插入数据，然后查询数据：

首先，要启动thrift，然后确保已经安装了 `happybase`。如果没有，可以使用 pip 安装：

```bash
start-all.sh
start-hbase.sh
nohup hbase thrift start > hbase_thrift.log 2>&1 &
pip install happybase hbase --break-system-packages
```

然后，可以使用以下 Python 代码来操作 HBase：

```python
import os
import happybase

# 连接到 HBase
connection = happybase.Connection('localhost', 9090)
# 获取表名列表
table_names = connection.tables()
# 解码表名
table_names = [name.decode('utf-8') for name in table_names]
print(table_names)

# 从环境变量获取表名和列族
table_name = os.getenv('HBASE_TABLE_NAME', 'score_info')
families = {
    'name': dict(max_versions=10),
    'score': dict(max_versions=1, block_cache_enabled=False),
    'date': dict(),  # 使用默认值
}
# 检查表是否存在
if table_name in connection.tables():
    print(f"Table {table_name} already exists.")
else:
    connection.create_table(table_name, families)
    print(f"Table {table_name} created.")

# 获取表
table = connection.table(table_name)

# 插入数据
table.put('student1', {
    'name:full_name': "Fred",
    'score:poltics': '74',
    'score:english': '104',
    'score:chinese': '117',
    'date:created': '2024-01-09'
})

# 插入数据
table.put('student2', {
    'name:full_name': "于同学",
    'score:政治': '74',
    'score:英语': '104',
    'score:语文': '117',
    'date:created': '2024-01-09'
})

# 查询数据
data = table.row('student2')

# 打印数据
for key, value in data.items():
    print(f"{key.decode('utf-8')}: {value.decode('utf-8')}")
```

请注意，这个示例假设 HBase Thrift 服务正在本地运行，并且监听的是默认的端口（9090）。如果 HBase Thrift 服务在其他地方运行，或者使用的是其他端口，需要在创建 `happybase.Connection` 时提供正确的主机名和端口号。

