# HBase Shell 和 Web UI 操作指南

## HBase Shell 操作方法

HBase Shell 是与 HBase 交互的最直接方式，提供了完整的命令行界面。

### 1. 启动 HBase Shell

```bash
# 检查 HBase 进程
sudo -u hadoop jps

# 检查 HBase 服务状态
# 停止 HBase
sudo -u hadoop /opt/hbase/bin/stop-hbase.sh

# 等待几秒后启动 HBase
sudo -u hadoop /opt/hbase/bin/start-hbase.sh

# 等待 HBase 完全启动（大约1-2分钟）
sleep 120

# 重新尝试连接 HBase Shell
sudo -u hadoop /opt/hbase/bin/hbase shell
```

### 2. 创建表

```
# 语法：create '表名', '列族1', '列族2', ...
create 'gaokao_scores', 'info', 'scores'
```

### 3. 插入高考成绩数据

```
# 语法：put '表名', '行键', '列族:列名', '值'
# 插入基本信息
put 'gaokao_scores', '张三_2024', 'info:name', '张三'
put 'gaokao_scores', '张三_2024', 'info:year', '2024'

# 插入成绩信息
put 'gaokao_scores', '张三_2024', 'scores:语文', '120'
put 'gaokao_scores', '张三_2024', 'scores:数学', '140'
put 'gaokao_scores', '张三_2024', 'scores:英语', '130'
put 'gaokao_scores', '张三_2024', 'scores:物理', '90'
put 'gaokao_scores', '张三_2024', 'scores:化学', '85'
put 'gaokao_scores', '张三_2024', 'scores:生物', '88'
put 'gaokao_scores', '张三_2024', 'scores:总分', '653'
```

### 4. 查询数据

```
# 查询单行数据
get 'gaokao_scores', '张三_2024'

# 扫描整个表
scan 'gaokao_scores'

# 按照指定条件扫描
scan 'gaokao_scores', {STARTROW => '张三', ENDROW => '张三\xFF'}

# 只查询特定列族
get 'gaokao_scores', '张三_2024', {COLUMN => 'scores'}
```

### 5. 更新数据

```
# 语法与插入相同，会覆盖原有数据
put 'gaokao_scores', '张三_2024', 'scores:语文', '125'
```

### 6. 删除数据

```
# 删除单个单元格
delete 'gaokao_scores', '张三_2024', 'scores:语文'

# 删除整行
deleteall 'gaokao_scores', '张三_2024'

# 删除表（先禁用再删除）
disable 'gaokao_scores'
drop 'gaokao_scores'
```

## 通过 Web 界面操作 HBase

HBase 提供了两种 Web 界面：

### 1. HBase 原生 Web UI

HBase 自带的 Web 界面主要用于监控和管理：

- 访问 Master Web UI: `http://你的服务器IP:16010`
- 访问 RegionServer Web UI: `http://你的服务器IP:16030`

这些界面提供了集群状态、表信息、Region 分布等信息，但操作功能有限。

### 2. HBase Web 管理工具：Hue

Hue 是一个功能更全面的 Web 界面，可以用来操作 HBase：

1. 安装 Hue：

```bash
sudo apt-get install hue hue-server
```

2. 配置 Hue 连接 HBase：
   修改 `/etc/hue/conf/hue.ini`，添加 HBase 配置。

3. 启动 Hue：

```bash
sudo systemctl start hue
```

4. 通过 Hue 操作 HBase：
   - 访问 `http://你的服务器IP:8888`
   - 登录后，导航到 "Query" > "HBase"
   - 在界面上可以创建表、浏览数据、添加记录等

### 3. 高考成绩表结构示例

在 Hue 或 HBase Shell 中创建以下表：

```
表名: gaokao_scores
列族:
  - info: 存储学生基本信息
  - scores: 存储各科成绩
```

行键设计: `学生姓名_年份`，例如 `张三_2024`
