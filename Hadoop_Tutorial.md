# 分布式与并行计算


# 1. 大数据和分布式系统

## 1.1. 大数据的基础概念

大数据是指在传统数据处理软件难以处理的大量、复杂的数据集。关于“多大才算大数据”，并没有一个明确的标准。当数据的规模、复杂性和处理速度超过了现有单台设备的处理能力，那么这就可以被认为是大数据。

简单来看，可以认为大数据有两个方面的问题：
* 数据规模太大，不好存储；
* 数据过于复杂，不好计算。

针对大数据的存储与计算，就要用到分布式系统。当前的分布式系统基本上是由分布式存储和分布式并行计算两部分组成。

分布式存储是指将数据存储在分布式网络中的计算机系统。

分布式并行计算是指将计算任务分配给分布式网络中的多个计算机并行计算，以提高计算效率。

## 1.2. 传统的数据存储

要明白分布式存储的必要性，需要先回顾一下传统的数据存储。

### 1.2.1 计算机存储信息的常见媒介

**光信号存储**

**光盘（CD/DVD/Blu-ray）**是一种光学存储媒介，通过激光束来读取和写入数据。光盘的优点是成本低，便于携带，且数据的存储寿命长。但是，光盘的存储容量相对较小，且读写速度较慢。

**磁信号存储**

**软盘（Floppy Disk）**：
- 存储容量：早期的软盘存储容量很小，通常在1.44MB左右。
- 读写速度：相对较慢。
- 成本：由于技术已经过时，现在很难找到新的软盘和驱动器，所以成本可能会相对较高。
- 用途：在现代计算中，软盘已经很少使用，主要用于老旧设备或特定的工业设备。

**磁带（Magnetic Tape）**：
- 存储容量：磁带的存储容量可以非常大，适合用于大规模的数据备份和归档。
- 读写速度：磁带的读写速度较慢，且只能顺序访问数据。
- 成本：磁带的成本相对较低，尤其是在大规模数据存储中。
- 用途：磁带主要用于数据备份和长期存储。

**机械硬盘（Hard Disk Drive, HDD）**：
- 存储容量：机械硬盘的存储容量可以非常大，现在常见的硬盘容量可以达到数TB。
- 读写速度：机械硬盘的读写速度相对较慢，因为它依赖于磁头和磁盘的物理移动。
- 成本：机械硬盘的成本相对较低，尤其是在每GB的存储成本上。
- 用途：机械硬盘广泛用于个人计算机和服务器，用于存储操作系统、应用程序和用户数据。

**电信号存储**

电信号存储媒介，如SD卡和固态硬盘（SSD），主要有以下特点：

**SD卡（Secure Digital Card）**：
- 存储容量：SD卡的存储容量可以从几MB到几TB不等。
- 读写速度：SD卡的读写速度相对较快，尤其是高级别的SD卡。
- 成本：SD卡的成本相对较低，但是高容量和高速度的SD卡成本会更高。
- 用途：SD卡主要用于便携设备，如相机、手机等，用于存储照片、视频和其他数据。

**固态硬盘（Solid State Drive, SSD）**：
- 存储容量：SSD的存储容量可以从几GB到几TB不等。
- 读写速度：SSD的读写速度非常快，远超过机械硬盘。
- 成本：SSD的成本相对较高，尤其是在每GB的存储成本上。
- 用途：SSD主要用于个人计算机和服务器，用于存储操作系统、应用程序和用户数据，提供快速的启动和加载时间。

### 1.2.2 单盘位存储

单盘位存储的容量上限主要取决于存储设备的类型。例如，截至目前（2023年），民用市场上常见的机械硬盘（HDD）的单盘位存储容量可以达到16TB甚至更高，而固态硬盘（SSD）的单盘位存储容量也可以达到4TB或更高。

单盘位存储的优势和劣势包括：

**优势**：
- **安装简单**：单盘位存储的管理和维护相对简单，不需要复杂的配置或管理工具。
- **迁移灵活**：对于单个用户或应用，单盘位存储拆装灵活，换盘到另一台机器上即可，无需考虑数据的复杂迁移问题。
- **成本低廉**：单盘位存储的成本相对较低，价格便宜。

**劣势**：
- **难以扩展**：单盘位存储的容量受到物理限制，如果需要更多的存储空间，可能需要更换更大的硬盘或添加额外的硬盘。
- **可靠性低**：如果单个硬盘发生故障，可能会导致数据丢失。因此，需要定期备份数据以防止数据丢失。
- **性能瓶颈**：对于需要高并发读写的应用，单盘位存储可能会成为性能瓶颈。

因此，面对单盘存不下等场景，就要考虑多盘位存储。

### 1.2.3 多盘位存储

**JBOD（Just a Bunch Of Disks）**：
- 特点：JBOD是将多个磁盘组合在一起，作为一个大的存储空间。每个磁盘独立工作，不提供冗余或性能增强。
- 优点：简单，全盘容量可用。
- 缺点：没有冗余，任何一个磁盘的故障都可能导致数据丢失。

**RAID 0（Striping）**：
- 特点：RAID 0将数据分割成块，均匀地分布在两个或更多的磁盘上，没有冗余。
- 优点：读写性能优秀，全盘容量可用。
- 缺点：没有冗余，任何一个磁盘的故障都会导致所有数据丢失。

**RAID 1（Mirroring）**：
- 特点：RAID 1将相同的数据写入两个磁盘，提供一份冗余。
- 优点：读性能优秀，提供冗余，一个磁盘故障不会导致数据丢失。
- 缺点：写性能一般，只有一半的总容量可用。

**RAID 5（Striping with Parity）**：
- 特点：RAID 5将数据和校验信息分布在三个或更多的磁盘上。
- 优点：读写性能优秀，提供冗余，一个磁盘故障不会导致数据丢失。
- 缺点：写性能受校验计算影响，恢复数据时性能下降。

**RAID 10（Striping + Mirroring）**：
- 特点：RAID 10是RAID 0和RAID 1的组合，提供冗余和性能增强。
- 优点：读写性能优秀，提供冗余，一个或多个磁盘故障（取决于故障磁盘的位置和数量）不会导致数据丢失。
- 缺点：只有一半的总容量可用。

**RAIDZ（ZFS RAID）**：
- 特点：RAIDZ是ZFS文件系统的RAID实现，提供单校验（RAIDZ1）、双校验（RAIDZ2）和三校验（RAIDZ3）的选项。
- 优点：读写性能优秀，提供冗余，一个、两个或三个磁盘故障（取决于RAIDZ级别）不会导致数据丢失，避免了RAID 5的"写孔"问题。
- 缺点：写性能受校验计算影响，恢复数据时性能下降，需要ZFS文件系统支持。


