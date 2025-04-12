#!/bin/bash

# =========================================
# Ubuntu 24.04 Hadoop 3.4.1 安装脚本 (精简版)
# =========================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 配置变量
HADOOP_VERSION="3.4.1"
JAVA_VERSION="openjdk-11-jdk"
HADOOP_USER="hadoop"
HADOOP_HOME="/opt/hadoop"
HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
DATA_DIR="/hadoop/data"
NAMENODE_DIR="$DATA_DIR/namenode"
DATANODE_DIR="$DATA_DIR/datanode"
LOG_DIR="/hadoop/logs"
CONFIG_ONLY=false

# 获取主机名
HOSTNAME=$(hostname)
# PUBLIC_IP将由select_network_interface函数设置

# 记录日志
log_file="/tmp/hadoop_install_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$log_file") 2>&1

# 输出带颜色的信息
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

# 解析命令行参数
parse_args() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --config-only) CONFIG_ONLY=true ;;
            --help) show_help; exit 0 ;;
            *) error "未知参数: $1" ;;
        esac
        shift
    done
}

show_help() {
    echo "Hadoop 3.4.1 安装脚本 - Ubuntu 24.04 + Java 11"
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  --config-only    仅更新配置文件，不重新下载和安装Hadoop"
    echo "  --help           显示此帮助信息"
}

# 选择网络接口 - 修复后的版本
select_network_interface() {
    section "选择网络接口"
    
    # 获取所有网络接口及其IP
    echo "系统中可用的网络接口:"
    echo "----------------------"
    
    # 创建数组存储网卡及其IP
    local interfaces=()
    local ips=()
    local count=0
    
    # 使用ip addr命令获取网卡和IP信息，并去掉子网前缀
    while read -r iface ip_with_prefix; do
        # 从CIDR表示法中提取IP地址部分
        local ip=$(echo "$ip_with_prefix" | cut -d/ -f1)
        
        # 只处理有效的数据行
        if [[ -n "$iface" && -n "$ip" && "$ip" != "127.0.0.1" ]]; then
            interfaces+=("$iface")
            ips+=("$ip")
            # 显示给用户 - 简化格式避免混淆
            echo "[$count] $iface: $ip"
            count=$((count+1))
        fi
    done < <(ip -4 -o addr show | awk '{print $2, $4}')
    
    # 如果没有找到任何接口
    if [ $count -eq 0 ]; then
        warn "未找到任何可用网络接口，使用默认检测方式"
        PUBLIC_IP=$(ip route get 1 | awk '{print $7; exit}' 2>/dev/null || hostname -I | awk '{print $1}')
        info "自动检测到IP: $PUBLIC_IP"
        return
    fi
    
    # 让用户选择网卡
    local selected
    while true; do
        read -p "请选择用于Hadoop服务的网络接口 [0-$((count-1))]: " selected
        
        if [[ "$selected" =~ ^[0-9]+$ ]] && [ "$selected" -lt "$count" ]; then
            PUBLIC_IP="${ips[$selected]}"
            info "已选择 ${interfaces[$selected]}: $PUBLIC_IP 作为Hadoop服务IP"
            break
        else
            warn "无效的选择，请重试"
        fi
    done
}

# 检查系统要求
check_system() {
    section "检查系统环境"
    
    # 检查是否为Ubuntu 24.04
    if ! grep -q "Ubuntu" /etc/os-release || ! grep -q "24.04" /etc/os-release; then
        warn "此脚本专为Ubuntu 24.04设计，当前系统可能不兼容"
        read -p "是否继续? (y/n): " confirm
        if [[ $confirm != "y" && $confirm != "Y" ]]; then
            error "安装已取消"
        fi
    else
        info "系统版本: Ubuntu 24.04 √"
    fi
    
    # 检查内存
    total_mem=$(free -m | awk '/^Mem:/{print $2}')
    if [[ $total_mem -lt 2048 ]]; then
        warn "内存小于2GB (${total_mem}MB)，Hadoop性能可能受影响"
    else
        info "内存大小: ${total_mem}MB √"
    fi
    
    # 确保root权限
    if [[ $EUID -ne 0 ]]; then
        error "请使用sudo或root用户运行此脚本"
    fi
    
    info "主机名: $HOSTNAME"
}

