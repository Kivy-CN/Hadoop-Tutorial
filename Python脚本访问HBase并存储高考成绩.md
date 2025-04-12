# Python脚本访问HBase并存储高考成绩

这个Python脚本将连接到本地安装的HBase，创建一个表格来存储高考成绩，并提供网卡选择功能。

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import happybase
import socket
import subprocess
import re
import sys
import os
from tabulate import tabulate

# 颜色定义
GREEN = '\033[0;32m'
YELLOW = '\033[0;33m'
RED = '\033[0;31m'
NC = '\033[0m'  # 无颜色

def print_info(message):
    """打印信息"""
    print(f"{GREEN}[INFO]{NC} {message}")

def print_warn(message):
    """打印警告"""
    print(f"{YELLOW}[WARN]{NC} {message}")

def print_error(message):
    """打印错误并退出"""
    print(f"{RED}[ERROR]{NC} {message}")
    sys.exit(1)

def get_interfaces():
    """获取所有可用的网络接口和IP"""
    interfaces = []
    
    try:
        # 在Linux系统上使用ip命令
        if os.name == 'posix':
            output = subprocess.check_output(["ip", "-o", "-4", "addr", "show"]).decode('utf-8')
            for line in output.split('\n'):
                if line:
                    parts = line.split()
                    iface = parts[1]
                    ip = parts[3].split('/')[0]
                    if iface != 'lo':  # 排除回环接口
                        interfaces.append((iface, ip))
        # 在Windows系统上使用ipconfig命令
        elif os.name == 'nt':
            output = subprocess.check_output(["ipconfig"]).decode('utf-8')
            iface = None
            for line in output.split('\n'):
                if line.strip():
                    if ':' in line and 'adapter' in line.lower():
                        iface = line.split(':')[0].strip()
                    elif 'IPv4' in line and iface:
                        ip = line.split(':')[1].strip()
                        interfaces.append((iface, ip))
    except Exception as e:
        print_warn(f"获取网络接口时出错: {e}")
        print_warn("将使用默认的localhost")
    
    return interfaces

def select_interface():
    """让用户选择网络接口"""
    interfaces = get_interfaces()
    
    if not interfaces:
        print_warn("未检测到网络接口，将使用localhost")
        return "localhost"
    
    print("可用的网络接口:")
    for i, (iface, ip) in enumerate(interfaces, 1):
        print(f"{i}. {iface}: {ip}")
    
    print(f"{len(interfaces) + 1}. 使用localhost")
    
    while True:
        try:
            choice = input("请选择网络接口 [默认为localhost]: ").strip()
            if not choice:
                return "localhost"
            
            choice = int(choice)
            if 1 <= choice <= len(interfaces):
                return interfaces[choice-1][1]
            elif choice == len(interfaces) + 1:
                return "localhost"
            else:
                print_warn("无效选择，请重新输入")
        except ValueError:
            print_warn("请输入数字")

def create_table(connection, table_name, column_families):
    """创建HBase表，如果不存在"""
    try:
        tables = connection.tables()
        # 将bytes转换为字符串
        tables = [t.decode('utf-8') if isinstance(t, bytes) else t for t in tables]
        
        if table_name in tables:
            print_info(f"表 '{table_name}' 已存在")
        else:
            connection.create_table(table_name, column_families)
            print_info(f"已创建表 '{table_name}'")
    except Exception as e:
        print_error(f"创建表时出错: {e}")

def input_exam_scores():
    """输入高考成绩"""
    print_info("请输入你的高考成绩数据")
    scores = {}
    
    subjects = [
        "语文", "数学", "英语", "物理", "化学", "生物", 
        "政治", "历史", "地理", "总分"
    ]
    
    try:
        student_name = input("请输入你的姓名: ").strip()
        exam_year = input("请输入高考年份 [2024]: ").strip() or "2024"
        
        for subject in subjects:
            if subject == "总分":
                print("现在请输入总分:")
            score = input(f"{subject}分数: ").strip()
            if score:
                try:
                    score = float(score)
                    scores[subject] = score
                except ValueError:
                    print_warn(f"无效的分数输入: {score}，已跳过")
    except KeyboardInterrupt:
        print("\n已取消输入")
        sys.exit(0)
    
    return student_name, exam_year, scores