### 1.2.4 Ubuntu下创建 RAID


以下是在 Ubuntu 中安装 Webmin 的步骤：


1. 首先，下载 Webmin 的 Debian 包。可以在 Webmin 的官方网站找到下载链接，或者直接在终端中使用以下命令下载：


```bash

wget http://prdownloads.sourceforge.net/webadmin/webmin_1.973_all.deb

```


2. 下载完成后，使用 dpkg 命令安装 Webmin：


```bash

sudo dpkg -i webmin_1.973_all.deb

```


3. dpkg 可能无法解决 Webmin 的所有依赖关系，可以使用 apt 命令来安装剩余的依赖：


```bash

sudo apt-get install -f

```


4. 安装完成后，可以在浏览器中通过 https://localhost:10000 访问 Webmin。请使用 Ubuntu 用户名和密码登录。


在 "Linux RAID" 页面中，可以看到所有 RAID 设备和他们的状态。可以使用 "Create RAID" 按钮来创建新的 RAID 设备，或者选择一个现有的设备进行管理。


请注意，Webmin 是一个强大的系统管理工具，它可以管理系统的许多方面，包括用户、服务、网络设置等。在使用它时，请确保了解正在做什么，以避免意外地改变系统设置。



### 1.2.5 ZFS 和 RAIDZ


在 Ubuntu 下，可以使用 ZFS 文件系统来创建 RAIDZ 磁盘阵列。以下是创建 RAIDZ 的步骤：


1. 首先，需要在系统上安装 ZFS。在终端中运行以下命令：


```bash

sudo apt update

sudo apt install zfsutils-linux

```


2. 假设有三个磁盘 `/dev/sdb`、`/dev/sdc` 和 `/dev/sdd`，可以使用以下命令创建 RAIDZ：


```bash

sudo zpool create mypool raidz /dev/sdb /dev/sdc /dev/sdd

```


这将创建一个名为 `mypool` 的 RAIDZ 磁盘阵列。


3. 可以使用 `zpool status` 命令来检查 RAIDZ 状态：


```bash

sudo zpool status mypool

```


请注意，RAIDZ 需要至少三个磁盘。如果有更多的磁盘，可以选择创建 RAIDZ2 或 RAIDZ3，它们可以容忍两个或三个磁盘的失败。


另外，ZFS 是一个复杂的文件系统，它有许多高级功能，如快照、复制和数据压缩。在使用 ZFS 时，可能需要花一些时间来学习和理解这些功能。


一个在线的RAIDZ容量计算工具：https://raidz-calculator.com/default.aspx


如果多盘位依然不够用，就要考虑分布式存储了。

## 1.3 分布式存储

分布式存储是指将数据存储在分布式网络中的计算机系统。分布式存储的关键是将数据分布在多个计算机上，并提供一个统一的接口来访问这些数据。

分布式存储的主要优点是可以处理大量数据和计算，提高系统的可用性和容错性。

分布式存储的主要缺点是数据访问速度可能较慢，需要考虑网络延迟和带宽限制。

### 1.3.1 分布式存储的抽象实现

分布式存储系统的实现通常涉及以下几个关键步骤：

1. **数据分片**：首先，数据被分割成多个小块或分片（shards）。这些分片可以独立地在不同的节点上存储和处理。

2. **数据分布**：然后，这些分片被分布到网络中的多个节点上。这通常通过一种称为哈希的函数来实现，该函数将每个分片映射到一个或多个节点。

3. **冗余和复制**：为了提高数据的可用性和容错性，每个分片通常会在多个节点上存储多个副本。如果一个节点失败，其他节点上的副本可以用来恢复数据。

4. **一致性和协调**：分布式存储系统需要一种机制来保证数据的一致性，即所有的副本都反映了最新的数据状态。这通常通过一种协调协议来实现，如Raft或Paxos。

5. **数据访问**：最后，分布式存储系统提供一个统一的接口，客户端可以通过这个接口访问存储在多个节点上的数据，而无需关心数据的具体位置和分布。

常见的分布式存储系统包括Google的GFS、Apache的Hadoop等。

### 1.3.2 分布式存储的物理实现

分布式存储系统的物理实现，首先需要一组服务器，这些服务器构成了分布式存储系统的物理基础。

每台服务器都配备有自己的存储设备，如硬盘或固态硬盘。这些服务器通过网络连接在一起，形成一个集群。

数据中心内部的网络连接常见的连接方式包括：

1. **万兆以太网（10 Gigabit Ethernet）**：提供了相对较高的带宽，可以满足大多数数据中心的需求。基于以太网，因此与现有的网络设备和协议兼容性良好。

2. **InfiniBand**：一种高性能的网络连接方式，提高极高带宽和低延迟的应用，适合高性能计算（HPC）或大规模并行场景。InfiniBand带宽远高于万兆以太网，而且延迟更低，但设备和管理成本通常也更高。

如果应用对带宽和延迟的需求非常高，那么可能需要选择InfiniBand。如果预算有限，或者对带宽和延迟的需求不是特别高，那么万兆以太网可能是一个更好的选择。

网络的设计和配置对于系统的性能和稳定性至关重要。通常，需要一个高速、低延迟的网络来连接这些服务器。在这些服务器上运行的软件负责管理和协调存储任务。Hadoop的HDFS（Hadoop Distributed File System）就是一个分布式存储系统的软件实现。


## 1.4 分布式并行计算

**分布式计算**：分布式计算是一种计算模式，其中多台计算机（通常在网络上）协同工作来完成一个任务。这些计算机可能在同一位置，也可能分布在世界各地。

分布式系统的主要优点是可以处理大量数据和计算，提高系统的可用性和容错性。

**并行计算**：并行计算是同时使用多个计算资源（如多个处理器或计算机）来解决一个计算问题。

并行计算可以在一个系统（如多核处理器）内部进行，也可以在多个系统（如计算机集群）之间进行。

**分布式并行计算**：分布式并行计算是分布式计算和并行计算的结合。

分布式并行计算是一种计算模式，它结合了分布式计算和并行计算的特点。在这种模式下，计算任务被分解成更小的子任务，这些子任务可以在多台计算机（通常在网络上）上同时（并行）执行。

这种计算模式的主要优点是可以处理大量数据和计算，提高系统的可用性和容错性。同时，通过并行执行任务，可以进一步提高计算效率和速度。