# 更新系统并安装依赖
update_system() {
    section "更新系统和安装依赖"
    info "更新系统并安装依赖..."
    
    # 安装必要的软件包
    sudo apt update || error "更新软件源失败"
    sudo apt install -y $JAVA_VERSION openssh-server openssh-client pdsh curl wget net-tools htop ufw || error "安装依赖失败"
    
    # 设置JAVA_HOME
    JAVA_HOME_PATH=$(readlink -f /usr/bin/java | sed 's:/bin/java::')
    if [ -z "$JAVA_HOME_PATH" ] || [[ "$JAVA_HOME_PATH" != *"java-11"* ]]; then
        JAVA_HOME_PATH=$(find /usr/lib/jvm -maxdepth 1 -name "*java-11*" | head -1)
    fi
    
    if [ -n "$JAVA_HOME_PATH" ]; then
        echo "export JAVA_HOME=$JAVA_HOME_PATH" | sudo tee /etc/profile.d/jdk.sh > /dev/null
        source /etc/profile.d/jdk.sh
        info "JAVA_HOME已设置为: $JAVA_HOME_PATH"
    else
        warn "无法自动检测JAVA_HOME路径，需手动设置"
    fi
    
    # 记录JAVA_HOME以供后续使用
    JAVA_HOME_DETECTED=$JAVA_HOME_PATH
}

# 创建Hadoop用户并配置SSH
setup_hadoop_user() {
    section "创建用户和配置SSH"
    info "创建Hadoop用户并配置SSH..."
    
    # 检查用户是否存在
    if ! id -u $HADOOP_USER &>/dev/null; then
        sudo useradd -m -s /bin/bash $HADOOP_USER || error "创建用户失败"
        echo "hadoop:hadoop" | sudo chpasswd || warn "设置默认密码失败"
        info "已创建用户 $HADOOP_USER 密码默认为 'hadoop'"
    else
        info "用户 ${HADOOP_USER} 已存在，跳过创建步骤"
    fi
    
    # 确保SSH服务正确安装和运行
    sudo systemctl enable ssh
    sudo systemctl start ssh
    
    # 确保/etc/hosts正确配置
    sudo bash -c "cat > /etc/hosts << EOF
127.0.0.1 localhost
$PUBLIC_IP $HOSTNAME

# 以下是IPv6配置
::1 localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF"
    
    # 配置hadoop用户SSH免密登录
    sudo -u $HADOOP_USER bash -c "
        mkdir -p ~/.ssh
        ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
        cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
        chmod 0600 ~/.ssh/authorized_keys
        
        # 配置SSH客户端
        cat > ~/.ssh/config << EOF
Host localhost
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    User $HADOOP_USER

Host $HOSTNAME
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    User $HADOOP_USER

Host 127.0.0.1
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    User $HADOOP_USER

Host $PUBLIC_IP
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    User $HADOOP_USER
EOF
        chmod 0600 ~/.ssh/config
    "
}

