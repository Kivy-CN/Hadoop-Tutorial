import time
import numpy as np
import matplotlib.pyplot as plt
from multiprocessing import Pool
import math

# 设置中文显示
plt.rcParams.update({'font.sans-serif': ['SimHei'], 'axes.unicode_minus': False})
# 可以调整这个参数来改变可并行化的部分比例
PARALLEL_PORTION = 0.9  # 90% 的工作可以并行化

# 总工作量
TOTAL_WORK = 10**9 #修改这个参数来改变工作量，试试 10^7, 10^8, 10^9

# 模拟计算密集型工作的函数
def compute_work(args):
    start, end = args
    result = 0
    for i in range(start, end):
        result += math.sin(i) * math.cos(i)
    return result

# 执行包含串行和并行部分的任务
def execute_task(num_processes):
    # 串行部分的工作
    serial_work = int(TOTAL_WORK * (1 - PARALLEL_PORTION))
    # 并行部分的工作
    parallel_work = TOTAL_WORK - serial_work
    
    start_time = time.time()
    
    # 串行部分
    serial_result = compute_work((0, serial_work))
    
    # 并行部分
    parallel_results = []
    if num_processes > 1:
        chunk_size = parallel_work // num_processes
        chunks = []
        for i in range(num_processes):
            start = serial_work + i * chunk_size
            end = serial_work + (i + 1) * chunk_size if i < num_processes - 1 else TOTAL_WORK
            chunks.append((start, end))
        
        with Pool(processes=num_processes) as pool:
            parallel_results = pool.map(compute_work, chunks)
    else:
        # 单进程情况
        parallel_results.append(compute_work((serial_work, TOTAL_WORK)))
    
    end_time = time.time()
    
    return end_time - start_time

# 计算阿姆达尔定律预测的理论加速比
def amdahl_speedup(p, n):
    return 1 / ((1 - p) + p/n)

# 测试不同进程数
def main():
    process_counts = [1, 2, 4, 8, 16, 32]
    execution_times = []
    speedups = []
    theoretical_speedups = []
    
    # 执行测试
    for num_processes in process_counts:
        print(f"测试 {num_processes} 个进程...")
        execution_time = execute_task(num_processes)
        execution_times.append(execution_time)
        
        # 计算相对于单进程的加速比
        if num_processes == 1:
            base_time = execution_time
            speedups.append(1.0)  # 单进程的加速比是1
        else:
            speedup = base_time / execution_time
            speedups.append(speedup)
        
        # 计算理论加速比
        theoretical_speedup = amdahl_speedup(PARALLEL_PORTION, num_processes)
        theoretical_speedups.append(theoretical_speedup)
        
        print(f"  执行时间: {execution_time:.4f} 秒")
        print(f"  实际加速比: {speedups[-1]:.4f}x")
        print(f"  理论加速比: {theoretical_speedup:.4f}x")
    
    # 绘制结果
    plt.figure(figsize=(12, 10))
    
    # 绘制执行时间
    plt.subplot(2, 1, 1)
    plt.bar([str(n) for n in process_counts], execution_times, color='skyblue')
    plt.title('执行时间与进程数的关系')
    plt.xlabel('进程数')
    plt.ylabel('执行时间 (秒)')
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    
    # 在每个柱形上添加时间数值
    for i, time_val in enumerate(execution_times):
        plt.text(i, time_val + 0.05, f'{time_val:.2f}s', ha='center')
    
    # 绘制加速比
    plt.subplot(2, 1, 2)
    x = range(len(process_counts))
    width = 0.35
    
    plt.bar([i - width/2 for i in x], speedups, width, label='实际加速比', color='coral')
    plt.bar([i + width/2 for i in x], theoretical_speedups, width, label='理论加速比 (阿姆达尔定律)', color='lightgreen')
    
    plt.title(f'加速比与进程数的关系 (并行部分: {PARALLEL_PORTION*100}%)')
    plt.xlabel('进程数')
    plt.ylabel('加速比 (相对于单进程)')
    plt.xticks(x, [str(n) for n in process_counts])
    plt.legend()
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    
    # 在每个柱形上添加加速比数值
    for i, speedup in enumerate(speedups):
        plt.text(i - width/2, speedup + 0.05, f'{speedup:.2f}x', ha='center')
    
    for i, th_speedup in enumerate(theoretical_speedups):
        plt.text(i + width/2, th_speedup + 0.05, f'{th_speedup:.2f}x', ha='center')
    
    plt.tight_layout()
    plt.savefig('amdahls_law_demonstration.png')
    plt.show()

if __name__ == "__main__":
    main()