# 2. 大数据处理架构Hadoop


## 2.1. Hadoop的发展历史※

Hadoop的发展历史：

1. 2002年，Doug Cutting和Mike Cafarella开始开发Nutch项目，这是一个开源的网络搜索引擎。
2. 2004年，Google发布了GFS（Google文件系统）和MapReduce的论文，这两种技术对Hadoop的发展产生了深远影响。
3. 2006年，Doug Cutting在Nutch项目中实现了MapReduce和GFS，这就是Hadoop的雏形。同年，他将这部分代码独立出来，创建了Hadoop项目。
4. 2008年，Yahoo在其生产环境中部署了Hadoop，这是Hadoop首次在大规模环境中的应用。
5. 2011年，Apache基金会正式接纳Hadoop为顶级项目。
6. 之后，Hadoop持续发展，衍生出了许多子项目，如HDFS、MapReduce、HBase、Hive、Pig等。

Hadoop主要使用Java编写，因此Java是使用Hadoop的主要语言。此外，Hadoop Streaming API允许用户使用任何支持标准输入/输出的编程语言来编写MapReduce程序，如Python、Ruby等。


## 2.2. Hadoop的结构※

Hadoop的结构主要由以下几个核心组件构成：

1. **Hadoop Common**：这是Hadoop的基础库，提供了Hadoop的基础工具和Java库。它包含了Hadoop项目所需的一些必要模块和接口，例如文件系统和OS级别的抽象，还有一些Java文件的实用程序。

2. **Hadoop Distributed File System (HDFS)**：HDFS是Hadoop的分布式文件系统，它能在大规模集群中提供高吞吐量的数据访问。HDFS设计用来存储大量的数据，并且能够与Hadoop的其他组件协同工作。HDFS有两种类型的节点：NameNode（管理文件系统的元数据）和DataNode（存储实际的数据）。

3. **Hadoop YARN (Yet Another Resource Negotiator)**：YARN是Hadoop的一个资源管理平台，负责管理计算资源和调度用户应用程序。YARN将任务调度和资源管理分离开来，使得Hadoop可以支持更多种类的处理任务，不仅仅是MapReduce任务。YARN包括两个主要组件：ResourceManager（负责整个系统的资源管理和分配）和 NodeManager（负责单个节点上的资源和任务管理）。

4. **Hadoop MapReduce**：MapReduce是Hadoop的一个编程模型，用于处理和生成大数据集。用户可以编写Map和Reduce函数，然后Hadoop会负责数据的分发、并行处理、错误处理等。MapReduce运行在YARN之上，利用YARN进行资源管理和任务调度。

这些组件共同构成了Hadoop的核心结构，使得Hadoop能够处理和存储大规模的数据。



## 2.3. Hadoop的安装与运行※

Hadoop的安装过程可以分为以下步骤：

1. 下载Hadoop的最新版本。
2. 解压下载的文件。
3. 配置Hadoop的环境变量。
4. 配置Hadoop的核心配置文件，包括core-site.xml, hdfs-site.xml, mapred-site.xml, yarn-site.xml。
5. 格式化Hadoop文件系统（HDFS）。
6. 启动Hadoop。

这个过程可以通过脚本进行自动化部署。例如，可以使用Shell脚本或Python脚本来自动化上述步骤。此外，还有一些工具如Apache Ambari，它提供了一个Web界面，可以方便地进行Hadoop的安装和管理。

在实际的生产环境中，Hadoop的安装和配置需要考虑的因素包括网络配置、硬件配置、安全设置等。

Hadoop主要有以下三种安装和运行方式：

1. **本地（standalone）模式**：这是Hadoop的默认模式。在这种模式下，Hadoop将在单个机器上运行，不使用HDFS，而是使用本地文件系统来存储数据。这种模式主要用于调试，可以在没有网络设置的情况下运行和测试MapReduce作业。

2. **伪分布式模式**：在这种模式下，Hadoop仍然在单个机器上运行，但是会使用HDFS来存储数据。每个Hadoop守护进程（如NameNode, DataNode, ResourceManager, NodeManager等）都会在单独的Java进程中运行。这种模式主要用于开发和测试，可以在单个机器上模拟Hadoop集群。

3. **完全分布式模式**：这是Hadoop在生产环境中的运行模式。在这种模式下，Hadoop会在一个由多台机器组成的集群上运行，每台机器运行一部分Hadoop守护进程。数据会被分布在整个HDFS中，MapReduce作业会在集群的所有机器上并行运行。

## 2.4 Hadoop的使用

使用Hadoop主要涉及以下步骤：

1. **安装和配置**：首先，需要在的机器或集群上安装Hadoop，并进行适当的配置。这包括选择运行模式（本地、伪分布式或完全分布式），配置Hadoop的环境变量，以及设置Hadoop的配置文件。

2. **启动Hadoop**：安装和配置完成后，需要启动Hadoop。这通常涉及启动HDFS和YARN。

3. **运行MapReduce作业**：一旦Hadoop启动，就可以运行MapReduce作业了。这通常涉及编写Map和Reduce函数，然后使用Hadoop命令行工具提交作业。

4. **监控和管理**：运行MapReduce作业时，可能需要监控作业的进度和性能。Hadoop提供了一些工具来帮助做到这一点，例如Hadoop Web UI和YARN ResourceManager UI。

5. **数据存储和处理**：Hadoop的主要功能是存储和处理大规模数据。可以使用HDFS命令行工具来操作HDFS中的数据，例如创建目录、上传文件、下载文件等。也可以使用Hadoop的其他工具和库来处理数据，例如Hive和Pig。


## 2.5 Hadoop的安装

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




# 3. 分布式文件系统HDFS


## 3.1. 分布式文件系统

分布式文件系统目前主要有以下几种：

1. **Google File System (GFS)**：GFS是Google开发的分布式文件系统，用于Google内部的大规模数据处理。谷歌内部使用，并没有开放给外界。GFS的设计启发了HDFS的开发。

2. **Hadoop Distributed File System (HDFS)**：HDFS是Apache Hadoop项目的一部分，设计用于存储大规模数据集，并且能够与Hadoop的其他组件协同工作。HDFS具有高容错性，可以在廉价硬件上运行，并且设计用于高吞吐量的数据访问。
适用场景：HDFS非常适合大规模数据处理任务，如大数据分析和机器学习，特别是当这些任务使用Hadoop生态系统（如MapReduce，HBase、Hive等）时。

