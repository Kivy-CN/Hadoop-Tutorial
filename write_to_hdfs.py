#!/usr/bin/env python3

from hdfs import InsecureClient
import getpass
import socket

def get_available_ips():
    """Get a list of potential IP addresses for the current machine."""
    ips = {}
    
    # Add hostname-related IPs
    hostname = socket.gethostname()
    try:
        # Get the primary IP
        primary_ip = socket.gethostbyname(hostname)
        ips["Primary IP"] = primary_ip
    except:
        pass
    
    # Try to get all IPs for the hostname
    try:
        hostname_ips = socket.getaddrinfo(hostname, None)
        for i, ip_info in enumerate(set(info[4][0] for info in hostname_ips if info[0] == socket.AF_INET), 1):
            if ip_info not in ips.values():
                ips[f"IP {i}"] = ip_info
    except:
        pass
    
    # Add common local IPs including the original one
    common_ips = ["127.0.0.1", "192.168.56.110"]
    for i, ip in enumerate(common_ips, 1):
        if ip not in ips.values():
            ips[f"Local {i}"] = ip
    
    return ips

def select_ip(ips):
    """Allow user to select an IP address from the list."""
    print("可用的IP地址 (Available IP addresses):")
    options = list(ips.items())
    for i, (name, ip) in enumerate(options, 1):
        print(f"{i}. {name}: {ip}")
    
    print(f"{len(options) + 1}. 手动输入IP (Enter IP manually)")
    
    while True:
        try:
            choice = int(input("请选择一个选项 (Select an option): "))
            if 1 <= choice <= len(options):
                return options[choice-1][1]  # Return the IP address
            elif choice == len(options) + 1:
                return input("请输入IP地址 (Enter IP address): ")
            else:
                print("选择无效，请重试。 (Invalid choice. Please try again.)")
        except ValueError:
            print("请输入一个数字。 (Please enter a number.)")

def write_file_to_hdfs():
    # Get student information
    student_id = input("请输入你的学号 (Enter your student ID): ")
    student_name = input("请输入你的姓名 (Enter your name): ")
    # Create filename
    filename = f"{student_id}{student_name}.txt"
    
    # Create file content
    content = f"这是学号 {student_id}，姓名 {student_name} 的测试文件。\n"
    content += "This is a test file created in HDFS."
    
    # Let user select an IP address
    ips = get_available_ips()
    selected_ip = select_ip(ips)
    
    hdfs_url = f'http://{selected_ip}:9870'
    
    print(f"正在连接HDFS系统... (Connecting to HDFS at {hdfs_url}...)")
    # Connect to HDFS - uses the WebHDFS REST API under the hood
    client = InsecureClient(hdfs_url, user=getpass.getuser())
    
    # Write the file to HDFS
    print(f"正在写入文件 {filename}... (Writing file {filename}...)")
    with client.write(f'/{filename}', encoding='utf-8') as writer:
        writer.write(content)
    
    print(f"文件 {filename} 已成功写入HDFS! (File {filename} successfully written to HDFS!)")
    print(f"你可以通过访问 {hdfs_url}/explorer.html 查看该文件")

if __name__ == "__main__":
    try:
        write_file_to_hdfs()
    except Exception as e:
        print(f"发生错误: {str(e)}")
        print("\n解决方案:")
        print("1. 确保Hadoop正在运行 (确认 jps 命令显示 NameNode 正在运行)")
        print("2. 确保你已安装 'hdfs' Python库: pip install hdfs")
        print("3. 确保WebHDFS REST API已启用")