#!/bin/bash

# Ubuntu 24.04 Hadoop安装脚本
# 使用USTC和TUNA镜像源以提高在中国大陆的下载速度

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
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
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup || warn "备份sources.list失败，继续执行"
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
    sudo apt update || error "更新软件源失败"
    sudo apt upgrade -y || warn "升级软件包失败，继续执行"
    sudo apt install -y $JAVA_VERSION openssh-server openssh-client pdsh curl wget net-tools || error "安装依赖失败"
}

# 创建Hadoop用户并配置SSH
setup_hadoop_user() {
    info "创建Hadoop用户并配置SSH..."
    # 检查用户是否存在
    if ! id -u $HADOOP_USER &>/dev/null; then
        sudo useradd -m -s /bin/bash $HADOOP_USER || error "创建用户失败"
        echo "请为${HADOOP_USER}用户设置密码:"
        sudo passwd $HADOOP_USER || warn "设置密码失败，但将继续安装过程"
    else
        info "用户${HADOOP_USER}已存在，跳过创建步骤"
    fi
    
    # 确保SSH服务正确安装和运行
    info "确保SSH服务正确安装和运行..."
    sudo systemctl enable ssh || warn "启用SSH服务失败"
    sudo systemctl start ssh || warn "启动SSH服务失败"
    
    # 检查SSH服务状态
    if ! systemctl is-active --quiet ssh; then
        warn "SSH服务未在运行，尝试重新配置和启动..."
        sudo apt purge -y openssh-server
        sudo apt install -y openssh-server
        sudo systemctl enable ssh
        sudo systemctl start ssh
        
        if ! systemctl is-active --quiet ssh; then
            error "SSH服务无法启动，请手动检查SSH配置"
        fi
    else
        info "SSH服务已在运行"
    fi
    
    # 确保本地hostname解析正确
    info "配置本地主机名解析..."
    hostname=$(hostname)
    if ! grep -q "127.0.0.1 $hostname" /etc/hosts; then
        echo "127.0.0.1 $hostname" | sudo tee -a /etc/hosts
    fi
    if ! grep -q "127.0.0.1 localhost" /etc/hosts; then
        echo "127.0.0.1 localhost" | sudo tee -a /etc/hosts
    fi
    
    # 为hadoop用户配置SSH免密登录
    sudo -u $HADOOP_USER bash -c "
        mkdir -p ~/.ssh
        ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
        cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
        chmod 0600 ~/.ssh/authorized_keys
        
        # 添加SSH客户端配置
        echo 'Host *
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null' > ~/.ssh/config
        chmod 0600 ~/.ssh/config
    " || warn "配置SSH失败，但将继续安装过程"
    
    # 测试SSH连接
    info "测试SSH本地连接..."
    ssh_test_output=$(sudo -u $HADOOP_USER ssh -o ConnectTimeout=5 localhost echo "SSH连接测试成功" 2>&1)
    if [[ "$ssh_test_output" == *"SSH连接测试成功"* ]]; then
        info "SSH连接测试成功"
    else
        warn "SSH连接测试失败: $ssh_test_output"
        warn "尝试另一种连接方法..."
        sudo -u $HADOOP_USER ssh -o ConnectTimeout=5 127.0.0.1 echo "SSH连接测试成功" || warn "SSH连接到127.0.0.1也失败"
        
        # 如果仍然失败，提供详细的错误信息
        warn "请检查SSH配置:"
        warn "1. SSH服务状态: $(systemctl status ssh | grep Active)"
        warn "2. SSH配置文件: $(grep "PermitRootLogin\|PasswordAuthentication" /etc/ssh/sshd_config)"
        warn "3. 防火墙状态: $(sudo ufw status)"
    fi
}