3. **GlusterFS**：GlusterFS是一个开源的分布式文件系统，能够处理大量的数据并提供高可用性。GlusterFS使用一种称为弹性哈希算法的技术来定位数据，这使得它可以在不需要元数据服务器的情况下进行扩展。
适用场景：GlusterFS适合需要高度可用和可扩展存储的场景，例如云存储和媒体流。

4. **Ceph**：Ceph是一个开源的分布式存储系统，提供了对象存储、块存储和文件系统三种接口。Ceph的一个显著特点是其强大的数据复制和恢复能力，它可以自动平衡数据并处理故障。
适用场景：Ceph适合需要多种类型存储（如对象、块和文件存储）的场景，例如云计算、虚拟化和容器化环境。

5. **MooseFS**：MooseFS是一个开源的分布式文件系统，提供了数据复制和容错功能。MooseFS的一个特点是其元数据服务器的设计，它使用多个元数据服务器来提供高可用性和容错能力。
适用场景：MooseFS适合需要高度可用和容错的存储系统的场景，例如云存储和备份系统。

## 3.2.	HDFS的适用场景※

HDFS(Hadoop Distributed File System) 主要适用于以下场景：

1. **大规模数据存储**：HDFS 能够存储 PB 级别的大数据，非常适合大数据分析等场景。

2. **批处理**：HDFS 优化了大规模数据流的连续读写，适合批处理任务，例如日志分析和报告生成。

3. **与 Hadoop 生态系统协同工作**：HDFS 是 Hadoop 生态系统的一部分，可与 MapReduce、Hive等 Hadoop 组件协同工作。

4. **容错和恢复**：HDFS 具有高容错性，能够自动从硬件故障中恢复，适合需要高可用性和数据持久性的场景。

5. **在廉价硬件上运行**：HDFS 能够在廉价的商用硬件上运行，适合需要大规模存储但预算有限的场景。

6. **高吞吐量数据访问**：HDFS 非常适合高吞吐量数据访问，适合需要大量数据访问的场景。

7. **不适合低延迟数据访问**：HDFS 不适合需要低延迟数据访问的场景，例如在线事务处理 (OLTP)。

## 3.3.	HDFS的安装

HDFS 是 Apache Hadoop 的一部分，因此安装 HDFS 实际上就是安装 Hadoop。以下是在单节点（也称为伪分布式模式）上安装 Hadoop 的基本步骤：

1. **系统准备**：确保的系统安装了 Java（Hadoop 需要 Java 运行环境），并设置好 `JAVA_HOME` 环境变量。

2. **下载 Hadoop**：从 Apache Hadoop 的官方网站下载最新的 Hadoop 发行版。

3. **解压 Hadoop**：将下载的 Hadoop tar.gz 文件解压到想要安装 Hadoop 的目录。

4. **配置 Hadoop**：编辑 Hadoop 的配置文件，主要是 `core-site.xml`，`hdfs-site.xml` 和 `mapred-site.xml`。在伪分布式模式下，需要设置文件系统为本地文件系统，并指定 NameNode 和 DataNode 的地址。

5. **格式化 HDFS**：在首次启动 Hadoop 之前，需要使用 `hadoop namenode -format` 命令来格式化 HDFS。

6. **启动 Hadoop**：使用 `start-dfs.sh` 和 `start-yarn.sh` 脚本来启动 Hadoop。

7. **验证安装**：使用 `jps` 命令来检查 Hadoop 的各个组件是否已经启动。应该能看到 `NameNode`，`DataNode`，`SecondaryNameNode`，`ResourceManager` 和 `NodeManager` 这几个进程。

如果想在多节点集群上安装 Hadoop，那么还需要配置 SSH 免密码登录，并在所有节点上重复以上步骤。


## 3.4. HDFS的使用

HDFS 提供了多种读写文件的方式，主要包括以下几种：

1. **HDFS Shell 命令**：HDFS 提供了一套类似于 Unix 文件系统的 Shell 命令，可以用来读写文件。例如，`hadoop fs -put localfile /user/hadoop/hadoopfile` 可以将本地文件上传到 HDFS，`hadoop fs -get /user/hadoop/hadoopfile localfile` 可以将 HDFS 上的文件下载到本地。

2. **HDFS Java API**：HDFS 的主要 API 是 Java API，可以用来进行更复杂的文件操作。例如，可以使用 `FileSystem` 类的 `create` 和 `open` 方法来写入和读取文件。

3. **WebHDFS REST API**：WebHDFS 是 HDFS 提供的一个 HTTP REST API，可以通过 HTTP 请求来读写文件。这使得非 Java 语言也可以方便地与 HDFS 交互。

4. **Hadoop Streaming**：Hadoop Streaming 是 Hadoop 提供的一个工具，可以使用任何可执行文件或脚本作为 Map/Reduce 任务来处理 HDFS 上的数据。

5. **第三方库**：有一些第三方库提供了与 HDFS 交互的接口，

Python 的 `hdfs`库，可以用来读写 HDFS 上的文件，提供了一些函数和方法，可以用来执行常见的HDFS操作，如读写文件、创建和删除目录等。

首先，确保已经安装了 `hdfs`。如果没有，可以使用 pip 安装：

```bash
pip install hdfs
```

然后，可以使用以下 Python 代码来操作 `hdfs`：

```python
from hdfs import InsecureClient

# 创建一个客户端
client = InsecureClient('http://localhost:50070', user='hdfs')

# 创建一个目录
client.makedirs('/user/hdfs/dir')

# 上传一个文件
client.upload('/user/hdfs/dir', 'localfile.txt')

# 读取一个文件
with client.read('/user/hdfs/dir/localfile.txt') as reader:
  content = reader.read()
```

请注意，这只是一个基本的例子，实际使用时可能需要处理各种可能的错误和异常。


# 4. 分布式数据库HBase

## 4.1. 分布式数据库

数据库是一个组织数据的系统，它允许用户存储、检索、更新和管理数据。数据库通常由一系列相关的数据表组成，每个数据表包含一组数据记录。

分布式数据库是一种数据库管理系统，它将数据分布在多个物理位置（可能是多个网络连接的计算机）上。

分布式数据库可以提高数据的可用性和可靠性，因为数据在多个节点上有备份。此外，分布式数据库还可以提高查询和事务处理的性能，因为这些操作可以在多个节点上并行执行。

主要的分布式数据库包括：

1. **Google Cloud Spanner**：Google Cloud Spanner 是 Google 的全球分布式关系数据库服务，提供了事务一致性和 SQL 语义。

