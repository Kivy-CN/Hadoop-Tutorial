
# Hive的安装

Hive 的安装过程通常包括以下前置步骤：

* **已经安装 Java**：Hive 需要 Java 运行环境，因此首先需要在系统上安装 Java 8。

* **已经安装 Hadoop**：Hive 需要在系统上安装 Hadoop。这一步上一单元已经完成了。。

以下是在已经安装好 Hadoop 的基础上，安装 Hive 的步骤：

0. **MySQL** 安装：

```Bash
sudo apt-get update  #更新软件源
sudo apt-get install mysql-server  #安装mysql
```

安装过程会提示设置mysql root用户的密码。

然后下载MySQL JDBC 驱动程序，也称为 MySQL Connector/J。你可以从 MySQL 的官方网站下载，或者使用 wget 在终端中下载。以下是使用 wget 下载的命令：

```bash
wget -c https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.23.zip
```

下载完成后，解压下载的 zip 文件：

```bash
unzip mysql-connector-java-8.0.23.zip
```

将解压后的 jar 文件复制到 Java 的扩展目录：

```bash
sudo cp mysql-connector-java-8.0.23/mysql-connector-java-8.0.23.jar /usr/share/java/
sudo cp mysql-connector-java-8.0.23/mysql-connector-java-8.0.23.jar  /usr/local/hive/lib/ 
```

以上步骤完成后，MySQL JDBC 驱动程序就安装完成了。

重置 MySQL 密码，你可以按照以下步骤操作：

首先止 MySQL 服务。在终端中输入以下命令：

```bash
sudo systemctl stop mysql
```

然后，你需要以不检查权限的方式启动 MySQL 服务。在终端中输入以下命令：

```bash
sudo mkdir -p /var/run/mysqld
sudo chown mysql:mysql /var/run/mysqld
sudo mysqld_safe --skip-grant-tables &
```

接下来登录到 MySQL。在终端中输入以下命令：

```bash
mysql -u root
```

在 MySQL 命令行中，你需要刷新权限并设置新密码。输入以下命令：

```sql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'hadoop';
FLUSH PRIVILEGES;
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'hadoop';
```

将 'hadoop' 替换为你想要设置的新密码。

最后，你需要退出 MySQL 并重启 MySQL 服务。在终端中输入以下命令：

```bash
quit
sudo systemctl start mysql
```

以上步骤完成后，MySQL 的 root 用户密码就被重置了。

然后启动并登陆mysql shell
```Bash
sudo service mysql start #启动mysql服务
mysql -u root -p  #登陆shell界面
```

新建hive数据库。
```Bash
mysql> create database hive;    #这个hive数据库与hive-site.xml中localhost:3306/hive的hive对应，用来保存hive元数据
```

配置mysql允许hive接入：
```Bash
CREATE USER 'hive'@'localhost';
# 创建一个名为hive的用户，并使其可以连接到localhost
ALTER USER 'hive'@'localhost' IDENTIFIED BY 'hive';
# 为hive用户设置密码为hive
GRANT ALL ON *.* TO 'hive'@'localhost';
mysql> flush privileges;  #刷新mysql系统权限关系表
```

1. **下载 Hive**：可以从 Apache Hive 的官方网站下载最新的 Hive 发行版：

```Bash
wget -c https://mirrors.tuna.tsinghua.edu.cn/apache/hive/hive-4.0.0/apache-hive-4.0.0-bin.tar.gz
```


2. **解压 Hive**：使用 `tar` 命令解压下载的文件：

```Bash
tar xzf apache-hive-4.0.0-bin.tar.gz
sudo mv apache-hive-4.0.0-bin /usr/local/hive
```

3. **配置 Hive**：需要先创建`hive-default.xml`文件，然后编辑 Hive 的配置文件（`hive-site.xml`），设置 Hive 的运行模式（本地模式或 MapReduce 模式）和 Hive 数据的存储路径等。

```Bash
cd /usr/local/hive/conf
cp hive-default.xml.template hive-site.xml
nano /usr/local/hive/conf/hive-site.xml
```

在`hive-site.xml`中添加如下配置信息：
```XML
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
    <name>hive.server2.authentication</name>
    <value>NONE</value>
    </property>
   <property>
     <name>hive.server2.thrift.bind.host</name>
     <value>0.0.0.0</value>
   </property>
   <property>
     <name>hive.server2.thrift.port</name>
     <value>10000</value>
   </property>
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:mysql://localhost:3306/hive?createDatabaseIfNotExist=true</value>
    <description>JDBC connect string for a JDBC metastore</description>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>com.mysql.jdbc.Driver</value>
    <description>Driver class name for a JDBC metastore</description>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>hive</value>
    <description>username to use against metastore database</description>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>hive</value>
    <description>password to use against metastore database</description>
  </property>
</configuration>
```

