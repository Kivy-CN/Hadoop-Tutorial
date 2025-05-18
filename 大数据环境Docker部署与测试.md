# 大数据环境Docker部署与测试

下面将提供一个完整的解决方案，包括：
1. Docker Compose配置文件，用于部署Hadoop、HBase、Hive、Spark、Kafka和Flink
2. Python测试脚本，用于验证每个组件的功能

## 1. Docker Compose配置文件

首先创建一个`docker-compose.yml`文件:

````yaml
version: '3'

services:
  namenode:
    image: apache/hadoop:3.3.6
    container_name: namenode
    hostname: namenode
    restart: always
    ports:
      - 9870:9870
      - 9000:9000
    volumes:
      - hadoop_namenode:/hadoop/dfs/name
    environment:
      - ENSURE_NAMENODE_DIR=/hadoop/dfs/name
      - CLUSTER_NAME=hadoop-cluster
    env_file:
      - ./hadoop.env
    command: ["hdfs", "namenode"]
    networks:
      - bigdata_network

  datanode:
    image: apache/hadoop:3.3.6
    container_name: datanode
    restart: always
    depends_on:
      - namenode
    volumes:
      - hadoop_datanode:/hadoop/dfs/data
    environment:
      - SERVICE_PRECONDITION=namenode:9870
      - CORE_CONF_fs_defaultFS=hdfs://namenode:9000
    env_file:
      - ./hadoop.env
    command: ["hdfs", "datanode"]
    networks:
      - bigdata_network
  
  resourcemanager:
    image: apache/hadoop:3.3.6
    container_name: resourcemanager
    hostname: resourcemanager
    restart: always
    depends_on:
      - namenode
    ports:
      - 8088:8088
    environment:
      - SERVICE_PRECONDITION=namenode:9000 namenode:9870
      - CORE_CONF_fs_defaultFS=hdfs://namenode:9000
    env_file:
      - ./hadoop.env
    command: ["yarn", "resourcemanager"]
    networks:
      - bigdata_network

  nodemanager:
    image: apache/hadoop:3.3.6
    container_name: nodemanager
    restart: always
    depends_on:
      - resourcemanager
    environment:
      - SERVICE_PRECONDITION=resourcemanager:8088
      - CORE_CONF_fs_defaultFS=hdfs://namenode:9000
    env_file:
      - ./hadoop.env
    command: ["yarn", "nodemanager"]
    networks:
      - bigdata_network

  historyserver:
    image: apache/hadoop:3.3.6
    container_name: historyserver
    restart: always
    depends_on:
      - namenode
      - resourcemanager
    environment:
      - SERVICE_PRECONDITION=resourcemanager:8088
      - CORE_CONF_fs_defaultFS=hdfs://namenode:9000
    volumes:
      - hadoop_historyserver:/hadoop/yarn/timeline
    env_file:
      - ./hadoop.env
    command: ["mapred", "historyserver"]
    networks:
      - bigdata_network

  hbase-master:
    image: apache/hbase:2.5.5
    container_name: hbase-master
    hostname: hbase-master
    depends_on:
      - namenode
      - datanode
      - zookeeper
    environment:
      - HBASE_CONF_hbase_rootdir=hdfs://namenode:9000/hbase
      - HBASE_CONF_hbase_cluster_distributed=true
      - HBASE_CONF_hbase_zookeeper_quorum=zookeeper
    ports:
      - 16000:16000
      - 16010:16010
    networks:
      - bigdata_network

  hbase-regionserver:
    image: apache/hbase:2.5.5
    container_name: hbase-regionserver
    hostname: hbase-regionserver
    depends_on:
      - hbase-master
      - zookeeper
    environment:
      - HBASE_CONF_hbase_rootdir=hdfs://namenode:9000/hbase
      - HBASE_CONF_hbase_cluster_distributed=true
      - HBASE_CONF_hbase_zookeeper_quorum=zookeeper
    ports:
      - 16030:16030
    networks:
      - bigdata_network

  metastore-db:
    image: postgres:15.4
    container_name: metastore-db
    environment:
      - POSTGRES_PASSWORD=hive
      - POSTGRES_USER=hive
      - POSTGRES_DB=metastore
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - bigdata_network

  hive-metastore:
    image: apache/hive:3.1.3
    container_name: hive-metastore
    hostname: hive-metastore
    depends_on:
      - namenode
      - datanode
      - metastore-db
    environment:
      - DB_DRIVER=postgres
      - DB_CONNECTION_URL=jdbc:postgresql://metastore-db:5432/metastore
      - DB_USER=hive
      - DB_PASS=hive
      - FS_DEFAULT_NAME=hdfs://namenode:9000
    ports:
      - "9083:9083"
    command: /opt/hive/bin/hive --service metastore
    networks:
      - bigdata_network

  hive-server:
    image: apache/hive:3.1.3
    container_name: hive-server
    hostname: hive-server
    depends_on:
      - hive-metastore
    environment:
      - HIVE_METASTORE_URI=thrift://hive-metastore:9083
      - FS_DEFAULT_NAME=hdfs://namenode:9000
    ports:
      - "10000:10000"
      - "10002:10002"
    command: /opt/hive/bin/hive --service hiveserver2
    networks:
      - bigdata_network

  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.1
    container_name: zookeeper
    hostname: zookeeper
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    networks:
      - bigdata_network

  kafka:
    image: confluentinc/cp-kafka:7.5.1
    container_name: kafka
    hostname: kafka
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
      - "29092:29092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092,PLAINTEXT_HOST://localhost:29092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"
    networks:
      - bigdata_network

  spark-master:
    image: apache/spark:3.5.0
    container_name: spark-master
    hostname: spark-master
    environment:
      - SPARK_MODE=master
      - SPARK_MASTER_HOST=spark-master
      - SPARK_MASTER_PORT=7077
      - SPARK_MASTER_WEBUI_PORT=8080
    ports:
      - "8080:8080"
      - "7077:7077"
    networks:
      - bigdata_network

  spark-worker:
    image: apache/spark:3.5.0
    container_name: spark-worker
    depends_on:
      - spark-master
    environment:
      - SPARK_MODE=worker
      - SPARK_MASTER_URL=spark://spark-master:7077
      - SPARK_WORKER_WEBUI_PORT=8081
      - SPARK_WORKER_MEMORY=1G
      - SPARK_WORKER_CORES=1
    ports:
      - "8081:8081"
    networks:
      - bigdata_network

  jobmanager:
    image: flink:1.18.1-scala_2.12
    container_name: jobmanager
    hostname: jobmanager
    ports:
      - "8083:8081"
    command: jobmanager
    environment:
      - JOB_MANAGER_RPC_ADDRESS=jobmanager
      - |
        FLINK_PROPERTIES=
        jobmanager.rpc.address: jobmanager
        state.backend: filesystem
        state.checkpoints.dir: file:///tmp/flink-checkpoints
        heartbeat.interval: 1000
        heartbeat.timeout: 5000
    networks:
      - bigdata_network

  taskmanager:
    image: flink:1.18.1-scala_2.12
    container_name: taskmanager
    depends_on:
      - jobmanager
    command: taskmanager
    environment:
      - JOB_MANAGER_RPC_ADDRESS=jobmanager
      - |
        FLINK_PROPERTIES=
        jobmanager.rpc.address: jobmanager
        taskmanager.numberOfTaskSlots: 2
        state.backend: filesystem
        state.checkpoints.dir: file:///tmp/flink-checkpoints
        heartbeat.interval: 1000
        heartbeat.timeout: 5000
    networks:
      - bigdata_network

