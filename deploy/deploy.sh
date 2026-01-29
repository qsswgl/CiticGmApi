#!/bin/bash
# ABC Payment Gateway 部署脚本
# 在服务器上执行此脚本进行部署

set -e

echo "=== ABC Payment Gateway 部署脚本 ==="
echo ""

# 1. 停止并删除旧容器
echo "1. 停止并删除旧容器..."
docker stop abc-payment-gateway 2>/dev/null || true
docker rm abc-payment-gateway 2>/dev/null || true

# 2. 构建新镜像
echo "2. 构建Docker镜像..."
cd /opt/abc-payment
docker build -t abc-payment-gateway:latest .

# 3. 启动新容器
echo "3. 启动新容器..."
bash /tmp/start-container.sh

# 4. 等待健康检查
echo "4. 等待服务启动（45秒）..."
sleep 45

# 5. 验证服务
echo "5. 验证服务状态..."
curl -s https://payment.qsgl.net/Wechat/Health

echo ""
echo "=== 部署完成 ==="
