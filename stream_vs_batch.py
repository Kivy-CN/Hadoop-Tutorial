import numpy as np
import pandas as pd
import time
import matplotlib.pyplot as plt
from tqdm import tqdm
import os
plt.rcParams['font.family'] = 'serif'
plt.rcParams['font.serif'] = ['Times New Roman'] + plt.rcParams['font.serif']
plt.rcParams['svg.fonttype'] = 'none'
plt.rcParams['pdf.fonttype'] = 'truetype'
# 创建数据文件夹
if not os.path.exists('data'):
    os.makedirs('data')

def generate_data(num_rows, filename):
    """生成模拟数据并保存到CSV文件"""
    if os.path.exists(filename):
        print(f"数据文件 {filename} 已存在，跳过生成")
        return
    
    print(f"生成包含 {num_rows} 行的数据...")
    # 生成随机数据
    data = {
        'id': np.arange(num_rows),
        'value1': np.random.randn(num_rows),
        'value2': np.random.randn(num_rows),
        'value3': np.random.randn(num_rows),
        'category': np.random.choice(['A', 'B', 'C', 'D'], size=num_rows)
    }
    
    df = pd.DataFrame(data)
    df.to_csv(filename, index=False)
    print(f"数据已保存到 {filename}")

def process_batch(filename):
    """批处理方式：一次性读取全部数据并处理"""
    start_time = time.time()
    
    # 读取全部数据
    df = pd.read_csv(filename)
    
    # 进行一些典型的数据处理操作
    result = df.groupby('category').agg({
        'value1': ['mean', 'std', 'min', 'max'],
        'value2': ['mean', 'std', 'min', 'max'],
        'value3': ['mean', 'std', 'min', 'max']
    })
    
    # 额外的计算以增加处理时间
    df['calculated'] = df['value1'] * df['value2'] / (df['value3'] + 1)
    df['zscore'] = (df['value1'] - df['value1'].mean()) / df['value1'].std()
    
    # 按category计算相关性
    correlations = {}
    for category in df['category'].unique():
        subset = df[df['category'] == category]
        correlations[category] = subset[['value1', 'value2', 'value3']].corr()
    
    end_time = time.time()
    return end_time - start_time

def process_stream(filename, chunk_size):
    """流处理方式：分块读取并处理数据"""
    start_time = time.time()
    
    # 准备用于聚合的数据结构
    category_counts = {}
    category_sums = {}
    category_sum_squares = {}
    category_mins = {}
    category_maxs = {}
    
    # 分块读取并处理
    for chunk in tqdm(pd.read_csv(filename, chunksize=chunk_size), desc="流处理进度"):
        # 基本处理
        chunk['calculated'] = chunk['value1'] * chunk['value2'] / (chunk['value3'] + 1)
        
        # 更新统计数据
        for category in chunk['category'].unique():
            subset = chunk[chunk['category'] == category]
            
            if category not in category_counts:
                category_counts[category] = 0
                category_sums[category] = {'value1': 0, 'value2': 0, 'value3': 0}
                category_sum_squares[category] = {'value1': 0, 'value2': 0, 'value3': 0}
                category_mins[category] = {'value1': float('inf'), 'value2': float('inf'), 'value3': float('inf')}
                category_maxs[category] = {'value1': float('-inf'), 'value2': float('-inf'), 'value3': float('-inf')}
            
            category_counts[category] += len(subset)
            
            for col in ['value1', 'value2', 'value3']:
                category_sums[category][col] += subset[col].sum()
                category_sum_squares[category][col] += (subset[col] ** 2).sum()
                category_mins[category][col] = min(category_mins[category][col], subset[col].min())
                category_maxs[category][col] = max(category_maxs[category][col], subset[col].max())
    
    # 计算最终统计结果
    results = {}
    for category in category_counts.keys():
        results[category] = {}
        for col in ['value1', 'value2', 'value3']:
            count = category_counts[category]
            mean = category_sums[category][col] / count
            variance = (category_sum_squares[category][col] / count) - (mean ** 2)
            std = np.sqrt(variance)
            
            results[category][col] = {
                'mean': mean,
                'std': std,
                'min': category_mins[category][col],
                'max': category_maxs[category][col]
            }
    
    end_time = time.time()
    return end_time - start_time

