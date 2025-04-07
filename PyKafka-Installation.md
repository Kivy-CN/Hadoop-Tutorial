# Ubuntu 24.04 PyKafka 安装脚本

下面是在 Ubuntu 24.04 上安装 PyKafka 及其依赖的完整脚本，使用中国大陆地区易于访问的镜像源：

````bash
#!/bin/bash
# filepath: install_pykafka.sh

set -e
echo "开始安装 PyKafka 及其依赖..."

# 更新apt源为国内镜像
echo "更新apt源为清华大学镜像..."
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
sudo bash -c 'cat > /etc/apt/sources.list << EOF
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-security main restricted universe multiverse
EOF'

# 更新软件包列表
sudo apt update

# 安装基础依赖
echo "安装基础依赖..."
sudo apt install -y python3 python3-pip python3-dev build-essential librdkafka-dev openjdk-17-jdk wget unzip

# 配置pip使用国内镜像
echo "配置pip使用清华大学镜像..."
mkdir -p ~/.pip
cat > ~/.pip/pip.conf << EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF

# 安装pykafka及其依赖
echo "安装pykafka及其依赖..."
pip3 install --upgrade pip
pip3 install pykafka
pip3 install kafka-python confluent-kafka

# 安装并配置Kafka
echo "下载并安装Kafka..."
cd /tmp
wget https://mirrors.tuna.tsinghua.edu.cn/apache/kafka/4.0.0/kafka_2.13-4.0.0.tgz
tar -xzf kafka_2.13-4.0.0.tgz
sudo mv kafka_2.13-4.0.0 /opt/kafka

# 创建Kafka服务单元
echo "创建Kafka服务..."
sudo bash -c 'cat > /etc/systemd/system/zookeeper.service << EOF
[Unit]
Description=Apache Zookeeper server
Documentation=http://zookeeper.apache.org
Requires=network.target remote-fs.target
After=network.target remote-fs.target

[Service]
Type=simple
ExecStart=/opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties
ExecStop=/opt/kafka/bin/zookeeper-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF'

sudo bash -c 'cat > /etc/systemd/system/kafka.service << EOF
[Unit]
Description=Apache Kafka Server
Documentation=http://kafka.apache.org/documentation.html
Requires=zookeeper.service
After=zookeeper.service

[Service]
Type=simple
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64"
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF'

# 启动Kafka服务
echo "启动Kafka服务..."
sudo systemctl daemon-reload
sudo systemctl enable zookeeper.service
sudo systemctl enable kafka.service
sudo systemctl start zookeeper.service
sudo systemctl start kafka.service

# 验证安装
echo "验证Kafka安装..."
sleep 10
sudo systemctl status zookeeper.service --no-pager
sudo systemctl status kafka.service --no-pager

echo "创建测试主题..."
/opt/kafka/bin/kafka-topics.sh --create --topic test-topic --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1

# 创建简单的Python测试脚本
echo "创建Python测试脚本..."
cat > ~/test_kafka.py << EOF
from kafka import KafkaProducer, KafkaConsumer
import threading
import time

def produce_messages():
    producer = KafkaProducer(bootstrap_servers=['localhost:9092'])
    for i in range(5):
        message = f"测试消息 {i}".encode('utf-8')
        producer.send('test-topic', message)
        print(f"已发送: {message.decode('utf-8')}")
        time.sleep(1)
    producer.close()

def consume_messages():
    consumer = KafkaConsumer('test-topic', bootstrap_servers=['localhost:9092'],
                             auto_offset_reset='earliest',
                             group_id='test-group')
    count = 0
    for message in consumer:
        print(f"已接收: {message.value.decode('utf-8')}")
        count += 1
        if count >= 5:
            break
    consumer.close()

if __name__ == "__main__":
    print("启动Kafka测试...")
    # 先启动消费者线程
    consumer_thread = threading.Thread(target=consume_messages)
    consumer_thread.start()
    
    # 等待消费者准备就绪
    time.sleep(2)
    
    # 启动生产者
    produce_messages()
    
    # 等待消费者完成
    consumer_thread.join()
    print("测试完成!")
EOF

echo "===================================="
echo "安装完成! 运行以下命令测试Kafka:"
echo "python3 ~/test_kafka.py"
echo "===================================="
````

## 使用说明

1. 保存脚本为 `install_pykafka.sh`
2. 添加执行权限：`chmod +x install_pykafka.sh`
3. 运行脚本：`./install_pykafka.sh`

脚本完成后，将自动安装所有依赖，配置服务，并创建一个测试脚本。可以运行 `python3 ~/test_kafka.py` 测试安装是否成功。

此脚本使用了清华大学的镜像源，这是中国大陆地区最稳定快速的镜像之一。如有需要，可以替换为其他国内镜像如阿里云、中科大等。