2. **HBase**：HBase 是 Hadoop 生态系统的一部分，它是一个开源的非关系型分布式数据库，设计用于大规模数据存储。

3. **CouchDB**：Apache CouchDB 是一个开源的分布式数据库，设计用于云计算环境。

4. **CockroachDB**：CockroachDB 是一个开源的分布式 SQL 数据库，设计用于构建全球、可扩展的云服务。

5. **Cassandra**：Apache Cassandra 是一个开源的分布式数据库，设计用于处理大量数据跨多个商品服务器。

由于本课程以Hadoop为基础，这里采用HBase。

## 4.2. 数据的结构化程度

结构化数据、非结构化数据和半结构化数据是描述数据组织方式的术语：

1. **结构化数据**：这种数据类型有预定义的数据模型，或者说，有严格的组织方式。它们通常存储在关系数据库中，如 SQL 数据库。例子包括人员名单、库存记录等。

2. **非结构化数据**：这种数据没有预定义的模型，也没有组织方式。这种数据类型包括电子邮件、视频、图片、网页内容等。

3. **半结构化数据**：这种数据介于结构化和非结构化数据之间。它们没有固定的格式，但有某种形式的组织，如标签或其他标记，以区分不同的元素。例子包括 JSON、XML、HTML 等。

至于数据的结构化程度是否有定量衡量指标，目前并没有公认的定量衡量标准。数据的结构化程度通常是根据数据的组织和格式化程度来定性描述的。例如，如果数据可以很容易地存储在表格中，那么它通常被认为是结构化的。如果数据是文本、图像或音频等形式，那么它通常被认为是非结构化的。如果数据有某种形式的标记或元数据，但不符合严格的表格结构，那么它通常被认为是半结构化的。

## 4.3.	HBase的适用场景※

HBase 的适用场景：

1. **大数据存储**：HBase 是一个宽列式存储的数据库，适合存储非结构化和半结构化的数据，因为列式存储允许数据模式在行之间有所不同，并且可以有效地存储和查询大量的稀疏数据。

2. **实时查询**：HBase 提供了低延迟的随机读写能力，因此它适合需要实时查询的应用。

3. **时间序列数据**：HBase 的数据模型和架构使得它非常适合存储时间序列数据，例如股票价格、气象数据等。

4. **内容管理系统**：HBase 可以用于构建内容管理系统或搜索引擎，因为它可以存储大量的文档或网页，并提供快速的全文搜索能力。

5. **日志存储和分析**：HBase 可以用于存储和分析大量的日志数据，例如网络日志、系统日志等。

6. **社交网络数据**：HBase 可以用于存储和分析社交网络数据，例如用户的朋友关系、用户的行为数据等。

## 4.4.	HBase的安装

HBase 的安装过程通常包括以下步骤：

1. **安装 Java**：HBase 需要 Java 运行环境，因此首先需要在系统上安装 Java。

2. **安装 Hadoop**：HBase 需要在系统上安装 Hadoop。这一步上一单元已经完成了。。

3. **下载和解压 HBase**：可以从 Apache HBase 的官方网站下载最新的 HBase 发行版。然后，使用以下命令解压下载的 HBase 压缩文件：

```bash
tar xzf hbase-x.y.z.tar.gz
```

4. **配置 HBase**：需要编辑 HBase 的配置文件（`hbase-site.xml`），设置 HBase 的运行模式（独立模式、伪分布式模式或完全分布式模式）和 HBase 数据的存储路径等。

5. **启动 HBase**：最后，可以使用 HBase 的启动脚本启动 HBase：

```bash
./bin/start-hbase.sh
```

以上是在单个节点上安装 HBase 的基本步骤。在生产环境中，可能需要在多个节点上安装 HBase，以构建一个分布式的 HBase 集群。


以下是在已经安装好 Hadoop 的基础上，安装 HBase 的步骤：

1. **下载 HBase**：首先，从 Apache HBase 的官方网站下载最新稳定版的 HBase。你可以使用 `wget` 命令来下载：

```bash
wget https://mirrors.tuna.tsinghua.edu.cn/apache/hbase/stable/hbase-2.5.8-bin.tar.gz
```

请注意，上述链接可能会随着新版本的发布而改变。

2. **解压 HBase**：使用 `tar` 命令解压下载的文件：

```bash
tar xzf hbase-2.5.8-bin.tar.gz
sudo mv hbase-2.5.8 /usr/local/hbase
```

3. **配置 HBase**：编辑 HBase 的配置文件 `hbase-site.xml`，设置 HBase 的运行模式和数据存储路径。你可以使用以下命令打开配置文件：

```bash
sudo nano /usr/local/hbase/conf/hbase-site.xml
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
​hbase thrift start
pip install happybase hbase
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


# 5. 分布式数据仓库Hive

## 5.1.	数据仓库与数据库的区别※

HBase适合大量短小查询，实时并发；Hive适合少量的复杂查询，密集读取。

数据仓库和数据库都是用于存储数据的系统，但它们的目标和使用方式有所不同。

**数据库**主要用于存储和管理日常操作的数据。可以把它想象成一个超市的货架，用于存放商品。当客户（即应用程序）需要商品（即数据）时，他们可以直接从货架（即数据库）上取得。例如，当在网上购物时，订单信息会被存储在数据库中，以便商家可以处理订单。

**数据仓库**则是用于存储历史数据，并进行复杂的查询和分析。可以把它想象成一个大型的仓库，用于存放过去的销售记录。这些记录可以用来分析销售趋势，预测未来的销售情况，或者找出最畅销的商品等。例如，一个大型零售商可能会使用数据仓库来存储过去几年的销售数据，然后使用这些数据来制定未来的销售策略。

总的来说，数据库更注重实时性和事务处理，适合处理 OLTP（在线事务处理）任务，而数据仓库更注重数据的整合、存储和分析，适合处理 OLAP（在线分析处理）任务。

OLTP（Online Transaction Processing，在线事务处理）和 OLAP（Online Analytical Processing，在线分析处理）是两种不同的数据处理方式。

**OLTP** 主要用于处理日常的事务型操作。这种操作通常涉及到数据的增删改查，例如银行转账、订单处理等。OLTP 系统的主要特点是大量的短小查询，更新密集，强调数据的实时性和并发性。

**OLAP** 主要用于分析业务数据，帮助企业进行决策。这种操作通常涉及到复杂的查询和大量的数据，例如销售趋势分析、财务报告等。OLAP 系统的主要特点是少量的复杂查询，读取密集，强调数据的整合和分析。

## 5.2.	Hive的安装

Hive 的安装过程通常包括以下前置步骤：

* **已经安装 Java**：Hive 需要 Java 运行环境，因此首先需要在系统上安装 Java 8。

* **已经安装 Hadoop**：Hive 需要在系统上安装 Hadoop。这一步上一单元已经完成了。。

以下是在已经安装好 Hadoop 的基础上，安装 Hive 的步骤：

1. **下载 Hive**：可以从 Apache Hive 的官方网站下载最新的 Hive 发行版：

```bash
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
mv hive-default.xml.template hive-default.xml
nano hive-site.xml
```

在`hive-site.xml`中添加如下配置信息：
```XML
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
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

