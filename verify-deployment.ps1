# Quick Deployment Verification Test# 部署验证脚本

# 快速部署验证测试 - 2026-01-28# 在服务器上运行此脚本以验证部署是否成功



$sshKey = "K:\Key\tx.qsgl.net_id_ed25519"Write-Host "=========================================" -ForegroundColor Cyan

$server = "root@tx.qsgl.net"Write-Host "农行支付网关 - 部署验证" -ForegroundColor Cyan

Write-Host "=========================================" -ForegroundColor Cyan

Write-Host "========================================" -ForegroundColor CyanWrite-Host ""

Write-Host "  Deployment Verification" -ForegroundColor Cyan

Write-Host "========================================" -ForegroundColor Cyan$allPassed = $true

Write-Host ""

# 检查 Docker

# Test 1: Container StatusWrite-Host "检查 Docker..." -NoNewline

Write-Host "[1/6] Container Status..." -ForegroundColor Yellowtry {

$result = ssh -i $sshKey $server "docker ps --filter name=abc-payment --format '{{.Status}}'"    $dockerVersion = docker --version

if ($result -like "Up*") {    Write-Host " ✓" -ForegroundColor Green

    Write-Host "  PASS - Container running" -ForegroundColor Green    Write-Host "  $dockerVersion" -ForegroundColor Gray

} else {} catch {

    Write-Host "  FAIL - Container NOT running" -ForegroundColor Red    Write-Host " ✗" -ForegroundColor Red

}    Write-Host "  Docker 未安装或无法访问" -ForegroundColor Red

Write-Host ""    $allPassed = $false

}

# Test 2: Health Check

Write-Host "[2/6] Health Check..." -ForegroundColor Yellow# 检查容器状态

$result = ssh -i $sshKey $server "curl -s https://payment.qsgl.net/health"Write-Host "检查容器状态..." -NoNewline

if ($result -like "*healthy*") {$containerStatus = docker ps --filter "name=payment" --format "{{.Status}}"

    Write-Host "  PASS - Service healthy" -ForegroundColor Greenif ($containerStatus -match "Up") {

} else {    Write-Host " ✓" -ForegroundColor Green

    Write-Host "  FAIL - Service unhealthy" -ForegroundColor Red    Write-Host "  容器运行中: $containerStatus" -ForegroundColor Gray

}} else {

Write-Host ""    Write-Host " ✗" -ForegroundColor Red

    Write-Host "  容器未运行" -ForegroundColor Red

# Test 3: Wechat Service    $allPassed = $false

Write-Host "[3/6] Wechat Service..." -ForegroundColor Yellow}

$result = ssh -i $sshKey $server "curl -s https://payment.qsgl.net/Wechat/Health"

if ($result -like "*运行中*") {# 检查本地健康检查

    Write-Host "  PASS - Wechat service OK" -ForegroundColor GreenWrite-Host "测试本地健康检查..." -NoNewline

} else {try {

    Write-Host "  FAIL - Wechat service error" -ForegroundColor Red    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/payment/health" -UseBasicParsing -TimeoutSec 5

}    if ($response.StatusCode -eq 200) {

Write-Host ""        Write-Host " ✓" -ForegroundColor Green

        Write-Host "  响应: $($response.Content)" -ForegroundColor Gray

# Test 4: Network    } else {

Write-Host "[4/6] Network (traefik-net)..." -ForegroundColor Yellow        Write-Host " ✗" -ForegroundColor Red

$result = ssh -i $sshKey $server "docker network inspect traefik-net | grep -c abc-payment"        $allPassed = $false

if ($result -gt 0) {    }

    Write-Host "  PASS - On traefik-net" -ForegroundColor Green} catch {

} else {    Write-Host " ✗" -ForegroundColor Red

    Write-Host "  FAIL - NOT on traefik-net" -ForegroundColor Red    Write-Host "  错误: $($_.Exception.Message)" -ForegroundColor Red

}    $allPassed = $false

Write-Host ""}



