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

# 创建用户和目录
setup_user_and_dirs() {
    info "设置用户和目录..."
    
    # 检查用户是否存在
    if ! id -u $HADOOP_USER &>/dev/null; then
        sudo useradd -m -s /bin/bash $HADOOP_USER
        echo "请为${HADOOP_USER}用户设置密码:"
        sudo passwd $HADOOP_USER
    else
        info "用户${HADOOP_USER}已存在，跳过创建步骤"
    fi
    
    # 创建必要的目录
    sudo mkdir -p $DATA_DIR $ZOOKEEPER_DIR $LOG_DIR $TMP_DIR
    
    # 设置权限
    sudo chown -R $HADOOP_USER:$HADOOP_USER $DATA_DIR $LOG_DIR $TMP_DIR
}

# 下载并安装HBase
download_and_install_hbase() {
    info "下载并安装HBase ${HBASE_VERSION}..."
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
    
    # 解压并安装
    info "解压并安装HBase..."
    sudo tar -xzf hbase-$HBASE_VERSION-bin.tar.gz
    sudo mv hbase-$HBASE_VERSION $HBASE_HOME
    
    # 设置权限
    sudo chown -R $HADOOP_USER:$HADOOP_USER $HBASE_HOME
    
    # 清理下载文件
    rm -f hbase-$HBASE_VERSION-bin.tar.gz
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
export HBASE_OPTS=\"-XX:+UseConcMarkSweepGC\"
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
    <value>localhost</value>
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
</configuration>
EOF"

    # 配置regionservers文件
    sudo -u $HADOOP_USER bash -c "cat > $HBASE_CONF_DIR/regionservers << EOF
localhost
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
        echo "HBase Web界面: http://localhost:16010"
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
            sed -i 's|<value>file://.*</value>|<value>hdfs://localhost:9000/hbase</value>|' $HBASE_CONF_DIR/hbase-site.xml
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
    check_hadoop
    setup_user_and_dirs
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