# 下载并安装Hadoop
download_and_install_hadoop() {
    info "下载并安装Hadoop ${HADOOP_VERSION}..."
    local download_success=false
    
    # 尝试从USTC镜像下载
    info "尝试从USTC镜像下载..."
    if wget -c https://mirrors.ustc.edu.cn/apache/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz; then
        download_success=true
    else
        warn "USTC镜像下载失败，尝试TUNA镜像..."
        # 尝试从TUNA镜像下载
        if wget -c https://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz; then
            download_success=true
        else
            warn "TUNA镜像下载失败，尝试Apache官方镜像..."
            # 尝试从Apache官方镜像下载
            if wget -c https://dlcdn.apache.org/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz; then
                download_success=true
            else
                error "所有下载源尝试失败，请检查网络连接或Hadoop版本是否存在"
            fi
        fi
    fi
    
    # 解压并安装
    info "解压并安装Hadoop..."
    sudo tar -xzf hadoop-$HADOOP_VERSION.tar.gz || error "解压Hadoop安装包失败"
    sudo rm -rf $HADOOP_HOME 2>/dev/null || true  # 如果目录已存在先删除
    sudo mv hadoop-$HADOOP_VERSION $HADOOP_HOME || error "移动Hadoop目录失败"
    
    # 创建必要的目录
    sudo mkdir -p $NAMENODE_DIR $DATANODE_DIR $LOG_DIR || error "创建数据目录失败"
    
    # 设置权限
    sudo chown -R $HADOOP_USER:$HADOOP_USER $HADOOP_HOME || warn "修改Hadoop目录权限失败"
    sudo chown -R $HADOOP_USER:$HADOOP_USER $DATA_DIR || warn "修改数据目录权限失败"
    sudo chown -R $HADOOP_USER:$HADOOP_USER $LOG_DIR || warn "修改日志目录权限失败"
    
    # 清理下载文件
    rm -f hadoop-$HADOOP_VERSION.tar.gz
}

