#!/bin/bash
# Traefik网络清理脚本
# 用于安全删除未使用的traefik-public网络

echo "========================================="
echo "  Traefik 网络清理工具"
echo "========================================="
echo ""

# 1. 检查traefik-public网络是否存在
echo "[1/4] 检查 traefik-public 网络..."
if ! docker network ls | grep -q traefik-public; then
    echo "  ✓ traefik-public 网络不存在（可能已被删除）"
    exit 0
fi

# 2. 检查网络上的容器数量
echo "[2/4] 检查容器使用情况..."
CONTAINER_COUNT=$(docker network inspect traefik-public --format='{{len .Containers}}' 2>/dev/null || echo "error")

if [ "$CONTAINER_COUNT" = "error" ]; then
    echo "  ✗ 无法检查网络"
    exit 1
fi

if [ "$CONTAINER_COUNT" -gt 0 ]; then
    echo "  ✗ 警告: 网络上有 $CONTAINER_COUNT 个容器正在使用"
    echo ""
    echo "使用该网络的容器:"
    docker network inspect traefik-public --format='{{range .Containers}}  - {{.Name}}{{println}}{{end}}'
    echo ""
    echo "建议: 不要删除此网络"
    exit 1
else
    echo "  ✓ 网络空闲 (0个容器)"
fi

# 3. 确认Traefik未连接
echo "[3/4] 检查 Traefik 连接状态..."
TRAEFIK_NETWORKS=$(docker inspect traefik --format='{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' 2>/dev/null)
TRAEFIK_PUBLIC_ID=$(docker network inspect traefik-public --format='{{.ID}}' 2>/dev/null | cut -c1-12)

if echo "$TRAEFIK_NETWORKS" | grep -q "$TRAEFIK_PUBLIC_ID"; then
    echo "  ✗ 警告: Traefik正在使用此网络"
    echo "建议: 不要删除此网络"
    exit 1
else
    echo "  ✓ Traefik未连接到此网络"
fi

# 4. 执行删除
echo "[4/4] 删除网络..."
echo ""
echo "即将删除 traefik-public 网络"
echo "按 Ctrl+C 取消，或按回车继续..."
read

if docker network rm traefik-public; then
    echo "  ✓ traefik-public 网络已成功删除"
    echo ""
    echo "当前网络列表:"
    docker network ls | grep traefik
else
    echo "  ✗ 删除失败"
    exit 1
fi

echo ""
echo "========================================="
echo "  清理完成"
echo "========================================="