def run_experiments():
    """运行批处理和流处理的对比实验"""
    # 定义数据规模序列（以百万行为单位）
    data_sizes = [0.1, 0.5, 1.0, 2.0, 5.0]
    chunk_sizes = [1000, 5000, 10000, 50000, 100000]
    
    results = []
    
    for size in data_sizes:
        size_in_rows = int(size * 1000000)
        filename = f"data/data_{size_in_rows}.csv"
        
        # 生成数据
        generate_data(size_in_rows, filename)
        
        # 运行批处理并记录时间
        print(f"\n数据规模: {size} 百万行")
        print("运行批处理...")
        batch_time = process_batch(filename)
        print(f"批处理时间: {batch_time:.2f} 秒")
        
        # 运行不同块大小的流处理并记录时间
        stream_times = {}
        for chunk_size in chunk_sizes:
            print(f"运行流处理 (块大小 = {chunk_size})...")
            stream_time = process_stream(filename, chunk_size)
            stream_times[chunk_size] = stream_time
            print(f"流处理时间 (块大小 = {chunk_size}): {stream_time:.2f} 秒")
        
        results.append({
            'size': size,
            'batch_time': batch_time,
            'stream_times': stream_times
        })
    
    return results

def visualize_results(results):
    """可视化处理时间的对比结果"""
    data_sizes = [r['size'] for r in results]
    batch_times = [r['batch_time'] for r in results]
    
    # 创建图表
    plt.figure(figsize=(15, 10))
    
    # 绘制批处理时间
    plt.subplot(2, 1, 1)
    plt.plot(data_sizes, batch_times, 'o-', linewidth=2, label='批处理')
    
    # 绘制不同块大小的流处理时间
    for chunk_size in results[0]['stream_times'].keys():
        stream_times = [r['stream_times'][chunk_size] for r in results]
        plt.plot(data_sizes, stream_times, 'o-', linewidth=2, label=f'流处理 (块大小={chunk_size})')
    
    plt.xlabel('数据规模 (百万行)')
    plt.ylabel('处理时间 (秒)')
    plt.title('批处理 vs 流处理: 处理时间对比')
    plt.grid(True)
    plt.legend()
    
    # 计算批处理与流处理的时间比率
    plt.subplot(2, 1, 2)
    for chunk_size in results[0]['stream_times'].keys():
        ratios = []
        for r in results:
            ratio = r['stream_times'][chunk_size] / r['batch_time']
            ratios.append(ratio)
        plt.plot(data_sizes, ratios, 'o-', linewidth=2, label=f'流处理/批处理 (块大小={chunk_size})')
    
    plt.axhline(y=1.0, color='r', linestyle='--', label='批处理基线')
    plt.xlabel('数据规模 (百万行)')
    plt.ylabel('时间比率 (流处理/批处理)')
    plt.title('流处理相对于批处理的时间比率')
    plt.grid(True)
    plt.legend()
    
    plt.tight_layout()
    plt.savefig('stream_vs_batch_comparison.svg')
    plt.close()
    
    # 创建块大小对比图
    plt.figure(figsize=(15, 8))
    
    for i, r in enumerate(results):
        chunk_sizes = list(r['stream_times'].keys())
        times = list(r['stream_times'].values())
        plt.plot(chunk_sizes, times, 'o-', linewidth=2, label=f'{r["size"]}百万行')
        
    plt.xscale('log')
    plt.xlabel('块大小 (行数)')
    plt.ylabel('处理时间 (秒)')
    plt.title('不同数据规模下流处理的块大小对比')
    plt.grid(True)
    plt.legend()
    
    plt.tight_layout()
    plt.savefig('chunk_size_comparison.svg')
    plt.close()

if __name__ == "__main__":
    print("开始流处理和批处理性能对比实验")
    results = run_experiments()
    print("\n绘制可视化结果...")
    visualize_results(results)
    print("实验完成! 可视化结果已保存到 stream_vs_batch_comparison.svg 和 chunk_size_comparison.svg") 