#!/bin/bash
# Ubuntu 24.04 搭建 Hadoop 生态系统脚本（适用于中国大陆地区）

set -e  # 遇到错误立即停止执行

echo "========== 开始安装 Docker 和 Hadoop 生态系统 =========="

# 步骤1：使用国内镜像安装 Docker
echo "正在安装 Docker..."
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release

# 添加 Docker 的 GPG 密钥（使用阿里云镜像）
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -

# 添加 Docker 仓库（使用阿里云镜像）
sudo add-apt-repository "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"

# 安装 Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# 启动并设置 Docker 开机自启
sudo systemctl start docker
sudo systemctl enable docker

# 将当前用户添加到 docker 组（免 sudo 运行 docker）
sudo usermod -aG docker $USER

# 配置 Docker 使用国内镜像加速
sudo mkdir -p /etc/docker
cat << EOF | sudo tee /etc/docker/daemon.json
{
    "registry-mirrors": [
        "https://docker.1ms.run",
        "https://docker.xuanyuan.me"
    ]
}
EOF

# 重启 Docker 使配置生效
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "Docker 安装完成，已配置国内镜像加速"

# 需要重新登录以应用 docker 组权限
echo "请注意：您需要重新登录以应用 docker 组权限"
echo "执行 'su - $USER' 或登出并重新登录后继续执行脚本的其余部分"
echo "按任意键继续..."
read -n 1 -s

# 步骤2：创建 Docker 网络
docker network create hadoop-network

# 步骤3：设置 Hadoop
echo "正在设置 Hadoop..."

# 拉取 Hadoop 镜像（使用官方镜像）
docker pull apache/hadoop:3

# 创建 Hadoop 数据目录
mkdir -p ~/hadoop-data/hdfs/namenode
mkdir -p ~/hadoop-data/hdfs/datanode

# 创建 Hadoop 配置文件
mkdir -p ~/hadoop-config
cat << EOF > ~/hadoop-config/core-site.xml
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://hadoop-master:9000</value>
    </property>
</configuration>
EOF

cat << EOF > ~/hadoop-config/hdfs-site.xml
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/hadoop/hdfs/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/hadoop/hdfs/datanode</value>
    </property>
</configuration>
EOF

# 运行 Hadoop 容器
docker run -d --name hadoop-master \
    --hostname hadoop-master \
    --network hadoop-network \
    -p 9870:9870 -p 9000:9000 -p 8088:8088 \
    -v ~/hadoop-config/core-site.xml:/opt/hadoop/etc/hadoop/core-site.xml \
    -v ~/hadoop-config/hdfs-site.xml:/opt/hadoop/etc/hadoop/hdfs-site.xml \
    -v ~/hadoop-data/hdfs/namenode:/hadoop/hdfs/namenode \
    -v ~/hadoop-data/hdfs/datanode:/hadoop/hdfs/datanode \
    apache/hadoop:3 tail -f /dev/null

# 等待 Hadoop 容器启动
echo "等待 Hadoop 容器启动 (增加等待时间)..."
sleep 15

# 格式化 HDFS namenode (只在第一次运行时执行)
docker exec hadoop-master bash -c '[ -z "$(ls -A /hadoop/hdfs/namenode)" ] && hdfs namenode -format -nonInteractive || echo "Namenode already formatted."' 

# 启动 HDFS 和 YARN
echo "启动 HDFS 和 YARN 服务..."
docker exec -d hadoop-master start-dfs.sh
docker exec -d hadoop-master start-yarn.sh

# 增加等待时间让服务启动
sleep 10

# 检查 Hadoop 容器日志以帮助诊断
echo "显示 hadoop-master 容器日志:"
docker logs hadoop-master

echo "Hadoop 设置完成，可通过 http://localhost:9870 访问 NameNode Web UI"

# 步骤4：设置 HBase
echo "正在设置 HBase..."

# 拉取 HBase 镜像（使用官方镜像）
docker pull harisekhon/hbase:latest

# 创建 HBase 配置
mkdir -p ~/hbase-config
cat << EOF > ~/hbase-config/hbase-site.xml
<configuration>
    <property>
        <name>hbase.rootdir</name>
        <value>hdfs://hadoop-master:9000/hbase</value>
    </property>
    <property>
        <name>hbase.cluster.distributed</name>
        <value>true</value>
    </property>
    <property>
        <name>hbase.zookeeper.quorum</name>
        <value>hbase-master</value>
    </property>
</configuration>
EOF

# 运行 HBase 容器
docker run -d --name hbase-master \
    --hostname hbase-master \
    --network hadoop-network \
    -p 16010:16010 -p 16000:16000 \
    -v ~/hbase-config/hbase-site.xml:/opt/hbase/conf/hbase-site.xml \
    harisekhon/hbase:latest

# 等待 HBase 容器启动
echo "等待 HBase 容器启动..."
sleep 10

# 启动 HBase
docker exec -d hbase-master start-hbase.sh

echo "HBase 设置完成，可通过 http://localhost:16010 访问 HBase Master Web UI"

# 步骤5：设置 Hive
echo "正在设置 Hive..."

# 拉取 Hive 镜像（使用官方镜像）
docker pull apache/hive:3.1.3

# 创建 Hive 数据目录
mkdir -p ~/hive-data/warehouse

# 创建 Hive 配置
mkdir -p ~/hive-config
cat << EOF > ~/hive-config/hive-site.xml
<configuration>
    <property>
        <name>hive.metastore.warehouse.dir</name>
        <value>/opt/hive/warehouse</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:derby:;databaseName=/opt/hive/metastore_db;create=true</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>org.apache.derby.jdbc.EmbeddedDriver</value>
    </property>
