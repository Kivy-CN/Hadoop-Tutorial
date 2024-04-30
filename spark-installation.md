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

# Spark的使用

在运行起来Hadoop和Spark之后，先往Hadoop的HDFS上传一份input.txt文件：

```Python
import os
import random
import string

# 生成一个随机的字符串
random_string = ''.join(random.choices(string.ascii_letters + string.digits, k=100))

# 将字符串保存到一个文本文件中
with open('input.txt', 'w') as f:
    f.write(random_string)

# 将文本文件上传到 HDFS
os.system('hadoop fs -put input.txt /input.txt')
```

在 Python 中使用 Spark，需要使用 PySpark 库。以下是一个简单的例子，这个例子使用 Spark 读取一个文本文件，然后计算文件中每个单词的出现次数：

```python
from pyspark import SparkContext, SparkConf

# 创建 SparkConf 和 SparkContext
conf = SparkConf().setAppName("wordCountApp")
sc = SparkContext(conf=conf)

# 读取输入文件
text_file = sc.textFile("hdfs://localhost:9000/input.txt")

# 使用 flatMap 分割行为单词，然后使用 map 将每个单词映射为一个 (word, 1) 对，最后使用 reduceByKey 对所有的 (word, 1) 对进行合并
counts = text_file.flatMap(lambda line: line.split(" ")) \
             .map(lambda word: (word, 1)) \
             .reduceByKey(lambda a, b: a + b)

# 将结果保存到输出文件
counts.saveAsTextFile("hdfs://localhost:9000/output.txt")
```

在这个例子中，首先创建了一个 SparkConf 对象和一个 SparkContext 对象。然后，使用 SparkContext 的 `textFile` 方法读取输入文件。接下来，使用 `flatMap`、`map` 和 `reduceByKey` 方法处理数据。最后，使用 `saveAsTextFile` 方法将结果保存到输出文件。

请注意，需要将 "hdfs://localhost:9000/input.txt" 和 "hdfs://localhost:9000/output.txt" 替换为实际输入文件和输出文件的路径。
