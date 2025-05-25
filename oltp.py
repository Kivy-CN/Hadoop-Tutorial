import sqlite3
import threading
import time
from datetime import datetime

# 创建本地数据库
conn = sqlite3.connect('ecommerce.db', check_same_thread=False)
cursor_lock = threading.Lock()  # 创建锁来同步数据库访问

# 创建表
with cursor_lock:
    cursor = conn.cursor()
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS orders (
        order_id INTEGER PRIMARY KEY,
        customer_id INTEGER,
        product_id INTEGER,
        quantity INTEGER,
        price REAL,
        order_date TEXT
    )
    ''')
    conn.commit()
    cursor.close()

# 模拟事务处理
def process_order(order_id, customer_id, product_id, quantity, price):
    try:
        order_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with cursor_lock:  # 使用锁来同步数据库访问
            cursor = conn.cursor()  # 为每个事务创建新的cursor
            cursor.execute(
                "INSERT INTO orders VALUES (?, ?, ?, ?, ?, ?)",
                (order_id, customer_id, product_id, quantity, price, order_date)
            )
            conn.commit()
            cursor.close()  # 关闭cursor释放资源
        print(f"订单 {order_id} 处理成功")
        return True
    except Exception as e:
        with cursor_lock:
            conn.rollback()
        print(f"订单处理失败: {e}")
        return False

# 模拟高并发场景
def simulate_oltp():
    threads = []
    for i in range(1, 101):
        customer_id = i % 20 + 1
        product_id = i % 10 + 1
        quantity = i % 5 + 1
        price = (i % 10 + 1) * 10.5
        
        thread = threading.Thread(
            target=process_order,
            args=(i, customer_id, product_id, quantity, price)
        )
        threads.append(thread)
        thread.start()
    
    # 限制同时运行的线程数，避免过多线程竞争
    active_threads = []
    max_active_threads = 10
    for thread in threads:
        active_threads.append(thread)
        if len(active_threads) >= max_active_threads:
            # 等待一个线程完成
            active_threads[0].join()
            active_threads.pop(0)
    
    # 等待剩余的线程完成
    for thread in active_threads:
        thread.join()
    
    print("OLTP模拟完成，共处理100个订单")

# 运行OLTP模拟
if __name__ == "__main__":
    try:
        simulate_oltp()
    finally:
        conn.close()
        print("数据库连接已关闭")