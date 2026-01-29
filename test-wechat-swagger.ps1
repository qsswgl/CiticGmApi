# Wechat Refund API Swagger Deployment Test
# Test Swagger documentation and API availability

$baseUrl = "https://payment.qsgl.net"
$sshKey = "K:\Key\tx.qsgl.net_id_ed25519"
$server = "root@tx.qsgl.net"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Wechat Refund API Deployment Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Main service health check
Write-Host "[Test 1] Main Service Health Check..." -ForegroundColor Yellow
$result = ssh -i $sshKey $server "curl -s $baseUrl/health"
Write-Host "Response: $result" -ForegroundColor Green
Write-Host ""

# Test 2: Wechat service health check
Write-Host "[Test 2] Wechat Service Health Check..." -ForegroundColor Yellow
$result = ssh -i $sshKey $server "curl -s $baseUrl/Wechat/Health"
Write-Host "Response: $result" -ForegroundColor Green
Write-Host ""

# Test 3: Swagger UI accessibility
Write-Host "[Test 3] Swagger UI Accessibility..." -ForegroundColor Yellow
$result = ssh -i $sshKey $server "curl -s -o /dev/null -w '%{http_code}' $baseUrl/swagger/index.html"
if ($result -eq "200") {
    Write-Host "PASS - Swagger UI accessible (HTTP $result)" -ForegroundColor Green
} else {
    Write-Host "FAIL - Swagger UI not accessible (HTTP $result)" -ForegroundColor Red
}
Write-Host ""

# Test 4: Swagger JSON
Write-Host "[Test 4] Swagger JSON..." -ForegroundColor Yellow
$result = ssh -i $sshKey $server "curl -s -o /dev/null -w '%{http_code}' $baseUrl/swagger/v1/swagger.json"
if ($result -eq "200") {
    Write-Host "PASS - Swagger JSON accessible (HTTP $result)" -ForegroundColor Green
} else {
    Write-Host "FAIL - Swagger JSON not accessible (HTTP $result)" -ForegroundColor Red
}
Write-Host ""

# Test 5: Check Wechat APIs in Swagger
Write-Host "[Test 5] Check Wechat APIs in Swagger..." -ForegroundColor Yellow
ssh -i $sshKey $server "curl -s $baseUrl/swagger/v1/swagger.json | python3 -c 'import sys, json; data=json.load(sys.stdin); paths=data.get(\"paths\", {}); wechat_paths=[p for p in paths.keys() if \"Wechat\" in p]; print(\"\n\".join(wechat_paths) if wechat_paths else \"No Wechat APIs found\")'"
Write-Host ""

# Test 6: Container status
Write-Host "[Test 6] Container Status..." -ForegroundColor Yellow
ssh -i $sshKey $server "docker ps --filter name=abc-payment --format 'table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}'"
Write-Host ""

# Test 7: Traefik status
Write-Host "[Test 7] Traefik Proxy Status..." -ForegroundColor Yellow
ssh -i $sshKey $server "docker ps --filter name=traefik --format 'table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}'"
Write-Host ""

# Test 8: Network connectivity
Write-Host "[Test 8] Network Connectivity..." -ForegroundColor Yellow
$networkCheck = ssh -i $sshKey $server "docker network inspect traefik-net --format '{{range .Containers}}{{.Name}} {{end}}' | grep -o 'abc-payment-gateway'"
if ($networkCheck -eq "abc-payment-gateway") {
    Write-Host "PASS - abc-payment-gateway connected to traefik-net" -ForegroundColor Green
} else {
    Write-Host "FAIL - abc-payment-gateway not connected to traefik-net" -ForegroundColor Red
}
Write-Host ""

# Test 9: Container logs (last 10 lines)
Write-Host "[Test 9] Container Logs (last 10 lines)..." -ForegroundColor Yellow
ssh -i $sshKey $server "docker logs abc-payment-gateway --tail 10"
Write-Host ""

# Test Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Swagger UI URL:" -ForegroundColor Yellow
Write-Host "  https://payment.qsgl.net/swagger/index.html" -ForegroundColor Green
Write-Host ""
Write-Host "Wechat Refund API Documentation:" -ForegroundColor Yellow
Write-Host "  GET  /Wechat/Refund       - Wechat Service Provider Refund (GET)" -ForegroundColor Green
Write-Host "  POST /Wechat/Refund       - Wechat Service Provider Refund (POST)" -ForegroundColor Green
Write-Host "  GET  /Wechat/QueryRefund  - Query Refund Status" -ForegroundColor Green
Write-Host "  GET  /Wechat/Health       - Health Check" -ForegroundColor Green
Write-Host ""