networks:
  bigdata_network:
    driver: bridge

volumes:
  hadoop_namenode:
  hadoop_datanode:
  hadoop_historyserver:
  postgres_data:
````

创建Hadoop环境变量文件 nano ./hadoop.env：

````text
CORE_CONF_fs_defaultFS=hdfs://namenode:9000
CORE_CONF_hadoop_http_staticuser_user=root
CORE_CONF_hadoop_proxyuser_hue_hosts=*
CORE_CONF_hadoop_proxyuser_hue_groups=*
CORE_CONF_io_compression_codecs=org.apache.hadoop.io.compress.SnappyCodec

HDFS_CONF_dfs_webhdfs_enabled=true
HDFS_CONF_dfs_permissions_enabled=false
HDFS_CONF_dfs_namenode_datanode_registration_ip___hostname___check=false

YARN_CONF_yarn_log___aggregation___enable=true
YARN_CONF_yarn_resourcemanager_recovery_enabled=true
YARN_CONF_yarn_resourcemanager_store_class=org.apache.hadoop.yarn.server.resourcemanager.recovery.FileSystemRMStateStore
YARN_CONF_yarn_resourcemanager_system___metrics___publisher_enabled=true
YARN_CONF_yarn_resourcemanager_hostname=resourcemanager
YARN_CONF_yarn_timeline___service_enabled=true
YARN_CONF_yarn_timeline___service_generic___application___history_enabled=true
YARN_CONF_yarn_timeline___service_hostname=historyserver
YARN_CONF_yarn_resourcemanager_address=resourcemanager:8032
YARN_CONF_yarn_resourcemanager_scheduler_address=resourcemanager:8030
YARN_CONF_yarn_resourcemanager_resource__tracker_address=resourcemanager:8031
````

