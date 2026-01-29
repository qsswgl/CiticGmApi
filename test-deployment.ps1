# 自动化测试脚本
$domain = "payment.qsgl.net"
$results = @()
$passed = 0
$failed = 0

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   AUTOMATED DEPLOYMENT TESTS" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Health Check
Write-Host "[1/6] Testing health endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://$domain/health" -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "  ✅ PASS - Health check OK" -ForegroundColor Green
        Write-Host "     Response: $($response.Content)" -ForegroundColor Gray
        $results += @{Test="Health Check"; Status="PASS"; Details="Status 200 OK"}
        $passed++
    } else {
        Write-Host "  ❌ FAIL - Status code: $($response.StatusCode)" -ForegroundColor Red
        $results += @{Test="Health Check"; Status="FAIL"; Details="Status $($response.StatusCode)"}
        $failed++
    }
} catch {
    Write-Host "  ❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += @{Test="Health Check"; Status="FAIL"; Details=$_.Exception.Message}
    $failed++
}
Write-Host ""

# Test 2: WeChat Health
Write-Host "[2/6] Testing WeChat service health..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://$domain/Wechat/Health" -TimeoutSec 10 -UseBasicParsing
    $data = $response.Content | ConvertFrom-Json
    if ($data.status -eq "healthy") {
        Write-Host "  ✅ PASS - WeChat service healthy" -ForegroundColor Green
        Write-Host "     Certificate: $($data.certificatePath)" -ForegroundColor Gray
        Write-Host "     Config: MchId=$($data.mchId), AppId=$($data.appId)" -ForegroundColor Gray
        $results += @{Test="WeChat Health"; Status="PASS"; Details="Certificate loaded"}
        $passed++
    } else {
        Write-Host "  ⚠️  WARN - Service status: $($data.status)" -ForegroundColor Yellow
        $results += @{Test="WeChat Health"; Status="WARN"; Details=$data.status}
        $passed++
    }
} catch {
    Write-Host "  ❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += @{Test="WeChat Health"; Status="FAIL"; Details=$_.Exception.Message}
    $failed++
}
Write-Host ""

# Test 3: Swagger API Documentation
Write-Host "[3/6] Testing Swagger API documentation..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://$domain/swagger/index.html" -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200 -and $response.Content -match "swagger") {
        Write-Host "  ✅ PASS - Swagger documentation accessible" -ForegroundColor Green
        Write-Host "     URL: https://$domain/swagger" -ForegroundColor Gray
        $results += @{Test="Swagger Docs"; Status="PASS"; Details="https://$domain/swagger"}
        $passed++
    } else {
        Write-Host "  ❌ FAIL - Swagger not working properly" -ForegroundColor Red
        $results += @{Test="Swagger Docs"; Status="FAIL"; Details="Content check failed"}
        $failed++
    }
} catch {
    Write-Host "  ❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += @{Test="Swagger Docs"; Status="FAIL"; Details=$_.Exception.Message}
    $failed++
}
Write-Host ""

# Test 4: WeChat Refund Demo Page
Write-Host "[4/6] Testing WeChat refund demo page..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://$domain/wechat-refund-demo.html" -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200 -and $response.Content -match "微信服务商退款") {
        Write-Host "  ✅ PASS - Demo page accessible" -ForegroundColor Green
        Write-Host "     URL: https://$domain/wechat-refund-demo.html" -ForegroundColor Gray
        $results += @{Test="Demo Page"; Status="PASS"; Details="Page loaded successfully"}
        $passed++
    } else {
        Write-Host "  ❌ FAIL - Demo page content invalid" -ForegroundColor Red
        $results += @{Test="Demo Page"; Status="FAIL"; Details="Content validation failed"}
        $failed++
    }
} catch {
    Write-Host "  ❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += @{Test="Demo Page"; Status="FAIL"; Details=$_.Exception.Message}
    $failed++
}
Write-Host ""