# 下载并安装Hadoop
download_and_install_hadoop() {
    section "下载和安装Hadoop"
    
    # 检查是否已安装或为配置模式
    if [ "$CONFIG_ONLY" = true ]; then
        info "配置模式：跳过下载和安装"
        return
    fi
    
    if [ -d "$HADOOP_HOME" ]; then
        info "Hadoop目录已存在，跳过下载和安装步骤"
        # 确保目录权限正确
        sudo chown -R $HADOOP_USER:$HADOOP_USER $HADOOP_HOME
        return
    fi
    
    info "下载并安装Hadoop ${HADOOP_VERSION}..."
    
    # 创建一个临时目录用于下载
    local temp_dir=$(mktemp -d)
    cd $temp_dir
    
    # 尝试从不同镜像下载
    local hadoop_archive="hadoop-$HADOOP_VERSION.tar.gz"
    local mirrors=(
        "https://mirrors.ustc.edu.cn/apache/hadoop/common/hadoop-$HADOOP_VERSION/$hadoop_archive"
        "https://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-$HADOOP_VERSION/$hadoop_archive"
    )
    
    for mirror in "${mirrors[@]}"; do
        if wget --progress=bar:force -O $hadoop_archive $mirror; then
            break
        fi
    done
    
    # 解压并安装
    sudo tar -xzf $hadoop_archive || error "解压Hadoop安装包失败"
    sudo rm -rf $HADOOP_HOME
    sudo mv hadoop-$HADOOP_VERSION $HADOOP_HOME || error "移动Hadoop目录失败"
    
    # 创建必要的目录
    sudo mkdir -p $NAMENODE_DIR $DATANODE_DIR $LOG_DIR $DATA_DIR/tmp
    
    # 设置权限
    sudo chown -R $HADOOP_USER:$HADOOP_USER $HADOOP_HOME
    sudo chown -R $HADOOP_USER:$HADOOP_USER $DATA_DIR
    sudo chown -R $HADOOP_USER:$HADOOP_USER $LOG_DIR
    
    # 确保二进制文件有执行权限
    sudo chmod -R 755 $HADOOP_HOME/bin $HADOOP_HOME/sbin
    
    # 清理
    cd /
    rm -rf $temp_dir
}

# 配置Hadoop
configure_hadoop() {
    section "配置Hadoop环境"
    info "配置Hadoop环境..."
    
    # 确保目录存在
    sudo mkdir -p $NAMENODE_DIR $DATANODE_DIR $LOG_DIR $DATA_DIR/tmp
    sudo chown -R $HADOOP_USER:$HADOOP_USER $DATA_DIR $LOG_DIR
    
    # 配置hadoop-env.sh
    sudo -u $HADOOP_USER bash -c "cat > $HADOOP_CONF_DIR/hadoop-env.sh << EOF
# Java路径设置
export JAVA_HOME=$JAVA_HOME_DETECTED

# 基本环境变量
export HADOOP_HOME=$HADOOP_HOME
export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
export HADOOP_LOG_DIR=$LOG_DIR
export HADOOP_OS_TYPE=\${HADOOP_OS_TYPE:-\$(uname -s)}

# 内存配置
export HADOOP_HEAPSIZE_MAX=1024m
export HADOOP_HEAPSIZE_MIN=512m

# JVM设置
export HADOOP_OPTS=\"\$HADOOP_OPTS -Djava.net.preferIPv4Stack=true\"
EOF"

    # 配置core-site.xml - 使用选定的IP地址
    sudo -u $HADOOP_USER bash -c "cat > $HADOOP_CONF_DIR/core-site.xml << EOF
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://$PUBLIC_IP:9000</value>
        <description>HDFS的URI，使用选定的IP地址</description>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>$DATA_DIR/tmp</value>
        <description>Hadoop临时目录</description>
    </property>
</configuration>
EOF"

    # 配置hdfs-site.xml - 使用选定的IP地址
    sudo -u $HADOOP_USER bash -c "cat > $HADOOP_CONF_DIR/hdfs-site.xml << EOF
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
<configuration>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>$NAMENODE_DIR</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>$DATANODE_DIR</value>
    </property>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.permissions.enabled</name>
        <value>false</value>
    </property>
    <property>
        <name>dfs.namenode.http-address</name>
        <value>$PUBLIC_IP:9870</value>
        <description>NameNode Web UI地址</description>
    </property>
    <property>
        <name>dfs.namenode.secondary.http-address</name>
        <value>$PUBLIC_IP:9868</value>
        <description>SecondaryNameNode Web UI地址</description>
    </property>
    <property>
        <name>dfs.datanode.http.address</name>
        <value>$PUBLIC_IP:9864</value>
        <description>DataNode Web UI地址</description>
    </property>
</configuration>
EOF"

    # 配置mapred-site.xml
    sudo -u $HADOOP_USER bash -c "cat > $HADOOP_CONF_DIR/mapred-site.xml << EOF
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.jobhistory.address</name>
        <value>$HOSTNAME:10020</value>
    </property>
    <property>
        <name>mapreduce.jobhistory.webapp.address</name>
        <value>$PUBLIC_IP:19888</value>
    </property>
</configuration>
EOF"

    # 配置yarn-site.xml
    sudo -u $HADOOP_USER bash -c "cat > $HADOOP_CONF_DIR/yarn-site.xml << EOF
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>$HOSTNAME</value>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address</name>
        <value>$PUBLIC_IP:8088</value>
        <description>确保从外部可访问</description>
    </property>
    <property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>1536</value>
    </property>
</configuration>
EOF"

    # 配置workers文件
    sudo -u $HADOOP_USER bash -c "echo '$HOSTNAME' > $HADOOP_CONF_DIR/workers"

    # 创建日志目录
    sudo mkdir -p $LOG_DIR/yarn/userlogs
    sudo chown -R $HADOOP_USER:$HADOOP_USER $LOG_DIR
}