## 2. Python测试脚本

创建一个Python测试脚本，用于测试所有组件：

````python
import os
import time
import findspark
findspark.init()  # 初始化Spark环境

import pandas as pd
from pyspark.sql import SparkSession
from hdfs import InsecureClient
from pywebhdfs.webhdfs import PyWebHdfsClient
from hive_service.ttypes import HiveServerException
from thrift.transport import TSocket
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol
from hive_service import ThriftHive
from kafka import KafkaProducer, KafkaConsumer
import happybase
import requests

def test_hadoop():
    print("=== Testing Hadoop HDFS ===")
    try:
        # 使用WebHDFS API
        hdfs_client = PyWebHdfsClient(host='localhost', port='9870', user_name='root')
        
        # 创建一个测试目录
        try:
            hdfs_client.make_dir('test_dir')
            print("Successfully created directory in HDFS")
        except:
            print("Directory might already exist")
            
        # 创建一个测试文件
        test_content = "Hello Hadoop!"
        with open("test_file.txt", "w") as f:
            f.write(test_content)
            
        # 上传文件到HDFS
        hdfs_client.create_file('test_dir/test_file.txt', test_content, overwrite=True)
        print("Successfully uploaded file to HDFS")
        
        # 读取文件内容
        file_content = hdfs_client.read_file('test_dir/test_file.txt')
        print(f"Read from HDFS: {file_content}")
        
        print("Hadoop HDFS test completed successfully!")
    except Exception as e:
        print(f"Error testing Hadoop: {str(e)}")

def test_hbase():
    print("\n=== Testing HBase ===")
    try:
        # 连接HBase
        connection = happybase.Connection('localhost', 16010)
        print("Connected to HBase")
        
        # 获取表列表
        tables = connection.tables()
        print(f"Existing tables: {tables}")
        
        # 创建测试表
        try:
            connection.create_table('test_table', {'cf1': dict()})
            print("Created test_table")
        except Exception as e:
            print(f"Table might already exist: {e}")
        
        # 获取表并插入数据
        table = connection.table('test_table')
        table.put(b'row1', {b'cf1:col1': b'value1'})
        print("Inserted data into test_table")
        
        # 读取数据
        row = table.row(b'row1')
        print(f"Read from HBase: {row}")
        
        print("HBase test completed successfully!")
    except Exception as e:
        print(f"Error testing HBase: {str(e)}")

