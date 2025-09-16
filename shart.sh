#!/usr/bin/env bash
set -euo pipefail

# 选择 compose 命令
if docker compose version >/dev/null 2>&1; then
  DC="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  DC="docker-compose"
else
  echo "❌ 未找到 docker compose 或 docker-compose，请安装 Docker Compose。"
  exit 1
fi

echo "✅ 使用: $DC"

# 1) 先起 HDFS（NameNode + DataNode）
$DC up -d namenode datanode1 datanode2

# 等待 NameNode 启动就绪（最多 60s）
echo "⏳ 等待 NameNode 就绪..."
for i in {1..60}; do
  if docker exec namenode hdfs dfs -ls / >/dev/null 2>&1; then
    echo "✅ NameNode 就绪"
    break
  fi
  sleep 1
done

# 2) 初始化 Spark 事件日志目录（幂等）
docker exec namenode hdfs dfs -mkdir -p /spark-logs || true
docker exec namenode hdfs dfs -chmod -R 1777 /spark-logs || true

# 3) 启动 YARN + HistoryServer + Spark 客户端
$DC up -d resourcemanager nodemanager1 nodemanager2 historyserver spark-client

echo "🎉 全部就绪："
echo "  - YARN RM UI:     http://localhost:8088"
echo "  - MR History UI:  http://localhost:19888"
echo "  - Timeline UI:    http://localhost:8188"
