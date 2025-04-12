# Ubuntu 24.04 HBase安装脚本

这是一个为Ubuntu 24.04设计的HBase完整安装脚本，使用USTC和TUNA镜像源以提高在中国大陆的下载速度。

```bash
#!/bin/bash

# Ubuntu 24.04 HBase安装脚本
# 使用USTC和TUNA镜像源以提高在中国大陆的下载速度

# 遇到错误即退出
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # 无颜色

# 配置变量
HBASE_VERSION="2.5.11"
JAVA_VERSION="openjdk-11-jdk"
HADOOP_USER="hadoop"
HADOOP_HOME="/opt/hadoop"
HBASE_HOME="/opt/hbase"
HBASE_CONF_DIR="$HBASE_HOME/conf"
DATA_DIR="/hbase/data"
ZOOKEEPER_DIR="$DATA_DIR/zookeeper"
LOG_DIR="/hbase/logs"
TMP_DIR="/hbase/tmp"
HOSTNAME="localhost"

# 输出带颜色的信息
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 替换apt源为USTC镜像
replace_apt_sources() {
    info "替换apt源为USTC镜像..."
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
    sudo bash -c 'cat > /etc/apt/sources.list << EOF
deb https://mirrors.ustc.edu.cn/ubuntu/ noble main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ noble-updates main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ noble-backports main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ noble-security main restricted universe multiverse
EOF'
}

# 更新系统并安装依赖
update_system() {
    info "更新系统并安装依赖..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y $JAVA_VERSION ssh pdsh curl wget net-tools lsof
}

# 配置网络接口
configure_network() {
    info "配置网络设置..."
    
    # 获取可用的网络接口和IP
    interfaces=($(ip -o -4 addr show | awk '{print $2 ":" $4}' | cut -d/ -f1 | grep -v "lo"))
    
    echo "可用的网络接口:"
    for i in "${!interfaces[@]}"; do
        echo "$((i+1)). ${interfaces[$i]}"
    done
    
    # 默认使用localhost
    HOSTNAME="localhost"
    
    # 询问用户是否要选择特定网络接口
    read -p "是否要选择特定网络接口? (y/n，默认为n使用localhost): " select_interface
    if [[ "$select_interface" == "y" ]]; then
        read -p "请选择网络接口编号 (1-${#interfaces[@]}): " interface_num
        if [[ "$interface_num" =~ ^[0-9]+$ ]] && [ "$interface_num" -ge 1 ] && [ "$interface_num" -le "${#interfaces[@]}" ]; then
            selected_interface=${interfaces[$((interface_num-1))]}
            HOSTNAME=$(echo $selected_interface | cut -d: -f2)
            info "已选择网络接口: $selected_interface, 将使用IP: $HOSTNAME"
        else
            warn "无效选择，将使用默认值localhost"
        fi
    else
        info "将使用localhost作为HBase主机名"
    fi
    
    # 检查/etc/hosts文件
    if ! grep -q "$HOSTNAME" /etc/hosts; then
        warn "未在/etc/hosts中找到 $HOSTNAME，建议添加对应条目"
        read -p "是否自动添加到/etc/hosts? (y/n): " add_hosts
        if [[ "$add_hosts" == "y" ]]; then
            if [[ "$HOSTNAME" != "localhost" ]]; then
                sudo bash -c "echo '$HOSTNAME $(hostname)' >> /etc/hosts"
                info "已添加 $HOSTNAME $(hostname) 到/etc/hosts"
            fi
        fi
    fi
}

# 检查Hadoop是否已安装
check_hadoop() {
    info "检查Hadoop是否已安装..."
    if [ ! -d "$HADOOP_HOME" ]; then
        warn "Hadoop未安装或未找到在 $HADOOP_HOME"
        read -p "HBase依赖Hadoop，是否继续安装？(y/n): " confirm
        if [ "$confirm" != "y" ]; then
            error "安装已取消。请先安装Hadoop后再安装HBase。"
        else
            warn "继续安装，但HBase可能无法正常运行，除非您已在其他位置安装了Hadoop。"
        fi
    else
        info "检测到Hadoop安装在 $HADOOP_HOME"
    fi
}

# 创建必要目录
setup_dirs() {
    info "设置必要的目录..."
    
    # 创建必要的目录，仅在不存在时创建
    for dir in "$DATA_DIR" "$ZOOKEEPER_DIR" "$LOG_DIR" "$TMP_DIR"; do
        if [ ! -d "$dir" ]; then
            sudo mkdir -p "$dir"
            info "创建目录: $dir"
        else
            info "目录已存在，跳过创建: $dir"
        fi
    done
    
    # 设置权限
    sudo chown -R $HADOOP_USER:$HADOOP_USER $DATA_DIR $LOG_DIR $TMP_DIR
}

# 下载并安装HBase
download_and_install_hbase() {
    local archive_file="hbase-$HBASE_VERSION-bin.tar.gz"
    
    # 检查是否已下载
    if [ -f "$archive_file" ]; then
        info "HBase安装包已下载，跳过下载步骤"
    else
        info "下载HBase ${HBASE_VERSION}..."
        local download_success=false
        
        # 尝试从USTC镜像下载
        info "尝试从USTC镜像下载..."
        if wget -c https://mirrors.ustc.edu.cn/apache/hbase/$HBASE_VERSION/hbase-$HBASE_VERSION-bin.tar.gz; then
            download_success=true
        else
            warn "USTC镜像下载失败，尝试TUNA镜像..."
            # 尝试从TUNA镜像下载
            if wget -c https://mirrors.tuna.tsinghua.edu.cn/apache/hbase/$HBASE_VERSION/hbase-$HBASE_VERSION-bin.tar.gz; then
                download_success=true
            else
                error "下载失败，请检查网络连接或HBase版本是否存在"
            fi
        fi
    fi
    
    # 检查是否已安装
    if [ -d "$HBASE_HOME" ]; then
        info "HBase已安装在 $HBASE_HOME，跳过解压安装步骤"
    else
        # 解压并安装
        info "解压并安装HBase..."
        sudo tar -xzf $archive_file
        sudo mv hbase-$HBASE_VERSION $HBASE_HOME
    fi
    
    # 无论是否已安装，都确保权限正确
    sudo chown -R $HADOOP_USER:$HADOOP_USER $HBASE_HOME
}

# 配置HBase
configure_hbase() {
    info "配置HBase环境..."
    
    # 配置hbase-env.sh
    sudo -u $HADOOP_USER bash -c "cat > $HBASE_CONF_DIR/hbase-env.sh << EOF
#!/usr/bin/env bash
export JAVA_HOME=\$(readlink -f /usr/bin/java | sed 's:/bin/java::')
export HBASE_HOME=$HBASE_HOME
export HBASE_LOG_DIR=$LOG_DIR
export HBASE_PID_DIR=/tmp
export HBASE_MANAGES_ZK=true
export HBASE_HEAPSIZE=1000
export HBASE_OPTS=\"-XX:+UseG1GC\"
export HADOOP_HOME=$HADOOP_HOME

# 防止在某些系统上遇到的IPv6问题
export HBASE_DISABLE_HADOOP_CLASSPATH_LOOKUP=true
export HBASE_REGIONSERVERS=$HBASE_CONF_DIR/regionservers
EOF"

    # 配置hbase-site.xml
    sudo -u $HADOOP_USER bash -c "cat > $HBASE_CONF_DIR/hbase-site.xml << EOF
<?xml version=\"1.0\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
<configuration>
  <!-- 基本配置 -->
  <property>
    <name>hbase.rootdir</name>
    <value>file://$DATA_DIR</value>
  </property>
  <property>
    <name>hbase.zookeeper.property.dataDir</name>
    <value>$ZOOKEEPER_DIR</value>
  </property>
  <property>
    <name>hbase.cluster.distributed</name>
    <value>false</value>
  </property>
  <property>
    <name>hbase.tmp.dir</name>
    <value>$TMP_DIR</value>
  </property>
  <property>
    <name>hbase.unsafe.stream.capability.enforce</name>
    <value>false</value>
  </property>
  <property>
    <name>hbase.zookeeper.quorum</name>
    <value>$HOSTNAME</value>
  </property>
  <!-- 内存配置 -->
  <property>
    <name>hbase.regionserver.handler.count</name>
    <value>30</value>
  </property>
  <property>
    <name>hbase.hregion.memstore.flush.size</name>
    <value>134217728</value>
  </property>
  <!-- 网络配置 -->
  <property>
    <name>hbase.master.hostname</name>
    <value>$HOSTNAME</value>
  </property>
  <property>
    <name>hbase.regionserver.hostname</name>
    <value>$HOSTNAME</value>
  </property>
</configuration>
EOF"

    # 配置regionservers文件
    sudo -u $HADOOP_USER bash -c "cat > $HBASE_CONF_DIR/regionservers << EOF
$HOSTNAME
EOF"
}

# 配置环境变量
setup_environment() {
    info "配置环境变量..."
    
    sudo bash -c "cat > /etc/profile.d/hbase.sh << EOF
export HBASE_HOME=$HBASE_HOME
export PATH=\$PATH:\$HBASE_HOME/bin
EOF"
    
    source /etc/profile.d/hbase.sh
}

# 启动HBase服务
start_hbase() {
    info "启动HBase服务..."
    sudo -u $HADOOP_USER bash -c "
        source /etc/profile.d/hbase.sh
        $HBASE_HOME/bin/start-hbase.sh
    "
}

# 验证安装
verify_installation() {
    info "验证HBase安装..."
    
    # 等待服务启动
    sleep 10
    
    # 检查进程是否运行
    jps_output=$(sudo -u $HADOOP_USER jps)
    if echo "$jps_output" | grep -q "HMaster" && \
       echo "$jps_output" | grep -q "HRegionServer" && \
       echo "$jps_output" | grep -q "HQuorumPeer"; then
        info "HBase安装验证成功！"
        echo "=================================================="
        echo "HBase Web界面: http://$HOSTNAME:16010"
        echo "JPS进程信息:"
        echo "$jps_output"
        echo "=================================================="
        
        # 运行HBase Shell测试
        info "运行简单的HBase Shell测试..."
        
        sudo -u $HADOOP_USER bash -c "
            source /etc/profile.d/hbase.sh
            echo 'status' | $HBASE_HOME/bin/hbase shell -n
        "
    else
        warn "HBase安装验证失败，请检查日志 $LOG_DIR"
        echo "JPS进程信息:"
        echo "$jps_output"
    fi
}

# 配置HBase集成HDFS（如果有Hadoop）
configure_hbase_with_hdfs() {
    info "检查是否配置HBase与HDFS集成..."
    
    if [ -d "$HADOOP_HOME" ]; then
        info "发现Hadoop，配置HBase使用HDFS存储..."
        
        # 修改hbase-site.xml中的rootdir配置
        sudo -u $HADOOP_USER bash -c "
            sed -i 's|<value>file://.*</value>|<value>hdfs://$HOSTNAME:9000/hbase</value>|' $HBASE_CONF_DIR/hbase-site.xml
            sed -i 's|<value>false</value>|<value>true</value>|' $HBASE_CONF_DIR/hbase-site.xml
        "
        
        # 确保HDFS中有/hbase目录
        info "在HDFS中创建/hbase目录..."
        sudo -u $HADOOP_USER bash -c "
            source /etc/profile.d/hadoop.sh
            $HADOOP_HOME/bin/hdfs dfs -mkdir -p /hbase
            $HADOOP_HOME/bin/hdfs dfs -chown $HADOOP_USER:$HADOOP_USER /hbase
        "
    else
        info "未检测到Hadoop，HBase将使用本地文件系统存储"
    fi
}

# 停止HBase函数
stop_hbase() {
    info "停止HBase服务..."
    sudo -u $HADOOP_USER bash -c "
        source /etc/profile.d/hbase.sh
        $HBASE_HOME/bin/stop-hbase.sh
    "
}

# 提供管理命令帮助
show_management_help() {
    echo "=================================================="
    echo "HBase管理命令:"
    echo "启动HBase: sudo -u $HADOOP_USER $HBASE_HOME/bin/start-hbase.sh"
    echo "停止HBase: sudo -u $HADOOP_USER $HBASE_HOME/bin/stop-hbase.sh"
    echo "HBase Shell: sudo -u $HADOOP_USER $HBASE_HOME/bin/hbase shell"
    echo "查看状态: sudo -u $HADOOP_USER jps"
    echo "查看日志: ls -la $LOG_DIR"
    echo "=================================================="
}

# 主函数
main() {
    info "开始在Ubuntu 24.04上安装HBase ${HBASE_VERSION}..."
    replace_apt_sources
    update_system
    configure_network
    check_hadoop
    setup_dirs
    download_and_install_hbase
    configure_hbase
    setup_environment
    configure_hbase_with_hdfs
    start_hbase
    verify_installation
    show_management_help
    info "HBase安装完成！"
}

# 执行主函数
main
```


## 使用方法

1. 将脚本保存为 `install_hbase.sh`
2. 添加执行权限：`chmod +x install_hbase.sh`
3. 运行脚本：`sudo ./install_hbase.sh`

## 脚本说明

- 使用USTC镜像源替换默认Ubuntu软件源
- 安装OpenJDK 11（与HBase 2.5.5兼容）
- 检查Hadoop是否已安装（HBase依赖Hadoop）
- 创建必要的目录结构
- 从USTC或TUNA镜像下载HBase
- 配置单节点HBase环境
- 如果检测到Hadoop，配置HBase使用HDFS存储
- 启动HBase服务并验证安装

安装完成后，可以通过Web界面访问：
- HBase Web UI: http://localhost:16010

## 注意事项

1. 此脚本默认使用与Hadoop相同的用户（hadoop）
2. 如果已安装Hadoop，脚本会自动配置HBase使用HDFS存储
3. 如果未安装Hadoop，HBase将使用本地文件系统
4. 脚本使用默认内存设置，可能需要根据实际服务器配置调整
