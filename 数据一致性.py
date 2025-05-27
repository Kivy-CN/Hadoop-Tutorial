import time
import random
import uuid
from collections import defaultdict

class Message:
    def __init__(self, content):
        self.id = str(uuid.uuid4())
        self.content = content
        self.processed = False

class Network:
    """模拟不可靠的网络传输"""
    def send(self, message, failure_rate=0.3):
        # 模拟网络延迟
        delay = random.uniform(0.01, 0.05)
        time.sleep(delay)
        
        # 模拟网络失败
        if random.random() < failure_rate:
            print(f"网络传输失败: {message.id}")
            return False
        return True

class Storage:
    """模拟持久化存储"""
    def __init__(self):
        self.processed_messages = set()
        self.data = []
        self.storage_failure_rate = 0.05  # 存储系统有时也会失败
    
    def store(self, message_id, data):
        # 模拟存储失败
        if random.random() < self.storage_failure_rate:
            print(f"存储操作失败: {message_id}")
            raise Exception("存储错误")
            
        self.processed_messages.add(message_id)
        self.data.append(data)
    
    def is_processed(self, message_id):
        # 模拟查询延迟
        time.sleep(random.uniform(0.01, 0.03))
        return message_id in self.processed_messages
    
    def get_data(self):
        return self.data.copy()

def at_most_once(messages, network):
    """
    至多一次语义：消息可能会丢失，但绝不会重复处理
    特点：不做重试，不做去重，简单但可能丢数据
    """
    print("\n=== 至多一次（At-most-once）===")
    results = []
    
    for msg in messages:
        # 尝试发送，但不重试
        if network.send(msg):
            print(f"处理消息: {msg.id}, 内容: {msg.content}")
            results.append(msg.content)
        else:
            print(f"消息丢失，不会重试: {msg.id}")
    
    return results

def at_least_once(messages, network, max_retries=3):
    """
    至少一次语义：保证消息至少被处理一次，但可能会重复处理
    特点：有重试机制，没有去重，不会丢数据但可能重复
    """
    print("\n=== 至少一次（At-least-once）===")
    results = []
    
    for msg in messages:
        delivered = False
        retries = 0
        
        # 尝试直到成功或超过最大重试次数
        while not delivered and retries <= max_retries:
            if network.send(msg, failure_rate=0.5):
                print(f"处理消息: {msg.id}, 内容: {msg.content}")
                results.append(msg.content)
                delivered = True
            else:
                retries += 1
                print(f"重试 #{retries} 消息: {msg.id}")
                # 指数退避，模拟真实的重试策略
                time.sleep(0.1 * (2 ** retries))
                
        if not delivered:
            print(f"经过{max_retries}次重试后消息仍未送达: {msg.id}")
    
    return results

def exactly_once(messages, network, storage, max_retries=3):
    """
    精确一次语义：保证消息只被处理一次，不多不少
    特点：有重试机制，有去重机制，不会丢数据也不会重复
    """
    print("\n=== 精确一次（Exactly-once）===")
    
    for msg in messages:
        delivered = False
        retries = 0
        
        # 检查消息是否已处理过（幂等性检查）
        if storage.is_processed(msg.id):
            print(f"消息已被处理过，跳过: {msg.id}")
            continue
        
        # 尝试直到成功或超过最大重试次数
        while not delivered and retries <= max_retries:
            if network.send(msg, failure_rate=0.5):
                # 处理消息并记录已处理
                try:
                    print(f"处理消息: {msg.id}, 内容: {msg.content}")
                    storage.store(msg.id, msg.content)
                    delivered = True
                except Exception as e:
                    print(f"存储失败，需要重试: {msg.id}, 错误: {e}")
                    retries += 1
            else:
                retries += 1
                print(f"重试 #{retries} 消息: {msg.id}")
                # 指数退避
                time.sleep(0.1 * (2 ** retries))
                
                # 重试前检查消息是否已处理（防止因确认消息丢失导致的重复处理）
                if storage.is_processed(msg.id):
                    print(f"发现消息已处理: {msg.id}")
                    delivered = True
                    break
                
        if not delivered:
            print(f"经过{max_retries}次重试后消息仍未送达: {msg.id}")
    
    return storage.get_data()

def simulate_duplicate_messages(original_messages, duplicate_rate=0.3):
    """模拟由于网络原因导致的消息重复"""
    all_messages = original_messages.copy()
    duplicates_count = 0
    
    for msg in original_messages:
        # 可能生成0-3个重复消息
        dup_count = 0
        for _ in range(3):
            if random.random() < duplicate_rate:
                # 创建相同id和内容的消息副本
                duplicate = Message(msg.content)
                duplicate.id = msg.id  # 使用相同ID以便于去重
                all_messages.append(duplicate)
                dup_count += 1
                duplicates_count += 1
        
        if dup_count > 0:
            print(f"生成了{dup_count}个重复消息: {msg.id}")
    
    # 打乱顺序以模拟真实场景
    random.shuffle(all_messages)
    print(f"总计生成了{duplicates_count}个重复消息")
    return all_messages