def test_hive():
    print("\n=== Testing Hive ===")
    try:
        # 连接到Hive Server
        transport = TSocket.TSocket('localhost', 10000)
        transport = TTransport.TBufferedTransport(transport)
        protocol = TBinaryProtocol.TBinaryProtocol(transport)
        client = ThriftHive.Client(protocol)
        
        transport.open()
        print("Connected to Hive")
        
        # 执行HQL查询
        client.execute("SHOW DATABASES")
        databases = client.fetchAll()
        print(f"Hive databases: {databases}")
        
        # 创建测试表
        client.execute("CREATE DATABASE IF NOT EXISTS test_db")
        client.execute("USE test_db")
        client.execute("CREATE TABLE IF NOT EXISTS test_table (id INT, name STRING)")
        print("Created test database and table in Hive")
        
        # 插入数据
        client.execute("INSERT INTO test_table VALUES (1, 'test_name')")
        print("Inserted data into Hive table")
        
        # 查询数据
        client.execute("SELECT * FROM test_table")
        result = client.fetchAll()
        print(f"Query result: {result}")
        
        transport.close()
        print("Hive test completed successfully!")
    except Exception as e:
        print(f"Error testing Hive: {str(e)}")

def test_spark():
    print("\n=== Testing Spark ===")
    try:
        # 创建SparkSession
        spark = SparkSession.builder \
            .appName("PythonSparkTest") \
            .master("spark://spark-master:7077") \
            .getOrCreate()
        
        print(f"Spark version: {spark.version}")
        
        # 创建简单的DataFrame
        data = [("Java", 1000), ("Python", 2000), ("Scala", 3000)]
        df = spark.createDataFrame(data, ["language", "users"])
        
        # 执行一些操作
        df.show()
        df.printSchema()
        
        # 简单的SQL查询
        df.createOrReplaceTempView("programming_languages")
        sql_df = spark.sql("SELECT * FROM programming_languages WHERE users > 1500")
        sql_df.show()
        
        # 停止SparkSession
        spark.stop()
        print("Spark test completed successfully!")
    except Exception as e:
        print(f"Error testing Spark: {str(e)}")

def test_kafka():
    print("\n=== Testing Kafka ===")
    try:
        # 创建Kafka producer
        producer = KafkaProducer(bootstrap_servers='kafka:9092')
        print("Created Kafka producer")
        
        # 发送消息
        topic = 'test'
        message = b'Hello Kafka!'
        producer.send(topic, message)
        producer.flush()
        print(f"Sent message to Kafka topic '{topic}'")
        
        # 创建消费者
        consumer = KafkaConsumer(
            topic,
            bootstrap_servers=['kafka:9092'],
            auto_offset_reset='earliest',
            group_id='test-group'
        )
        
        print("Waiting for messages...")
        # 设置超时，以防止无限等待
        start_time = time.time()
        message_received = False
        
        while time.time() - start_time < 10:  # 10秒超时
            msg_pack = consumer.poll(timeout_ms=1000)
            if msg_pack:
                for _, messages in msg_pack.items():
                    for message in messages:
                        print(f"Received message: {message.value}")
                        message_received = True
                        break
            
            if message_received:
                break
        
        print("Kafka test completed successfully!")
    except Exception as e:
        print(f"Error testing Kafka: {str(e)}")

def test_flink():
    print("\n=== Testing Flink ===")
    try:
        # 通过Flink REST API检查Flink集群状态
        response = requests.get('http://localhost:8083/overview')
        if response.status_code == 200:
            overview = response.json()
            print(f"Flink version: {overview.get('flink-version')}")
            print(f"Flink jobs running: {overview.get('jobs-running')}")
            print("Flink cluster is running!")
        else:
            print(f"Failed to connect to Flink REST API: {response.status_code}")
            
        print("Flink test completed!")
    except Exception as e:
        print(f"Error testing Flink: {str(e)}")

