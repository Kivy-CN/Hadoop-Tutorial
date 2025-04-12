#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

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

# 配置变量
HADOOP_USER="hadoop"
HBASE_HOME="/opt/hbase"
THRIFT_PORT=9090

# 获取网络接口
get_interfaces() {
    interfaces=($(ip -o -4 addr show | awk '{print $2 ":" $4}' | cut -d/ -f1 | grep -v "lo"))
    
    echo "可用的网络接口:"
    for i in "${!interfaces[@]}"; do
        echo "$((i+1)). ${interfaces[$i]}"
    done
    
    # 默认使用localhost
    BIND_ADDRESS="localhost"
    
    # 询问用户是否要选择特定网络接口
    read -p "请选择Thrift服务绑定的网络接口 (1-${#interfaces[@]}, 默认为localhost): " interface_num
    if [[ "$interface_num" =~ ^[0-9]+$ ]] && [ "$interface_num" -ge 1 ] && [ "$interface_num" -le "${#interfaces[@]}" ]; then
        selected_interface=${interfaces[$((interface_num-1))]}
        BIND_ADDRESS=$(echo $selected_interface | cut -d: -f2)
        info "已选择网络接口: $selected_interface, Thrift将绑定到IP: $BIND_ADDRESS"
    else
        info "将使用localhost作为Thrift绑定地址"
    fi
}

# 检查Thrift是否已运行
check_thrift_running() {
    if sudo -u $HADOOP_USER netstat -tuln | grep -q ":$THRIFT_PORT "; then
        info "HBase Thrift服务已在端口 $THRIFT_PORT 上运行"
        return 0
    else
        warn "HBase Thrift服务未运行"
        return 1
    fi
}

# 启动Thrift服务
start_thrift() {
    info "正在启动HBase Thrift服务，绑定到 $BIND_ADDRESS:$THRIFT_PORT..."
    
    # 停止现有的Thrift服务（如果有）
    sudo -u $HADOOP_USER "$HBASE_HOME/bin/hbase-daemon.sh" stop thrift || true
    sleep 2
    
    # 启动新的Thrift服务，绑定到指定接口
    sudo -u $HADOOP_USER "$HBASE_HOME/bin/hbase-daemon.sh" start thrift -b "$BIND_ADDRESS" -p "$THRIFT_PORT"
    
    # 检查是否成功启动
    sleep 3
    if check_thrift_running; then
        info "HBase Thrift服务已成功启动"
    else
        error "启动HBase Thrift服务失败，请检查HBase日志"
    fi
}

# 主函数
main() {
    info "HBase Thrift服务管理工具"
    
    # 检查HBase是否安装
    if [ ! -d "$HBASE_HOME" ]; then
        error "HBase未安装在 $HBASE_HOME"
    fi
    
    # 检查Thrift服务是否已运行
    if check_thrift_running; then
        read -p "Thrift服务已运行，是否重启? (y/n): " restart
        if [[ "$restart" == "y" ]]; then
            get_interfaces
            start_thrift
        else
            info "保持现有Thrift服务运行"
        fi
    else
        get_interfaces
        start_thrift
    fi
    
    # 显示连接信息
    echo "=================================================="
    echo "HBase Thrift服务现在运行在: $BIND_ADDRESS:$THRIFT_PORT"
    echo "您现在可以运行Python脚本连接HBase:"
    echo "python3 hbase_gaokao.py"
    echo "=================================================="
}

# 执行主函数
main