5. **启动 Hive**：最后，可以使用 Hive 的启动脚本启动 Hive：

```bash
hive
```

以上是在单个节点上安装 Hive 的基本步骤。在生产环境中，可能需要在多个节点上安装 Hive，以构建一个分布式的 Hive 集群。这需要更复杂的配置和更多的步骤。


## 5.3. Hive的适用场景

Hive 是一个建立在 Hadoop 上的数据仓库工具，它提供了类 SQL 的查询语言 HiveQL，用于查询、摘要和分析数据。以下是 Hive 的一些适用场景：

1. **批量数据处理**：Hive 适合处理大量的数据，例如日志分析、数据挖掘等。它可以处理 PB 级别的数据。

2. **数据仓库任务**：Hive 适合进行数据 ETL（提取、转换、加载）任务，以及数据摘要和报告。例如，可以使用 Hive 来创建数据仓库，然后使用 HiveQL 来生成报告。

3. **数据分析**：Hive 提供了丰富的内置函数，用于数据分析，包括字符串处理、日期处理、数值计算等。也可以使用 HiveQL 来编写复杂的数据分析查询。

4. **与其他数据工具集成**：Hive 可以与其他数据工具集成，例如 Spark、Pig、HBase 等。这使得可以在 Hive 中查询和分析这些工具的数据。

总的来说，Hive 适合处理大数据的场景，特别是需要进行数据查询和分析的场景。

## 5.4. Hive的使用

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

请注意，这些命令需要在运行 Hive 服务的机器上执行，并且可能需要 root 权限。如果你的 Hive 服务是通过某种集群管理工具（如 Apache Ambari 或 Cloudera Manager）管理的，你应该使用那个工具来停止 Hive 服务。


通过修改Hadoop的`core-site.xml`配置文件来添加或修改`hadoop.proxyuser.hadoop.groups`和`hadoop.proxyuser.hadoop.hosts`这两个配置项。

```Bash
cp  /usr/local/hadoop/etc/hadoop/core-site.xml  /usr/local/hadoop/etc/hadoop/core-site.xml.back
nano /usr/local/hadoop/etc/hadoop/core-site.xml
```

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
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
  <property>
    <name>hive.server2.authentication</name>
    <value>PAM</value>
  </property>
    <property>
        <name>hive.server2.enable.doAs</name>
        <value>true</value>
    </property>
</configuration>
```

这个配置允许`hadoop`用户代理任何组的用户，并且允许从任何主机进行代理。

修改配置文件后，你需要重启Hadoop和Hive服务。

请注意，这个配置可能会带来安全风险，因为它允许`hadoop`用户代理任何用户。在生产环境中，你应该根据实际需要来设置这个配置，而不是简单地允许所有的代理请求。

在 Python 中使用 Hive，可以使用 `pyhive` 库。以下是一个简单的示例，展示如何连接到 Hive，执行查询，然后获取结果：

首先，要运行Hiveserver2。然后要确保已经安装了 `pyhive` 等依赖包。如果没有，可以使用 pip 安装：

```bash
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


# 6. 分布式计算框架MapReduce
## 6.1.	MapReduce的发展历史※

MapReduce 是由 Google 的工程师在 2004 年首次提出的一种分布式计算模型，主要目标是简化大规模数据集上的计算。

MapReduce 的发展历史的简要概述：

1. **2004年**：Google 的工程师 Jeffrey Dean 和 Sanjay Ghemawat 发表了一篇名为 "MapReduce: Simplified Data Processing on Large Clusters" 的论文，首次提出了 MapReduce 模型。这个模型使得开发者可以在不了解分布式系统细节的情况下，进行大规模数据处理。

2. **2006年**：Doug Cutting 和 Mike Cafarella 为了支持 Nutch（一个开源的网络搜索引擎项目）的扩展，开始开发 Hadoop，并将 MapReduce 作为 Hadoop 的核心组件。Hadoop 是一个开源的分布式计算框架，它使得 MapReduce 模型得以在更广泛的场景中使用。

3. **2008年**：Yahoo 在其生产环境中部署了 Hadoop 和 MapReduce，这是 MapReduce 在大规模商业应用中的首次使用。

4. **2010年以后**：随着大数据和分布式计算的发展，MapReduce 成为了处理大规模数据的重要工具。许多公司和组织，包括 Facebook、Twitter、LinkedIn 等，都在其数据处理流程中使用了 MapReduce。

5. **现在**：MapReduce 的计算模型相对较为简单，不适合需要复杂迭代计算或实时处理的任务。Spark 提供了更为灵活的计算模型，支持复杂的迭代计算，而且通过内存计算可以大大提高计算速度。Flink 则提供了对实时流处理的原生支持，适合需要实时处理的任务。对于需要复杂迭代计算或实时处理的任务，Spark 和 Flink 通常是更好的选择。

## 6.2. MapReduce的设计思想

MapReduce 的中文翻译通常是“映射-归约”。其中，“Map”对应“映射”，“Reduce”对应“归约”。这两个词分别代表了 MapReduce 计算模型的两个主要阶段：Map 阶段和 Reduce 阶段。

1. **Map 阶段**：在这个阶段，输入数据被分割成多个独立的块，然后每个块被分配给一个 Map 任务进行处理。Map 任务对输入数据进行处理，并生成一组中间键值对。

2. **Reduce 阶段**：在这个阶段，所有的中间键值对被按键排序，然后分配给 Reduce 任务。Reduce 任务对每个键的所有值进行处理，并生成一组输出键值对。

许多类型的计算都可以转换成 MapReduce 模型，例如排序、聚合、过滤、分组等。这些计算都可以通过 Map 阶段和 Reduce 阶段的组合来实现。

