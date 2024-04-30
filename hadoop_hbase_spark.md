# Hadoop HBase Spark 运行实战

## 1 环境运行

### 1.1 启动Hadoop

```bash
start-all.sh
```

### 1.2 启动HBase

```bash
start-hbase.sh
```

### 1.3 启动Spark

```bash
start-all.sh
```

通过访问以下URL来确认这些组件是否已经成功启动：

- Hadoop: http://localhost:9870/
- HBase: http://localhost:16010/
- Spark: http://localhost:4040/

## 2 Python使用

以下是使用Python操作HDFS，HBase和Spark的示例代码。

首先，我们需要安装一些必要的库，包括`hdfs`, `happybase`, `pyspark`，`seaborn`和`pandas`以及`scikit-learn`。

```bash
pip install hdfs happybase pyspark seaborn pandas scikit-learn --break-system-packages
```

### 2.1. 使用HDFS

我们可以使用`hdfs`库来操作HDFS。以下是一个简单的例子，它将一个本地文件上传到HDFS：

```python
from hdfs import InsecureClient

client = In

secure

Client('http://localhost:9870', user='hadoop')
local_path = '/path/to/local/file'
hdfs_path = '/path/to/hdfs/directory'

# Upload local file to HDFS
client.upload(hdfs_path, local_path)
```

### 2.2. 使用HBase

我们可以使用`happybase`库来操作HBase。以下是一个简单的例子，它在HBase中创建一个表：

```python
import happybase

connection = happybase.Connection('localhost')
connection.open()

table_name = 'my_table'
families = {
    'cf1': dict(max_versions=10),
    'cf2': dict(max_versions=1, block_cache_enabled=False),
    'cf3': dict(),  # Use defaults
}

# Create table
connection.create_table(table_name, families)
```

### 2.3. 使用Spark

我们可以使用`pyspark`库来操作Spark。以下是一个简单的例子，它在Spark中创建一个RDD并进行一些操作：

```python
from pyspark import SparkContext

sc = SparkContext("local", "First App")

# Create RDD
data = [1, 2, 3, 4, 5]
rdd = sc.parallelize(data)

# Perform operation on RDD
rdd = rdd.map(lambda x: x * 2)
result = rdd.collect()

print(result)  # Output: [2, 4, 6, 8, 10]
```

## 3 Iris数据写入和读取

以下是一个Python脚本的示例，它将Iris数据集写入到Hadoop的HDFS中，然后在HBase中创建对应的表，并使用Spark进行数据读取和简单的可视化。


然后，我们可以编写以下Python脚本：

```python
from hdfs import InsecureClient
import happybase
from pyspark import SparkContext, SparkConf
from pyspark.sql import SparkSession
from sklearn import datasets
import pandas as pd
import seaborn as sns
import io

# 1. Load Iris dataset from sklearn
iris = datasets.load_iris()
iris_df = pd.DataFrame(data=iris.data, columns=iris.feature_names)
iris_df['target'] = iris.target

# Write Iris dataset to HDFS
client = InsecureClient('http://localhost:9870', user='hadoop')
with client.write('/iris.csv') as writer:
    iris_df.to_csv(writer)

# 2. Create table in HBase
connection = happybase.Connection('localhost')
connection.open()

table_name = 'iris'
families = {
    'sepal': dict(),
    'petal': dict(),
    'species': dict(),
}

# Create table
connection.create_table(table_name, families)

# 3. Use Spark to read data and visualize
conf = SparkConf().setAppName("IrisApp").setMaster("local")
sc = SparkContext(conf=conf)
spark = SparkSession(sc)

# Read data from HDFS
df = spark.read.csv("hdfs://localhost:9870/iris.csv", inferSchema=True, header=True)

# Convert Spark DataFrame to Pandas DataFrame for visualization
pandas_df = df.toPandas()

# Visualize data
sns.pairplot(pandas_df, hue="target")
```

这个脚本首先将本地的Iris数据集上传到HDFS，然后在HBase中创建一个名为`iris`的表，最后使用Spark读取HDFS中的数据，并使用seaborn库进行可视化。

请注意，你需要替换`/path/to/iris.csv`为你本地Iris数据集的实际路径。此外，这个脚本假设你的Hadoop，HBase和Spark都运行在本地，并且使用默认的端口。如果你的设置不同，你需要相应地修改这个脚本。