# Test 5: Container Status
Write-Host "[5/6] Checking container status..." -ForegroundColor Yellow
$containerStatus = & ssh -i "K:\Key\tx.qsgl.net_id_ed25519" root@tx.qsgl.net "docker ps --filter name=abc-payment-gateway --format '{{.Names}}\t{{.Status}}'" 2>&1
if ($containerStatus -match "abc-payment-gateway" -and $containerStatus -match "Up") {
    Write-Host "  ✅ PASS - Container running" -ForegroundColor Green
    Write-Host "     Status: $containerStatus" -ForegroundColor Gray
    $results += @{Test="Container Status"; Status="PASS"; Details=$containerStatus}
    $passed++
} else {
    Write-Host "  ❌ FAIL - Container not running properly" -ForegroundColor Red
    $results += @{Test="Container Status"; Status="FAIL"; Details=$containerStatus}
    $failed++
}
Write-Host ""

# Test 6: Traefik Status (ensure not affected)
Write-Host "[6/6] Verifying Traefik is still running..." -ForegroundColor Yellow
$traefikStatus = & ssh -i "K:\Key\tx.qsgl.net_id_ed25519" root@tx.qsgl.net "docker ps --filter name=traefik --format '{{.Names}}\t{{.Status}}'" 2>&1
if ($traefikStatus -match "traefik" -and $traefikStatus -match "Up") {
    Write-Host "  ✅ PASS - Traefik unaffected and running" -ForegroundColor Green
    Write-Host "     Status: $traefikStatus" -ForegroundColor Gray
    $results += @{Test="Traefik Status"; Status="PASS"; Details=$traefikStatus}
    $passed++
} else {
    Write-Host "  ❌ FAIL - Traefik may have been affected!" -ForegroundColor Red
    $results += @{Test="Traefik Status"; Status="FAIL"; Details=$traefikStatus}
    $failed++
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   TEST SUMMARY" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total Tests: $($passed + $failed)"
Write-Host "✅ Passed: $passed" -ForegroundColor Green
Write-Host "❌ Failed: $failed" -ForegroundColor Red
Write-Host ""

# Detailed Results
Write-Host "Detailed Results:" -ForegroundColor Yellow
foreach ($result in $results) {
    $color = if ($result.Status -eq "PASS") { "Green" } elseif ($result.Status -eq "WARN") { "Yellow" } else { "Red" }
    $icon = if ($result.Status -eq "PASS") { "✅" } elseif ($result.Status -eq "WARN") { "⚠️" } else { "❌" }
    Write-Host "  $icon $($result.Test): $($result.Status)" -ForegroundColor $color
}
Write-Host ""

if ($failed -eq 0) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "   ✅ DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "🌐 Service URLs:" -ForegroundColor Cyan
    Write-Host "   Main: https://$domain" -ForegroundColor White
    Write-Host "   Swagger: https://$domain/swagger" -ForegroundColor White
    Write-Host "   Health: https://$domain/health" -ForegroundColor White
    Write-Host "   WeChat Test: https://$domain/wechat-refund-demo.html" -ForegroundColor White
    Write-Host ""
    Write-Host "📊 Management Commands:" -ForegroundColor Cyan
    Write-Host "   View logs: ssh -i K:\Key\tx.qsgl.net_id_ed25519 root@tx.qsgl.net 'docker logs -f abc-payment-gateway'" -ForegroundColor Gray
    Write-Host "   Restart: ssh -i K:\Key\tx.qsgl.net_id_ed25519 root@tx.qsgl.net 'docker restart abc-payment-gateway'" -ForegroundColor Gray
    Write-Host "   Stop: ssh -i K:\Key\tx.qsgl.net_id_ed25519 root@tx.qsgl.net 'docker stop abc-payment-gateway'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "💾 Backup Location:" -ForegroundColor Cyan
    Write-Host "   /opt/backups/abc-payment-*" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "   ⚠️  DEPLOYMENT COMPLETED WITH ISSUES" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Some tests failed. Check logs:" -ForegroundColor Yellow
    Write-Host "  ssh -i K:\Key\tx.qsgl.net_id_ed25519 root@tx.qsgl.net 'docker logs abc-payment-gateway'" -ForegroundColor Gray
    Write-Host ""
}