然而，有些计算难以转换成 MapReduce 模型，或者转换后的效率不高。例如，需要多次迭代的计算（如图算法、机器学习算法等）就难以直接转换成 MapReduce 模型，因为 MapReduce 模型不直接支持迭代。虽然可以通过多次 MapReduce 任务来实现迭代，但这样会增加计算的复杂性和开销。此外，需要全局共享状态的计算也难以转换成 MapReduce 模型，因为 MapReduce 模型是基于数据的局部性的。

## 6.3.	MapReduce的应用场景

MapReduce 主要适用于以下几种场景：

1. **大规模数据处理**：MapReduce 能够处理 PB 级别的数据，适合于大规模数据集的处理。

2. **批处理**：MapReduce 适合于批处理任务，例如日志分析、数据挖掘等。

3. **分布式排序和分组**：MapReduce 的 Reduce 阶段提供了自然的排序和分组机制，适合于需要排序和分组的计算任务。

4. **并行计算**：MapReduce 通过将计算任务分配到多个节点上并行执行，可以大大提高计算速度。

然而，MapReduce 不适合需要复杂迭代计算或实时处理的任务。对于这些任务，可能需要使用其他的分布式计算模型，如 Spark 或 Flink。

## 6.4. MapReduce的使用

在 Python 中，可以使用 `mrjob` 库来实现 MapReduce。`mrjob` 是一个 Python 的 MapReduce 库，它允许在 Python 中编写 MapReduce 任务，并可以在多种环境中运行，包括本地机器、Hadoop 集群或 Amazon's Elastic MapReduce 服务。

首先，确保已经安装了 `mrjob`。如果没有，可以使用 pip 安装：

```bash
pip install mrjob
```

然后，可以使用以下 Python 代码来实现一个计算单词出现次数的 MapReduce 任务：

```python
from mrjob.job import MRJob
from mrjob.step import MRStep
import re

WORD_RE = re.compile(r"[\w']+")

class MRWordFrequencyCount(MRJob):

    def steps(self):
        return [
            MRStep(mapper=self.mapper_get_words,
                   reducer=self.reducer_count_words)
        ]

    def mapper_get_words(self, _, line):
        words = WORD_RE.findall(line)
        for word in words:
            yield (word.lower(), 1)

    def reducer_count_words(self, word, values):
        yield (word, sum(values))

if __name__ == '__main__':
    MRWordFrequencyCount.run()
```

可以将这个脚本保存为 `wordcount.py`，然后在命令行中运行它：

```bash
python wordcount.py input.txt
```

这个脚本会读取 `input.txt` 文件，计算每个单词的出现次数，然后将结果输出到标准输出。

要在本地的 Hadoop 集群上运行上述的 MapReduce 任务，需要先确保机器上已经安装了 Hadoop 和 mrjob。然后，可以使用以下的命令来运行 MapReduce 任务：

```bash
python wordcount.py -r hadoop hdfs:///path/to/your/input.txt
```

在这个命令中，`-r hadoop` 指定了运行环境为 Hadoop，`hdfs:///path/to/your/input.txt` 是输入文件在 HDFS 中的路径。

请注意，需要将 `hdfs:///path/to/your/input.txt` 替换为实际输入文件的路径。如果有多个输入文件，可以在命令行中列出所有的文件，或者使用通配符。

运行这个命令后，mrjob 会自动将 Python 脚本转换为一个 Hadoop Streaming 任务，并在 Hadoop 集群上运行这个任务。结果会被输出到标准输出。

# 7. 分布式计算框架Spark

## 7.1.	Spark的发展历史

Apache Spark 是一种大规模数据处理的开源集群计算系统，它最初是由加州大学伯克利分校的 AMPLab（算法机器人学习实验室）在 2009 年开发的。

Spark 的主要发展历程：

1. **2009年**：Spark 项目在加州大学伯克利分校的 AMPLab 启动。

2. **2010年**：Spark 在 USENIX NSDI 大会上公开发布。

3. **2012年**：Spark 成为 Apache 基金会的孵化项目。

4. **2013年**：Spark 成为 Apache 基金会的顶级项目。

5. **2014年**：Spark 1.0 发布，这是 Spark 的第一个大版本。

6. **2015年**：Spark 1.6 发布，这是 Spark 1.x 系列的最后一个版本。

7. **2016年**：Spark 2.0 发布，这个版本引入了一些重要的新特性，如 Structured Streaming、DataFrame API 和 Dataset API。

8. **2018年**：Spark 2.4 发布，这是 Spark 2.x 系列的最后一个版本。

9. **2020年**：Spark 3.0 发布，这个版本进一步改进了 Spark 的性能和易用性。

至今，Spark 已经成为大数据处理领域最流行的开源项目之一，被广泛应用于数据挖掘、机器学习、图计算等多种场景。

## 7.2. Spark的适用场景

Apache Spark 适用于以下几种场景：

1. **迭代式算法**：Spark 的弹性分布式数据集（RDD）可以在内存中缓存数据，这使得 Spark 非常适合于需要多次迭代的算法，如机器学习和图算法。

2. **交互式数据挖掘和查询**：Spark 提供了强大的交互式 Python 和 Scala shell，可以方便地进行数据挖掘和查询。

3. **流处理**：Spark Streaming 可以处理实时数据流，并提供了与批处理相同的 API，使得开发者可以在同一套代码上进行批处理和流处理。

4. **图处理**：GraphX 是 Spark 的一个图计算库，提供了一套灵活的图计算 API。

与 Hadoop 相比，Spark 有以下优势：

1. **速度**：Spark 能够将数据缓存到内存中，这使得 Spark 在处理迭代式算法时比 Hadoop MapReduce 快很多。

2. **易用性**：Spark 提供了丰富的高级 API，包括 Java、Scala、Python 和 R，以及一套强大的交互式查询工具。

3. **灵活性**：Spark 支持批处理、交互式查询、流处理和机器学习等多种计算模式。

4. **容错性**：Spark 的 RDD 提供了一种高效的容错机制。

## 7.3. Spark的安装

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


## 7.4. Spark的使用

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

## 7.5 Hadoop HBase Spark 运行实战

### 7.5.1 环境运行

启动Hadoop

```bash
start-all.sh
```

启动HBase

```bash
start-hbase.sh
```

启动Spark

```bash
start-all.sh
```

通过访问以下URL来确认这些组件是否已经成功启动：

- Hadoop: http://localhost:9870/
- HBase: http://localhost:16010/
- Spark: http://localhost:4040/

### 7.5.2 Python使用