def main():
    print_info("高考成绩HBase存储程序")
    
    # 选择网络接口
    host = select_interface()
    print_info(f"将使用 {host} 连接HBase")
    
    # 连接到HBase
    try:
        connection = happybase.Connection(host=host, port=9090, timeout=10000)
        print_info("已成功连接到HBase")
    except Exception as e:
        print_error(f"连接HBase失败: {e}")
        print_warn("请确保：")
        print_warn("1. HBase服务正在运行")
        print_warn("2. Thrift服务已启动 (使用 'hbase thrift start' 命令)")
        print_warn("3. 选择的网络接口能够连接到HBase")
        sys.exit(1)
    
    # 创建表
    table_name = 'gaokao_scores'
    column_families = {
        'info': dict(),      # 基本信息
        'scores': dict(),    # 分数信息
    }
    
    create_table(connection, table_name, column_families)
    
    # 获取表对象
    table = connection.table(table_name)
    
    # 输入高考成绩
    student_name, exam_year, scores = input_exam_scores()
    
    # 生成行键（使用姓名+年份）
    row_key = f"{student_name}_{exam_year}"
    
    # 存储数据
    data = {
        b'info:name': student_name.encode('utf-8'),
        b'info:year': exam_year.encode('utf-8')
    }
    
    # 添加分数
    for subject, score in scores.items():
        data[f'scores:{subject}'.encode('utf-8')] = str(score).encode('utf-8')
    
    # 写入数据
    try:
        table.put(row_key.encode('utf-8'), data)
        print_info(f"已成功保存 {student_name} 的高考成绩")
    except Exception as e:
        print_error(f"保存数据失败: {e}")
    
    # 读取并显示数据
    try:
        print_info("从HBase读取数据:")
        row = table.row(row_key.encode('utf-8'))
        
        # 准备显示数据
        info_data = []
        scores_data = []
        
        # 提取基本信息
        name = row.get(b'info:name', b'').decode('utf-8')
        year = row.get(b'info:year', b'').decode('utf-8')
        info_data.append(["姓名", name])
        info_data.append(["年份", year])
        
        # 提取分数信息
        for key, value in row.items():
            if key.startswith(b'scores:'):
                subject = key.decode('utf-8').split(':')[1]
                score = value.decode('utf-8')
                scores_data.append([subject, score])
        
        # 显示信息
        print("\n基本信息:")
        print(tabulate(info_data, headers=["字段", "值"], tablefmt="grid"))
        
        print("\n高考成绩:")
        print(tabulate(scores_data, headers=["科目", "分数"], tablefmt="grid"))
        
    except Exception as e:
        print_error(f"读取数据失败: {e}")
    
    connection.close()

if __name__ == "__main__":
    main()
```

## 使用说明

1. 安装必要的依赖:
   ```bash
   sudo pip3 install happybase tabulate
   ```

2. 启动HBase的Thrift服务(必须先启动才能用Python连接):
   ```bash
   sudo -u hadoop /opt/hbase/bin/hbase thrift start
   ```

3. 执行Python脚本:
   ```bash
   python3 hbase_gaokao.py
   ```

4. 脚本运行过程:
   - 列出可用网络接口供选择
   - 连接到HBase服务
   - 创建`gaokao_scores`表(如果不存在)
   - 引导您输入高考成绩信息
   - 将数据保存到HBase
   - 读取并显示保存的数据

## 注意事项

1. 确保HBase服务正在运行
2. 需要启动HBase的Thrift服务
3. 如果连接失败，请检查选择的网络接口是否正确
4. 对于表的列族设计，使用了`info`存储基本信息和`scores`存储各科分数