# 配置环境变量
setup_environment() {
    section "配置环境变量"
    
    # 创建环境变量配置
    sudo bash -c "cat > /etc/profile.d/hadoop.sh << EOF
export JAVA_HOME=$JAVA_HOME_DETECTED
export HADOOP_HOME=$HADOOP_HOME
export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
export PDSH_RCMD_TYPE=ssh
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
EOF"
    
    # 为当前会话加载环境变量
    source /etc/profile.d/hadoop.sh
    
    # 添加到hadoop用户的.bashrc
    sudo -u $HADOOP_USER bash -c "cat >> ~$HADOOP_USER/.bashrc << EOF

# Hadoop环境变量
export JAVA_HOME=$JAVA_HOME_DETECTED
export HADOOP_HOME=$HADOOP_HOME
export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
export PDSH_RCMD_TYPE=ssh
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
EOF"
}

# 初始化HDFS
initialize_hdfs() {
    section "初始化HDFS文件系统"
    
    # 确保目录存在
    sudo mkdir -p $NAMENODE_DIR $DATANODE_DIR
    sudo chown -R $HADOOP_USER:$HADOOP_USER $NAMENODE_DIR $DATANODE_DIR
    
    # 检查是否需要格式化
    if [ "$CONFIG_ONLY" = true ] && [ -d "$NAMENODE_DIR/current" ]; then
        info "NameNode已格式化，跳过格式化步骤"
    else
        info "格式化HDFS NameNode..."
        # 清理旧的数据目录
        sudo rm -rf $NAMENODE_DIR/* $DATANODE_DIR/*
        
        # 执行格式化
        sudo -u $HADOOP_USER bash -c "
            export JAVA_HOME=$JAVA_HOME_DETECTED
            export HADOOP_HOME=$HADOOP_HOME
            export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
            export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
            
            echo 'Y' | $HADOOP_HOME/bin/hdfs namenode -format
        "
    fi
}

# 启动Hadoop服务 - 修复了路径问题
start_hadoop() {
    section "启动Hadoop服务"
    
    # 停止可能正在运行的服务
    sudo -u $HADOOP_USER bash -c "
        export JAVA_HOME=$JAVA_HOME_DETECTED
        export HADOOP_HOME=$HADOOP_HOME
        export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
        export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
        
        $HADOOP_HOME/sbin/stop-all.sh >/dev/null 2>&1 || true
        sleep 3
    "
    
    # 创建启动脚本 - 显式使用完整路径
    sudo -u $HADOOP_USER bash -c "cat > /tmp/start_hadoop.sh << 'EOF'
#!/bin/bash
export JAVA_HOME=$JAVA_HOME_DETECTED
export HADOOP_HOME=$HADOOP_HOME
export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
export HADOOP_OPTS=\"-Djava.net.preferIPv4Stack=true\"

echo \"====== 启动HDFS服务 ======\"
$HADOOP_HOME/sbin/start-dfs.sh
sleep 5

echo \"====== 启动YARN服务 ======\"
$HADOOP_HOME/sbin/start-yarn.sh
sleep 5

echo \"====== 启动MapReduce历史服务器 ======\"
$HADOOP_HOME/bin/mapred --daemon start historyserver
sleep 2

echo \"====== 检查运行状态 ======\"
jps

# 创建基础目录
echo \"====== 创建基础目录 ======\"
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/$HADOOP_USER
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /tmp
$HADOOP_HOME/bin/hdfs dfs -chmod 777 /tmp
$HADOOP_HOME/bin/hdfs dfs -ls /

# 上传测试文件
echo \"====== 上传测试文件 ======\"
echo 'Hello Hadoop' > /tmp/test.txt
$HADOOP_HOME/bin/hdfs dfs -put /tmp/test.txt /user/$HADOOP_USER/
$HADOOP_HOME/bin/hdfs dfs -ls /user/$HADOOP_USER/

echo \"====== 服务启动完成 ======\"
echo \"HDFS Web界面: http://$PUBLIC_IP:9870\"
echo \"YARN Web界面: http://$PUBLIC_IP:8088\"
echo \"MapReduce作业历史: http://$PUBLIC_IP:19888\"
EOF"
    
    # 替换脚本中的变量为实际值
    sudo sed -i "s|\$JAVA_HOME_DETECTED|$JAVA_HOME_DETECTED|g" /tmp/start_hadoop.sh
    sudo sed -i "s|\$HADOOP_HOME|$HADOOP_HOME|g" /tmp/start_hadoop.sh
    sudo sed -i "s|\$HADOOP_CONF_DIR|$HADOOP_CONF_DIR|g" /tmp/start_hadoop.sh
    sudo sed -i "s|\$PATH|$PATH|g" /tmp/start_hadoop.sh
    sudo sed -i "s|\$HADOOP_USER|$HADOOP_USER|g" /tmp/start_hadoop.sh
    sudo sed -i "s|\$PUBLIC_IP|$PUBLIC_IP|g" /tmp/start_hadoop.sh
    
    # 执行启动脚本
    sudo chmod +x /tmp/start_hadoop.sh
    sudo -u $HADOOP_USER /tmp/start_hadoop.sh
    
    # 验证端口绑定
    info "验证端口绑定..."
    sleep 3
    sudo netstat -tulnp | grep -E "9870|8088|19888" | grep "$PUBLIC_IP" || warn "未发现服务绑定到 $PUBLIC_IP"
}

# 验证安装
verify_installation() {
    section "验证Hadoop安装"
    
    # 检查进程
    local jps_output=$(sudo -u $HADOOP_USER jps 2>/dev/null || echo "无法执行jps命令")
    echo "当前Java进程:"
    echo "$jps_output"
    
    # 验证网络绑定配置
    info "验证网络绑定配置..."
    echo "配置的IP地址: $PUBLIC_IP"
    sudo netstat -tulnp | grep -E "9870|9000|8088" | grep "$PUBLIC_IP" || warn "未找到绑定到 $PUBLIC_IP 的Hadoop服务"
    
    # 总结
    echo ""
    echo "====================== Hadoop安装完成 ======================"
    echo "HDFS Web界面: http://$PUBLIC_IP:9870"
    echo "YARN Web界面: http://$PUBLIC_IP:8088"
    echo "MapReduce作业历史: http://$PUBLIC_IP:19888"
    echo ""
    echo "HDFS命令示例:"
    echo "  hdfs dfs -ls /              # 列出根目录"
    echo "  hdfs dfs -put <本地文件> <HDFS路径>  # 上传文件"
    echo "================================================================="
}

# 主函数
main() {
    # 解析命令行参数
    parse_args "$@"
    
    # 显示脚本标题
    echo -e "${BLUE}=====================================================${NC}"
    echo -e "${BLUE}     Hadoop ${HADOOP_VERSION} 安装脚本 - Ubuntu 24.04      ${NC}"
    echo -e "${BLUE}=====================================================${NC}"
    
    # 执行安装流程
    check_system
    select_network_interface  # 添加网卡选择功能
    
    if [ "$CONFIG_ONLY" = true ]; then
        info "仅更新配置模式"
        update_system
        setup_hadoop_user
        configure_hadoop
        setup_environment
        initialize_hdfs
        start_hadoop
        verify_installation
    else
        update_system
        setup_hadoop_user
        download_and_install_hadoop
        configure_hadoop
        setup_environment
        initialize_hdfs
        start_hadoop
        verify_installation
    fi
    
    info "日志文件保存在: $log_file"
    info "Hadoop安装过程完成!"
}

# 执行主函数，传递所有命令行参数
main "$@"