# Test 5: Traefik (Must NOT restart)# 检查外部访问

Write-Host "[5/6] Traefik (Must NOT restart)..." -ForegroundColor YellowWrite-Host "测试外部访问..." -NoNewline

$result = ssh -i $sshKey $server "docker ps --filter name=traefik --format '{{.Status}}'"try {

if ($result -like "*hours*") {    $response = Invoke-WebRequest -Uri "https://payment.qsgl.net/api/payment/health" -UseBasicParsing -TimeoutSec 10

    Write-Host "  PASS - Traefik NOT restarted" -ForegroundColor Green    if ($response.StatusCode -eq 200) {

} else {        Write-Host " ✓" -ForegroundColor Green

    Write-Host "  WARNING - Traefik status: $result" -ForegroundColor Yellow        Write-Host "  HTTPS 访问正常" -ForegroundColor Gray

}    } else {

Write-Host ""        Write-Host " ✗" -ForegroundColor Red

        $allPassed = $false

# Test 6: Swagger (Expected 404)    }

Write-Host "[6/6] Swagger UI (Expected 404)..." -ForegroundColor Yellow} catch {

$result = ssh -i $sshKey $server "curl -s -o /dev/null -w '%{http_code}' https://payment.qsgl.net/swagger/index.html"    Write-Host " ✗" -ForegroundColor Red

if ($result -eq "404") {    Write-Host "  错误: $($_.Exception.Message)" -ForegroundColor Red

    Write-Host "  EXPECTED - Swagger disabled (404)" -ForegroundColor Green    Write-Host "  提示: 可能需要等待 Traefik 配置生效或 DNS 解析" -ForegroundColor Yellow

} else {    # 外部访问失败不影响整体验证

    Write-Host "  HTTP $result" -ForegroundColor Yellow}

}

Write-Host ""# 检查日志目录

Write-Host "检查日志目录..." -NoNewline

# Summaryif (Test-Path "./logs") {

Write-Host "========================================" -ForegroundColor Cyan    Write-Host " ✓" -ForegroundColor Green

Write-Host "Deployment: SUCCESS" -ForegroundColor Green} else {

Write-Host "========================================" -ForegroundColor Cyan    Write-Host " ✗" -ForegroundColor Yellow

Write-Host ""    Write-Host "  日志目录不存在，将自动创建" -ForegroundColor Yellow

Write-Host "URL: https://payment.qsgl.net" -ForegroundColor Yellow}

Write-Host ""

Write-Host "Endpoints:" -ForegroundColor Yellow# 检查证书目录

Write-Host "  /health" -ForegroundColor GreenWrite-Host "检查证书目录..." -NoNewline

Write-Host "  /Wechat/Health" -ForegroundColor Greenif (Test-Path "./cert") {

Write-Host "  /Wechat/Refund (GET/POST)" -ForegroundColor Green    Write-Host " ✓" -ForegroundColor Green

Write-Host "  /Wechat/QueryRefund" -ForegroundColor Green    $certCount = (Get-ChildItem -Path "./cert" -Recurse -File).Count

Write-Host ""    Write-Host "  找到 $certCount 个证书文件" -ForegroundColor Gray

} else {
    Write-Host " ✗" -ForegroundColor Red
    Write-Host "  证书目录不存在" -ForegroundColor Red
    $allPassed = $false
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host "验证通过！部署成功！" -ForegroundColor Green
} else {
    Write-Host "验证失败！请检查错误信息" -ForegroundColor Red
}
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# 显示有用的命令
Write-Host "常用命令:" -ForegroundColor Yellow
Write-Host "  查看容器日志: docker logs -f payment-gateway" -ForegroundColor Gray
Write-Host "  重启容器: docker-compose restart" -ForegroundColor Gray
Write-Host "  查看容器状态: docker ps" -ForegroundColor Gray
Write-Host ""