</configuration>
EOF

# 运行 Hive 容器
docker run -d --name hive-server \
    --hostname hive-server \
    --network hadoop-network \
    -p 10000:10000 -p 10002:10002 \
    -v ~/hive-config/hive-site.xml:/opt/hive/conf/hive-site.xml \
    -v ~/hive-data/warehouse:/opt/hive/warehouse \
    apache/hive:3.1.3

# 等待 Hive 容器启动
echo "等待 Hive 容器启动..."
sleep 20

# 初始化 Hive schema
docker exec hive-server schematool -initSchema -dbType derby

echo "Hive 设置完成，可通过 localhost:10000 访问 Hive 服务"

# 步骤6：原生读写测试
echo "正在进行原生读写测试..."

# HDFS 原生读写测试
echo "测试 HDFS 原生读写..."
docker exec hadoop-master bash -c "echo '这是 HDFS 测试数据！' > /tmp/hdfs_test.txt"
docker exec hadoop-master hadoop fs -mkdir -p /user/test
docker exec hadoop-master hadoop fs -put /tmp/hdfs_test.txt /user/test/
docker exec hadoop-master hadoop fs -cat /user/test/hdfs_test.txt

# HBase 原生读写测试
echo "测试 HBase 原生读写..."
docker exec hbase-master bash -c "echo 'create \"test_table\", \"cf\"' | hbase shell"
docker exec hbase-master bash -c "echo 'put \"test_table\", \"row1\", \"cf:col1\", \"HBase 测试数据\"' | hbase shell"
docker exec hbase-master bash -c "echo 'get \"test_table\", \"row1\"' | hbase shell"

# Hive 原生读写测试
echo "测试 Hive 原生读写..."
docker exec hive-server bash -c "echo 'CREATE TABLE test_table (id INT, name STRING);' | beeline -u jdbc:hive2://localhost:10000 -n hive -p hive"
docker exec hive-server bash -c "echo 'INSERT INTO test_table VALUES (1, \"Hive 测试数据\");' | beeline -u jdbc:hive2://localhost:10000 -n hive -p hive"
docker exec hive-server bash -c "echo 'SELECT * FROM test_table;' | beeline -u jdbc:hive2://localhost:10000 -n hive -p hive"

# 步骤7：安装 Python 并进行 Python 读写测试
echo "正在设置 Python 客户端并测试 Python 读写操作..."

# 安装必要的包
sudo apt install -y python3-pip
pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple hdfs happybase pyhive thrift sasl thrift_sasl

# 创建 Python 测试脚本

# HDFS Python 脚本
cat << 'EOF' > ~/hadoop_python_example.py
#!/usr/bin/env python3
from hdfs import InsecureClient

# 连接到 HDFS
hdfs_client = InsecureClient('http://localhost:9870', user='hdfs')

# 写入数据
hdfs_client.write('/user/test/python_test.txt', data='Python 写入 HDFS 的测试数据！')

# 读取数据
with hdfs_client.read('/user/test/python_test.txt') as reader:
    content = reader.read()
    print("从 HDFS 读取:", content.decode('utf-8'))

print("HDFS Python 测试成功完成！")
EOF

# HBase Python 脚本
cat << 'EOF' > ~/hbase_python_example.py
#!/usr/bin/env python3
import happybase

# 连接到 HBase
connection = happybase.Connection('localhost', port=16000)

# 如果表不存在则创建
try:
    connection.create_table(
        'python_test_table',
        {'cf1': dict()}
    )
except Exception as e:
    print("表可能已存在:", e)

# 获取表
table = connection.table('python_test_table')

# 写入数据
table.put(b'row-key-1', {b'cf1:col1': b'Python 写入 HBase 的测试数据！'})

# 读取数据
row = table.row(b'row-key-1')
print("从 HBase 读取:", row[b'cf1:col1'].decode('utf-8'))

connection.close()
print("HBase Python 测试成功完成！")
EOF

# Hive Python 脚本
cat << 'EOF' > ~/hive_python_example.py
#!/usr/bin/env python3
from pyhive import hive

# 连接到 Hive
conn = hive.Connection(host='localhost', port=10000, username='hive')
cursor = conn.cursor()

# 创建表
cursor.execute("DROP TABLE IF EXISTS python_test_table")
cursor.execute("CREATE TABLE python_test_table (id INT, message STRING)")

# 插入数据
cursor.execute("INSERT INTO python_test_table VALUES (1, 'Python 写入 Hive 的测试数据！')")

# 读取数据
cursor.execute("SELECT * FROM python_test_table")
for row in cursor.fetchall():
    print("从 Hive 读取:", row)

conn.close()
print("Hive Python 测试成功完成！")
EOF

# 授予脚本执行权限
chmod +x ~/hadoop_python_example.py ~/hbase_python_example.py ~/hive_python_example.py

# 运行 Python 示例
echo "运行 Python 示例:"
echo "1. HDFS Python 示例:"
python3 ~/hadoop_python_example.py

echo "2. HBase Python 示例:"
python3 ~/hbase_python_example.py

echo "3. Hive Python 示例:"
python3 ~/hive_python_example.py

echo "========== 安装完成！所有 Hadoop 生态系统组件已安装并测试 =========="
echo "您可以通过以下地址访问 Web 界面:"
echo "- Hadoop NameNode: http://localhost:9870"
echo "- Hadoop ResourceManager: http://localhost:8088"
echo "- HBase Master: http://localhost:16010"
echo "- Hive 服务: 通过 JDBC 连接 localhost:10000"