# 配置Hadoop
configure_hadoop() {
    info "配置Hadoop环境..."
    
    # 配置hadoop-env.sh
    sudo -u $HADOOP_USER bash -c "cat > $HADOOP_CONF_DIR/hadoop-env.sh << EOF
export JAVA_HOME=\$(readlink -f /usr/bin/java | sed 's:/bin/java::')
export HADOOP_HOME=$HADOOP_HOME
export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
export HADOOP_LOG_DIR=$LOG_DIR
export HADOOP_PID_DIR=/tmp
export HADOOP_HEAPSIZE=1000
export HADOOP_NAMENODE_OPTS=\"-Dhadoop.security.logger=INFO,RFAS -Xmx1024m\"
export HADOOP_DATANODE_OPTS=\"-Dhadoop.security.logger=ERROR,RFAS -Xmx1024m\"
export PDSH_RCMD_TYPE=ssh
EOF" || warn "配置hadoop-env.sh失败"

    # 配置core-site.xml
    sudo -u $HADOOP_USER bash -c "cat > $HADOOP_CONF_DIR/core-site.xml << EOF
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
    <property>
        <name>io.file.buffer.size</name>
        <value>131072</value>
    </property>
</configuration>
EOF" || warn "配置core-site.xml失败"

    # 配置hdfs-site.xml
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
</configuration>
EOF" || warn "配置hdfs-site.xml失败"

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
        <name>mapreduce.application.classpath</name>
        <value>\$HADOOP_HOME/share/hadoop/mapreduce/*:\$HADOOP_HOME/share/hadoop/mapreduce/lib/*</value>
    </property>
</configuration>
EOF" || warn "配置mapred-site.xml失败"

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
        <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
        <value>org.apache.hadoop.mapred.ShuffleHandler</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>localhost</value>
    </property>
</configuration>
EOF" || warn "配置yarn-site.xml失败"

    # 配置workers文件
    sudo -u $HADOOP_USER bash -c "cat > $HADOOP_CONF_DIR/workers << EOF
localhost
EOF" || warn "配置workers文件失败"
}

# 配置环境变量
setup_environment() {
    info "配置环境变量..."
    
    sudo bash -c "cat > /etc/profile.d/hadoop.sh << EOF
export HADOOP_HOME=$HADOOP_HOME
export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
EOF" || warn "配置环境变量失败"
    
    # 加载环境变量
    export HADOOP_HOME=$HADOOP_HOME
    export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
    export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
}

# 初始化HDFS
initialize_hdfs() {
    info "初始化HDFS NameNode..."
    sudo -u $HADOOP_USER bash -c "
        export HADOOP_HOME=$HADOOP_HOME
        export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
        export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
        $HADOOP_HOME/bin/hdfs namenode -format
    " || warn "初始化HDFS失败"
}

# 启动Hadoop服务
start_hadoop() {
    info "启动Hadoop服务..."
    
    # 再次验证SSH连接
    info "在启动服务前验证SSH连接..."
    ssh_test=$(sudo -u $HADOOP_USER ssh -o ConnectTimeout=5 localhost echo "OK" 2>&1)
    if [[ "$ssh_test" != "OK" ]]; then
        warn "SSH连接测试失败! 将使用替代方式启动Hadoop..."
        warn "SSH连接问题: $ssh_test"
        
        # 使用直接命令而不是启动脚本
        info "直接启动Hadoop服务..."
        sudo -u $HADOOP_USER bash -c "
            export HADOOP_HOME=$HADOOP_HOME
            export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
            export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
            
            # 直接启动服务
            $HADOOP_HOME/bin/hdfs --daemon start namenode
            $HADOOP_HOME/bin/hdfs --daemon start datanode
            $HADOOP_HOME/bin/yarn --daemon start resourcemanager
            $HADOOP_HOME/bin/yarn --daemon start nodemanager
        " || warn "启动Hadoop服务失败"
        return
    fi
    
    # 正常启动Hadoop
    sudo -u $HADOOP_USER bash -c "
        export HADOOP_HOME=$HADOOP_HOME
        export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
        export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
        
        # 使用PDSH_RCMD_TYPE=ssh以确保使用ssh
        export PDSH_RCMD_TYPE=ssh
        
        # 启动HDFS和YARN
        $HADOOP_HOME/sbin/start-dfs.sh
        $HADOOP_HOME/sbin/start-yarn.sh
    " || warn "启动Hadoop服务失败"
}

# 验证安装
verify_installation() {
    info "验证Hadoop安装..."
    
    # 等待服务启动
    sleep 15
    
    # 检查进程是否运行
    jps_output=$(sudo -u $HADOOP_USER jps 2>/dev/null || echo "jps命令执行失败")
    if echo "$jps_output" | grep -q "NameNode" && \
       echo "$jps_output" | grep -q "DataNode" && \
       echo "$jps_output" | grep -q "ResourceManager" && \
       echo "$jps_output" | grep -q "NodeManager"; then
        info "Hadoop安装验证成功！"
        echo "=================================================="
        echo "HDFS Web界面: http://localhost:9870"
        echo "YARN Web界面: http://localhost:8088"
        echo "JPS进程信息:"
        echo "$jps_output"
        echo "=================================================="
    else
        warn "Hadoop安装验证失败，请检查日志"
        echo "JPS进程信息:"
        echo "$jps_output"
        
        # 提供一些可能的问题排查提示
        echo "可能的问题排查建议:"
        echo "1. 检查SSH免密登录是否配置正确"
        echo "   尝试: sudo -u $HADOOP_USER ssh localhost"
        echo "2. 检查Java是否正确安装"
        echo "   尝试: java -version"
        echo "3. 检查防火墙是否允许Hadoop端口"
        echo "   尝试: sudo ufw status"
        echo "4. 查看Hadoop日志文件: $LOG_DIR"
        
        # 尝试手动启动进程
        echo "尝试手动启动进程..."
        if ! echo "$jps_output" | grep -q "NameNode"; then
            echo "启动NameNode..."
            sudo -u $HADOOP_USER $HADOOP_HOME/bin/hdfs --daemon start namenode
        fi
        if ! echo "$jps_output" | grep -q "DataNode"; then
            echo "启动DataNode..."
            sudo -u $HADOOP_USER $HADOOP_HOME/bin/hdfs --daemon start datanode
        fi
        if ! echo "$jps_output" | grep -q "ResourceManager"; then
            echo "启动ResourceManager..."
            sudo -u $HADOOP_USER $HADOOP_HOME/bin/yarn --daemon start resourcemanager
        fi
        if ! echo "$jps_output" | grep -q "NodeManager"; then
            echo "启动NodeManager..."
            sudo -u $HADOOP_USER $HADOOP_HOME/bin/yarn --daemon start nodemanager
        fi
        
        # 再次检查进程
        sleep 5
        echo "重新检查进程..."
        jps_output2=$(sudo -u $HADOOP_USER jps 2>/dev/null || echo "jps命令执行失败")
        echo "$jps_output2"
    fi
}

# 主函数
main() {
    # 移除set -e，转而使用更细粒度的错误处理
    info "开始在Ubuntu 24.04上安装Hadoop ${HADOOP_VERSION}..."
    replace_apt_sources
    update_system
    setup_hadoop_user
    download_and_install_hadoop
    configure_hadoop
    setup_environment
    initialize_hdfs
    start_hadoop
    verify_installation
    info "Hadoop安装完成！"
}

# 执行主函数
main