4. **配置 Hive 环境变量**：编辑 `~/.bashrc` 文件，添加 Hive 的环境变量。你可以使用以下命令打开配置文件：

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
export HIVE_HOME=/usr/local/hive
export PATH=$PATH:$HIVE_HOME/bin
```

然后，运行以下命令使环境变量生效：

```bash
source ~/.bashrc
```

5. **配置 Hadoop**

编辑Hadoop的配置文件（`core-site.xml`），设置允许 `hadoop` 用户模拟 `hive` 用户。
```Bash
nano /usr/local/hadoop/etc/hadoop/core-site.xml
```
Hadoop 的配置文件 `core-site.xml` 中添加以下配置：

```xml
<property>
  <name>hadoop.proxyuser.hadoop.hosts</name>
  <value>*</value>
</property>
<property>
  <name>hadoop.proxyuser.hadoop.groups</name>
  <value>*</value>
</property>
```

修改配置后，需要重启 Hadoop 和 Hive 服务。
```Bash
stop-all.sh
start-all.sh
```


6. **Hadoop 创建路径**：


```bash
hadoop fs -mkdir -p /user/hive/warehouse/test_db.db
hadoop fs -chown -R hive:hadoop /user/hive/warehouse/test_db.db
hadoop fs -chmod -R 775 /user/hive/warehouse/test_db.db
hadoop fs -chown -R hive:hadoop /user/hive/warehouse
hadoop fs -chmod -R 775 /user/hive/warehouse
```
`

7. **启动 Hive**：

先初始化！！！

```bash
schematool -dbType mysql -initSchema
```

要停止所有的 Hive 服务，你需要停止 Hive Metastore 服务和 HiveServer2 服务。这通常可以通过以下命令完成：

```bash
# 停止 Hive Metastore
pkill -f HiveMetaStore

# 停止 HiveServer2
pkill -f HiveServer2
```

这些命令会找到运行 Hive Metastore 和 HiveServer2 的进程，并发送 SIGTERM 信号来优雅地停止这些进程。如果这些进程没有响应 SIGTERM 信号，你可以使用 SIGKILL 信号强制停止这些进程，例如：

```bash
# 强制停止 Hive Metastore
pkill -9 -f HiveMetaStore

# 强制停止 HiveServer2
pkill -9 -f HiveServer2
```
在 Python 中使用 Hive，可以使用 `pyhive` 库。以下是一个简单的示例，展示如何连接到 Hive，执行查询，然后获取结果：

首先，要运行Hiveserver2。然后要确保已经安装了 `pyhive` 等依赖包。如果没有，可以使用 pip 安装：

```Bash
hive --service hiveserver2 &
pip install pyhive thrift thrift_sasl --break-system-packages
```

然后，可以使用以下 Python 代码来操作 Hive：

```python
from pyhive import hive

# 连接到 Hive
conn = hive.Connection(host='localhost', port=10000, username='hadoop')

# 创建一个 cursor
cursor = conn.cursor()

cursor.execute('''
    CREATE TABLE IF NOT EXISTS my_table (
        column1 STRING,
        column2 STRING,
        column3 STRING
    ) 
    ROW FORMAT DELIMITED 
    FIELDS TERMINATED BY ',' 
    STORED AS TEXTFILE
''')

cursor.execute('''
    CREATE TABLE IF NOT EXISTS students (
        name STRING,
        major STRING,
        gender STRING
    ) 
    ROW FORMAT DELIMITED 
    FIELDS TERMINATED BY ',' 
    STORED AS TEXTFILE
''')

cursor.execute('''
    INSERT INTO students (name, major, gender) 
    VALUES ('Tom', 'Computer Science', 'Male')
''')


# 获取所有表的名称
cursor.execute("SHOW TABLES")
tables = cursor.fetchall()

for table in tables:
    table_name = table[0]
    print(f"Table Name: {table_name}")
    
    # 获取并打印表的结构
    cursor.execute(f"DESCRIBE {table_name}")
    schema = cursor.fetchall()
    for column in schema:
        print(column)        
    print("\n")

# 执行查询
cursor.execute('SELECT * FROM students')

# 获取结果
for result in cursor.fetchall():
    print(result)
```

请注意，这个示例假设 Hive 服务正在本地运行，并且监听的是默认的端口（10000）。如果 Hive 服务在其他地方运行，或者使用的是其他端口，需要在创建 `hive.Connection` 时提供正确的主机名和端口号。
