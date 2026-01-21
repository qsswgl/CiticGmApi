#!/bin/bash

# 中信国密API自动部署脚本
# 用法: ./deploy.sh

set -e

echo "=========================================="
echo "  中信银行国密加解密API - 自动部署脚本"
echo "=========================================="

# 配置变量
APP_NAME="citic-gm-api"
IMAGE_NAME="citic-gm-api:latest"
CONTAINER_PORT=8080

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行，请先启动Docker"
    exit 1
fi

# 检查traefik网络是否存在
if ! docker network inspect traefik-network > /dev/null 2>&1; then
    echo "📦 创建traefik-network网络..."
    docker network create traefik-network
fi

# 停止并删除旧容器（如果存在）
if docker ps -a --format '{{.Names}}' | grep -q "^${APP_NAME}$"; then
    echo "🛑 停止旧容器..."
    docker stop ${APP_NAME} || true
    docker rm ${APP_NAME} || true
fi

# 构建镜像
echo "🔨 构建Docker镜像..."
docker build -t ${IMAGE_NAME} .

# 使用docker-compose启动
echo "🚀 启动容器..."
docker-compose up -d

# 等待容器启动
echo "⏳ 等待服务启动..."
sleep 10

# 健康检查
echo "🔍 执行健康检查..."
for i in {1..10}; do
    if curl -s http://localhost:${CONTAINER_PORT}/api/Crypto/health | grep -q "healthy"; then
        echo "✅ 服务启动成功！"
        break
    fi
    if [ $i -eq 10 ]; then
        echo "❌ 服务启动失败，请检查日志"
        docker logs ${APP_NAME}
        exit 1
    fi
    echo "等待服务就绪... ($i/10)"
    sleep 3
done

# 显示容器状态
echo ""
echo "=========================================="
echo "  部署完成！"
echo "=========================================="
echo ""
echo "📋 容器状态:"
docker ps --filter "name=${APP_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "🌐 访问地址:"
echo "   - Swagger文档: https://citic.qsgl.net/"
echo "   - 健康检查: https://citic.qsgl.net/api/Crypto/health"
echo ""
echo "📝 常用命令:"
echo "   查看日志: docker logs -f ${APP_NAME}"
echo "   停止服务: docker-compose down"
echo "   重启服务: docker-compose restart"
echo ""