def simulate_out_of_order(messages, reorder_rate=0.4):
    """模拟消息乱序到达"""
    # 复制消息列表，避免修改原列表
    reordered = messages.copy()
    
    # 随机交换一些消息的位置
    swaps = int(len(messages) * reorder_rate)
    for _ in range(swaps):
        i, j = random.sample(range(len(reordered)), 2)
        reordered[i], reordered[j] = reordered[j], reordered[i]
    
    print(f"执行了{swaps}次消息位置交换，模拟乱序到达")
    return reordered

def main():
    # 创建更多原始消息
    message_count = 20
    original_messages = [Message(f"数据-{i}") for i in range(message_count)]
    
    # 模拟网络环境
    network = Network()
    
    # 创建存储
    storage = Storage()
    
    # 1. 至多一次处理
    print("\n--- 测试至多一次语义 ---")
    # 消息可能会乱序到达
    reordered_messages = simulate_out_of_order(original_messages)
    results_at_most_once = at_most_once(reordered_messages, network)
    print(f"处理结果: {results_at_most_once}")
    print(f"原始消息数: {len(original_messages)}, 处理后数据量: {len(results_at_most_once)}")
    print(f"丢失率: {(len(original_messages) - len(results_at_most_once)) / len(original_messages):.2%}")
    
    # 2. 至少一次处理
    print("\n--- 测试至少一次语义 ---")
    # 模拟消息重复和乱序场景
    duplicate_messages = simulate_duplicate_messages(original_messages, duplicate_rate=0.4)
    reordered_duplicates = simulate_out_of_order(duplicate_messages)
    results_at_least_once = at_least_once(reordered_duplicates, network)
    print(f"处理结果: {results_at_least_once[:5]}... (共{len(results_at_least_once)}项)")
    print(f"原始消息数: {len(original_messages)}, 重复后消息数: {len(reordered_duplicates)}, 处理后数据量: {len(results_at_least_once)}")
    print(f"重复率: {(len(results_at_least_once) - len(original_messages)) / len(original_messages):.2%}")
    
    # 3. 精确一次处理
    print("\n--- 测试精确一次语义 ---")
    # 使用之前生成的重复消息进行测试
    results_exactly_once = exactly_once(reordered_duplicates, network, storage)
    print(f"处理结果: {results_exactly_once[:5]}... (共{len(results_exactly_once)}项)")
    print(f"原始消息数: {len(original_messages)}, 重复后消息数: {len(reordered_duplicates)}, 处理后数据量: {len(results_exactly_once)}")
    print(f"精确率: {abs(len(results_exactly_once) - len(original_messages)) / len(original_messages):.2%}")
    
    # 对比总结
    print("\n=== 三种一致性语义对比 ===")
    print(f"至多一次处理结果数: {len(results_at_most_once)} / {len(original_messages)} (丢失率: {(len(original_messages) - len(results_at_most_once)) / len(original_messages):.2%})")
    print(f"至少一次处理结果数: {len(results_at_least_once)} / {len(original_messages)} (重复率: {(len(results_at_least_once) - len(original_messages)) / len(original_messages):.2%})")
    print(f"精确一次处理结果数: {len(results_exactly_once)} / {len(original_messages)} (精确率: {abs(len(results_exactly_once) - len(original_messages)) / len(original_messages):.2%})")

    # 效率比较
    print("\n=== 性能对比 ===")
    # 创建新的测试数据集
    test_messages = [Message(f"效率测试-{i}") for i in range(30)]
    
    start_time = time.time()
    at_most_once(test_messages, network)
    at_most_time = time.time() - start_time
    print(f"至多一次处理时间: {at_most_time:.4f}秒")
    
    start_time = time.time()
    at_least_once(test_messages, network)
    at_least_time = time.time() - start_time
    print(f"至少一次处理时间: {at_least_time:.4f}秒")
    
    storage = Storage()  # 重置存储
    start_time = time.time()
    exactly_once(test_messages, network, storage)
    exactly_time = time.time() - start_time
    print(f"精确一次处理时间: {exactly_time:.4f}秒")
    
    print(f"相对时间比例 - 至多一次:至少一次:精确一次 = 1:{at_least_time/at_most_time:.2f}:{exactly_time/at_most_time:.2f}")

if __name__ == "__main__":
    main()