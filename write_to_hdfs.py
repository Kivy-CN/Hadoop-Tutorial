#!/usr/bin/env python3
# filepath: write_to_hdfs.py

from hdfs import InsecureClient
import getpass

def write_file_to_hdfs():
    # Get student information
    student_id = input("请输入你的学号 (Enter your student ID): ")
    student_name = input("请输入你的姓名 (Enter your name): ")
    # Create filename
    filename = f"{student_id}{student_name}.txt"
    
    # Create file content
    content = f"这是学号 {student_id}，姓名 {student_name} 的测试文件。\n"
    content += "This is a test file created in HDFS."
    
    print(f"正在连接HDFS系统... (Connecting to HDFS...)")
    # Connect to HDFS - uses the WebHDFS REST API under the hood
    client = InsecureClient('http://127.0.0.1:9870', user=getpass.getuser())
    
    # Write the file to HDFS
    print(f"正在写入文件 {filename}... (Writing file {filename}...)")
    with client.write(f'/{filename}', encoding='utf-8') as writer:
        writer.write(content)
    
    print(f"文件 {filename} 已成功写入HDFS! (File {filename} successfully written to HDFS!)")
    print(f"你可以通过访问 http://127.0.0.1:9870/explorer.html 查看该文件")

if __name__ == "__main__":
    try:
        write_file_to_hdfs()
    except Exception as e:
        print(f"发生错误: {str(e)}")
        print("\n解决方案:")
        print("1. 确保Hadoop正在运行 (确认 jps 命令显示 NameNode 正在运行)")
        print("2. 确保你已安装 'hdfs' Python库: pip install hdfs")
        print("3. 确保WebHDFS REST API已启用")