if __name__ == "__main__":
    print("Starting big data components tests...\n")
    
    # 首先等待所有服务启动
    print("Waiting for services to be fully initialized (30 seconds)...")
    time.sleep(30)
    
    # 测试各个组件
    test_hadoop()
    test_hbase()
    test_hive()
    test_spark()  
    test_kafka()
    test_flink()
    
    print("\nAll tests completed!")
````

## 3. 运行指南

1. 安装必要的Python依赖

````bash
pip install pyspark hdfs pywebhdfs happybase thrift kafka-python findspark pandas requests
````

2. 启动Docker容器集群

````bash
sudo docker-compose up -d
````

3. 等待所有服务启动（约2-5分钟）

4. 运行测试脚本

````bash
python test_bigdata_components.py
````

## 4. 系统架构说明

这个大数据处理环境包含以下组件，它们之间的协作关系如下：

1. **Hadoop生态系统**:
   - NameNode: HDFS的主节点，管理文件系统命名空间
   - DataNode: 存储数据的工作节点
   - ResourceManager: YARN资源管理器
   - NodeManager: YARN资源的工作节点
   - HistoryServer: 存储和展示已完成的MapReduce任务

2. **HBase**:
   - HBase Master: 负责管理HBase集群
   - RegionServer: 存储和处理HBase数据的服务器
   - 依赖于Hadoop HDFS存储数据，依赖ZooKeeper进行协调

3. **Hive**:
   - Metastore: 存储元数据的服务
   - HiveServer2: 提供JDBC/ODBC接口
   - 依赖PostgreSQL作为元数据库
   - 使用HDFS进行数据存储

4. **Spark**:
   - Master: 集群管理器
   - Worker: 执行任务的工作节点
   - 可以与Hadoop HDFS、Hive集成

5. **Kafka**:
   - Broker: 处理和存储消息
   - 依赖ZooKeeper进行协调

6. **Flink**:
   - JobManager: 协调分布式执行
   - TaskManager: 执行任务的工作节点
   - 可以与Hadoop、Kafka集成

所有组件通过Docker网络`bigdata_network`互连，确保它们可以相互通信。

## 5. 注意事项

1. **系统要求**:
   - 至少8GB RAM
   - 至少20GB可用磁盘空间
   - Docker和Docker Compose安装正确
   - Windows用户需配置Docker Desktop资源限制

2. **可能的问题和解决方案**:
   - 端口冲突: 如果本地已有应用占用这些端口，可以在`docker-compose.yml`中修改
   - 内存不足: 可能导致容器崩溃，增加Docker内存限制或减少服务数量
   - 网络问题: 测试脚本中某些地方使用`localhost`，而另一些使用容器名称，可能需要根据实际情况调整

3. **维护操作**:
   - 停止所有容器: `docker-compose down`
   - 保留数据并停止容器: `docker-compose stop`
   - 查看容器日志: `docker logs <container_name>`
   - 重启单个服务: `docker-compose restart <service_name>`

4. **数据持久化**:
   - 数据存储在Docker卷中: `hadoop_namenode`, `hadoop_datanode`, `hadoop_historyserver`, `postgres_data`
   - 删除这些卷将清除所有数据

5. **安全性说明**:
   - 此设置适合开发和测试环境，未启用任何安全特性
   - 生产环境需要额外的安全配置，如认证、授权和加密

## 6. Web界面访问

以下是各组件Web界面的访问地址:

- Hadoop NameNode: http://localhost:9870
- Hadoop YARN ResourceManager: http://localhost:8088
- HBase Master: http://localhost:16010
- Spark Master: http://localhost:8080
- Flink JobManager: http://localhost:8083

至此上面提供了一个完整的大数据处理环境，各组件已配置为可以相互通信，适合本地开发和测试。

