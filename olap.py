import sqlite3
import pandas as pd
import matplotlib.pyplot as plt
from concurrent.futures import ProcessPoolExecutor
import numpy as np
import time
import matplotlib as mpl
from matplotlib.font_manager import FontProperties

# 配置matplotlib支持中文显示
def setup_chinese_font():
    # 方法1：尝试使用系统中文字体
    try:
        # Windows系统常见中文字体
        font_paths = [
            'C:/Windows/Fonts/simhei.ttf',  # 黑体
            'C:/Windows/Fonts/msyh.ttf',    # 微软雅黑
            'C:/Windows/Fonts/simsun.ttc',  # 宋体
        ]
        
        # 尝试加载系统中文字体
        for path in font_paths:
            try:
                chinese_font = FontProperties(fname=path)
                return chinese_font
            except:
                continue
                
        # 方法2：如果找不到特定中文字体，使用系统默认字体
        plt.rcParams['font.sans-serif'] = ['SimHei', 'Microsoft YaHei', 'SimSun', 'DejaVu Sans']
        plt.rcParams['axes.unicode_minus'] = False  # 解决负号显示问题
        return None
        
    except Exception as e:
        print(f"设置中文字体时出错: {e}")
        # 方法3：如果以上方法都失败，使用英文标签
        return None

# 连接到数据库
conn = sqlite3.connect('ecommerce.db')

# 加载数据到Pandas
def load_data():
    return pd.read_sql_query("SELECT * FROM orders", conn)

# 复杂分析任务
def analyze_sales_by_product(df):
    result = df.groupby('product_id').agg({
        'quantity': 'sum',
        'price': 'mean',
        'order_id': 'count'
    }).rename(columns={'order_id': 'total_orders'})
    result['total_revenue'] = result['quantity'] * result['price']
    return result

def analyze_customer_behavior(df):
    return df.groupby('customer_id').agg({
        'order_id': 'count',
        'price': ['sum', 'mean', 'std'],
        'quantity': 'sum'
    })

def time_trend_analysis(df):
    df['order_date'] = pd.to_datetime(df['order_date'])
    df['date'] = df['order_date'].dt.date
    return df.groupby('date').agg({
        'order_id': 'count',
        'price': 'sum'
    }).rename(columns={'order_id': 'orders_count', 'price': 'daily_revenue'})

# 使用并行处理执行多个分析任务
def parallel_analysis(df):
    with ProcessPoolExecutor(max_workers=3) as executor:
        product_future = executor.submit(analyze_sales_by_product, df)
        customer_future = executor.submit(analyze_customer_behavior, df)
        time_future = executor.submit(time_trend_analysis, df)
        
        product_analysis = product_future.result()
        customer_analysis = customer_future.result()
        time_analysis = time_future.result()
    
    return product_analysis, customer_analysis, time_analysis

# 执行分析
def run_olap_analysis():
    print("开始OLAP分析...")
    df = load_data()
    start_time = time.time()
    product_analysis, customer_analysis, time_analysis = parallel_analysis(df)
    end_time = time.time()

    print(f"OLAP分析完成，耗时: {end_time - start_time:.2f}秒")
    print("\n产品销售分析:")
    print(product_analysis)
    print("\n客户行为分析:")
    print(customer_analysis)
    print("\n时间趋势分析:")
    print(time_analysis)

    # 设置中文字体
    chinese_font = setup_chinese_font()

    # 可视化分析结果
    plt.figure(figsize=(10, 6))
    plt.bar(product_analysis.index, product_analysis['total_revenue'])
    if chinese_font:
        plt.title('各产品总收入', fontproperties=chinese_font)
        plt.xlabel('产品ID', fontproperties=chinese_font)
        plt.ylabel('总收入', fontproperties=chinese_font)
    else:
        plt.title('Product Total Revenue')
        plt.xlabel('Product ID')
        plt.ylabel('Total Revenue')
    plt.savefig('product_revenue.png')
    plt.close()

    plt.figure(figsize=(10, 6))
    orders_by_customer = customer_analysis[('order_id', 'count')]
    plt.bar(orders_by_customer.index, orders_by_customer.values)
    if chinese_font:
        plt.title('各客户订单数量', fontproperties=chinese_font)
        plt.xlabel('客户ID', fontproperties=chinese_font)
        plt.ylabel('订单数量', fontproperties=chinese_font)
    else:
        plt.title('Customer Order Count')
        plt.xlabel('Customer ID')
        plt.ylabel('Order Count')
    plt.savefig('customer_orders.png')
    plt.close()

if __name__ == "__main__":
    run_olap_analysis()
    conn.close()