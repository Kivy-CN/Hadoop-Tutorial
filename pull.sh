#!/bin/bash

echo "Pulling all required docker images..."

# Hadoop images
echo "Pulling Hadoop images..."
sudo docker pull docker.1ms.run/apache/hadoop|| { echo "Failed to pull Hadoop image"; exit 1; }

# HBase images - using harisekhon/hbase which is a well-maintained alternative
echo "Pulling HBase images..."
sudo docker pull docker.1ms.run/harisekhon/hbase || { echo "Failed to pull HBase image"; exit 1; }

# PostgreSQL for Hive metastore
echo "Pulling PostgreSQL image..."
sudo docker pull docker.1ms.run/postgres|| { echo "Failed to pull PostgreSQL image"; exit 1; }

# Hive images
echo "Pulling Hive images..."
sudo docker pull docker.1ms.run/apache/hive|| { echo "Failed to pull Hive image"; exit 1; }

# ZooKeeper image
echo "Pulling ZooKeeper image..."
sudo docker pull docker.1ms.run/confluentinc/cp-zookeeper|| { echo "Failed to pull ZooKeeper image"; exit 1; }

# Kafka image
echo "Pulling Kafka image..."
sudo docker pull docker.1ms.run/confluentinc/cp-kafka || { echo "Failed to pull Kafka image"; exit 1; }

# Spark images
echo "Pulling Spark images..."
sudo docker pull docker.1ms.run/apache/spark|| { echo "Failed to pull Spark image"; exit 1; }

# Flink images
echo "Pulling Flink images..."
sudo docker pull docker.1ms.run/flink || { echo "Failed to pull Flink image"; exit 1; }

echo "All images pulled successfully!"

# Verify all images are available
echo "Verifying images..."
sudo docker images | grep -E 'apache/hadoop|harisekhon/hbase|postgres|apache/hive|confluentinc/cp-zookeeper|confluentinc/cp-kafka|apache/spark|flink'