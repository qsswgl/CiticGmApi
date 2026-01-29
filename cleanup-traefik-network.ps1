# Traefik网络清理脚本 (PowerShell版本)
# 用于安全删除未使用的traefik-public网络

$SshKey = "K:\Key\tx.qsgl.net_id_ed25519"
$SshHost = "root@tx.qsgl.net"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Traefik 网络清理工具" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# 1. 检查网络是否存在
Write-Host "[1/4] 检查 traefik-public 网络..." -ForegroundColor Yellow
$networkExists = & ssh -i "$SshKey" "$SshHost" "docker network ls | grep -q traefik-public && echo yes || echo no" 2>&1

if ($networkExists -match "no") {
    Write-Host "  ✓ traefik-public 网络不存在（可能已被删除）" -ForegroundColor Green
    exit 0
}

# 2. 检查容器使用情况
Write-Host "[2/4] 检查容器使用情况..." -ForegroundColor Yellow
$containerCount = & ssh -i "$SshKey" "$SshHost" "docker network inspect traefik-public --format='{{len .Containers}}' 2>/dev/null" 2>&1

if ($containerCount -match "^\d+$" -and [int]$containerCount -gt 0) {
    Write-Host "  ✗ 警告: 网络上有 $containerCount 个容器正在使用" -ForegroundColor Red
    Write-Host ""
    Write-Host "使用该网络的容器:" -ForegroundColor Yellow
    & ssh -i "$SshKey" "$SshHost" "docker network inspect traefik-public --format='{{range .Containers}}  - {{.Name}}{{println}}{{end}}'" 2>&1
    Write-Host ""
    Write-Host "建议: 不要删除此网络" -ForegroundColor Red
    exit 1
} else {
    Write-Host "  ✓ 网络空闲 (0个容器)" -ForegroundColor Green
}

# 3. 确认Traefik未连接
Write-Host "[3/4] 检查 Traefik 连接状态..." -ForegroundColor Yellow
$traefikConnected = & ssh -i "$SshKey" "$SshHost" @"
TRAEFIK_NETWORKS=`$(docker inspect traefik --format='{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' 2>/dev/null)
TRAEFIK_PUBLIC_ID=`$(docker network inspect traefik-public --format='{{.ID}}' 2>/dev/null | cut -c1-12)
echo `$TRAEFIK_NETWORKS | grep -q `$TRAEFIK_PUBLIC_ID && echo connected || echo not_connected
"@ 2>&1

if ($traefikConnected -match "connected") {
    Write-Host "  ✗ 警告: Traefik正在使用此网络" -ForegroundColor Red
    Write-Host "建议: 不要删除此网络" -ForegroundColor Red
    exit 1
} else {
    Write-Host "  ✓ Traefik未连接到此网络" -ForegroundColor Green
}

# 4. 执行删除
Write-Host "[4/4] 删除网络..." -ForegroundColor Yellow
Write-Host ""
Write-Host "即将删除 traefik-public 网络" -ForegroundColor Yellow
Write-Host "按 Ctrl+C 取消，或按回车继续..." -ForegroundColor Gray
$null = Read-Host

$deleteResult = & ssh -i "$SshKey" "$SshHost" "docker network rm traefik-public 2>&1" 2>&1

if ($deleteResult -match "traefik-public" -or $deleteResult -match "^f171cdf5e41d") {
    Write-Host "  ✓ traefik-public 网络已成功删除" -ForegroundColor Green
    Write-Host ""
    Write-Host "当前Traefik网络列表:" -ForegroundColor Cyan
    & ssh -i "$SshKey" "$SshHost" "docker network ls | grep traefik" 2>&1
} else {
    Write-Host "  ✗ 删除失败: $deleteResult" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "  清理完成" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