以下是使用Python操作HDFS，HBase和Spark的示例代码。

首先，我们需要安装一些必要的库，包括`hdfs`, `happybase`, `pyspark`，`seaborn`和`pandas`以及`scikit-learn`。

```bash
pip install hdfs happybase pyspark seaborn pandas scikit-learn --break-system-packages
```

使用HDFS

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

使用HBase

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

使用Spark

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

### 7.5.3 Iris数据写入和读取

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


# 8. 流计算以及Flink基础

## 8.1. 批计算与流计算的区别

批处理和流处理是两种不同的数据处理模型，它们的主要区别包括：

1. **数据处理的时间性**：批处理通常在一段时间后处理收集到的数据，而流处理则是实时处理数据。这意味着批处理通常有一定的延迟，而流处理可以提供近实时的结果。

2. **数据的有限性**：批处理处理的是有限的数据集，而流处理处理的是无限的数据流。这意味着批处理任务在处理完所有数据后就会结束，而流处理任务则可以持续不断地运行。

3. **处理方式**：批处理通常一次处理所有数据，而流处理则是一次处理一个或一批数据。这意味着批处理通常需要更多的计算资源，但可以更好地利用数据局部性，而流处理则可以更快地处理数据，但可能需要更复杂的状态管理。

4. **用途**：批处理通常用于离线分析，例如日志分析、报表生成等，而流处理则通常用于实时分析，例如实时监控、实时推荐等。

请注意，这两种处理模型并不是互斥的，很多应用需要同时使用批处理和流处理。例如，一个应用可能使用流处理进行实时分析，同时使用批处理进行深度分析。



## 8.2.	Flink的发展历史

Apache Flink 是一个开源的流处理框架，它的发展历史如下：

1. **2009年**：Flink 的前身 Stratosphere 项目在多个大学和研究机构的支持下开始。

2. **2014年**：Stratosphere 项目被 Apache Software Foundation 接纳为孵化项目，并改名为 Flink。"Flink" 在德语中意为 "快速"，这反映了该项目的目标，即快速处理大数据。

3. **2015年**：Flink 从 Apache 的孵化项目毕业，成为顶级项目。同年，Flink 社区发布了 Flink 的第一个稳定版本 0.10.0。

4. **2016年以后**：Flink 社区持续发布新版本，不断增加新的特性，例如保存点（savepoints）、事件时间（event time）支持、CEP 库等。同时，Flink 的应用也越来越广泛，被越来越多的公司用于实时数据处理。

Flink 的发展历史显示了它从一个学术项目发展为一个被广泛使用的大数据处理框架的过程。

## 8.3. Flink的适用场景※

Apache Flink 作为一个高效、灵活的大数据处理框架，适用于多种场景，包括但不限于：

1. **实时数据流处理**：Flink 提供了强大的流处理能力，可以处理高速流入的数据，并提供近实时的结果。这对于需要实时分析和决策的应用非常重要，例如实时监控、实时推荐、实时风控等。

2. **事件驱动应用**：Flink 支持事件时间处理和水印机制，可以处理乱序数据，非常适合事件驱动的应用，例如复杂事件处理、实时报警等。

3. **批处理**：虽然 Flink 主要是一个流处理框架，但它也支持批处理。Flink 的 DataSet API 提供了一套完整的批处理能力，可以进行大规模的数据分析和计算。

4. **机器学习和数据挖掘**：Flink 提供了一套机器学习库，可以进行大规模的机器学习和数据挖掘，例如分类、回归、聚类等。但这方面不如Spark的生态成熟。

5. **ETL**：Flink 可以进行实时的 ETL（Extract, Transform, Load）操作，例如数据清洗、数据转换、数据加载等。


## 8.4.	Flink的安装

安装 Apache Flink 的过程可以分为以下几个步骤：

1. **下载 Flink**：首先，需要从 Flink 的官方网站下载最新的 Flink 发行版。可以选择预编译的版本，这样可以省去自己编译的步骤。

```bash
wget https://www.apache.org/dyn/closer.lua/flink/flink-1.18.0/flink-1.18.0-bin-scala_2.12.tgz
```

2. **解压 Flink**：下载完成后，需要解压下载的文件。

```bash
tar xvf flink-1.18.0-bin-scala_2.12.tgz
```

3. **设置环境变量**：为了方便使用 Flink，可以将 Flink 的 bin 目录添加到 PATH 环境变量中。还需要设置 `FLINK_HOME` 环境变量，指向 Flink 安装目录。

```bash
export FLINK_HOME=/path/to/flink-1.18.0
export PATH=$PATH:$FLINK_HOME/bin
```

4. **启动 Flink**：现在，可以启动 Flink 的本地模式了。

```bash
start-cluster.sh
```

以上步骤是在单机上安装 Flink 的基本步骤。如果想在集群上安装 Flink，还需要配置 Flink 的集群管理器，例如 Standalone、YARN 或 Kubernetes。

请注意，运行 Flink 还需要 Java 环境，所以在安装 Flink 之前，需要确保机器上已经安装了 Java。

## 8.5.	Flink的使用

Apache Flink 主要使用 Java 或 Scala 进行编程，但也提供了 Python API，称为 PyFlink。

Apache Flink 的开发团队在 2020 年宣布了他们计划逐步淘汰对 Scala API 的支持。因此，建议使用 Java 或 Python API 进行开发。

以下是一个使用 PyFlink 的简单示例，该示例从一个集合中读取数据，然后计算每个元素的平方：

```python
from pyflink.dataset import ExecutionEnvironment
from pyflink.table import BatchTableEnvironment, TableConfig

# 创建 ExecutionEnvironment 和 BatchTableEnvironment
env = ExecutionEnvironment.get_execution_environment()
t_config = TableConfig()
t_env = BatchTableEnvironment.create(env, t_config)

# 创建一个从 1 到 100 的集合
data = [i for i in range(1, 101)]
ds = env.from_collection(data)

# 计算每个元素的平方
result = ds.map(lambda x: x**2)

# 打印结果
result.output()

# 执行任务
env.execute("Batch Job")
```

在这个示例中，首先创建了一个 ExecutionEnvironment 和一个 BatchTableEnvironment。然后，使用 `from_collection` 方法创建了一个 DataSet。接下来，使用 `map` 方法计算每个元素的平方。最后，使用 `output` 方法打印结果，并使用 `execute` 方法执行任务。

请注意，这个示例需要在 Flink 的 Python 环境中运行。可以使用 `pip install apache-flink` 命令安装 PyFlink。


