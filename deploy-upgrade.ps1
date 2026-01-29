# 腾讯云自动化升级部署脚本 - 支持备份和回滚
# 部署微信退款API到现有容器，不影响Traefik

param(
    [string]$ServerHost = "tx.qsgl.net",
    [string]$SshKeyPath = "K:\Key\tx.qsgl.net_id_ed25519",
    [string]$SshUser = "root",
    [string]$DeployPath = "/opt/abc-payment",
    [string]$Domain = "payment.qsgl.net"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================"
Write-Host "   ABC Payment Gateway - Upgrade Deploy"
Write-Host "   With Backup & Rollback Support"
Write-Host "========================================"
Write-Host ""

# Step 1: Build and Publish
Write-Host "[1/9] Building project..." -ForegroundColor Yellow
dotnet build -c Release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed" -ForegroundColor Red
    exit 1
}

dotnet publish -c Release -o .\bin\Release\net10.0\publish
if ($LASTEXITCODE -ne 0) {
    Write-Host "Publish failed" -ForegroundColor Red
    exit 1
}
Write-Host "   Build completed" -ForegroundColor Green
Write-Host ""

# Step 2: Create deployment package
Write-Host "[2/9] Creating deployment package..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$deployDir = ".\deploy-temp"
$deployZip = "deploy_$timestamp.zip"

if (Test-Path $deployDir) {
    Remove-Item $deployDir -Recurse -Force
}
New-Item -ItemType Directory -Path $deployDir | Out-Null

Copy-Item ".\bin\Release\net10.0\publish\*" -Destination $deployDir -Recurse
Copy-Item ".\Dockerfile" -Destination $deployDir
Copy-Item "K:\payment\deploy\docker-compose.traefik.yml" -Destination "$deployDir\docker-compose.yml"

# Update port configuration
(Get-Content "$deployDir\docker-compose.yml") -replace 'server.port=5000', 'server.port=8080' | Set-Content "$deployDir\docker-compose.yml"
(Get-Content "$deployDir\docker-compose.yml") -replace 'http://\+:5000', 'http://+:8080' | Set-Content "$deployDir\docker-compose.yml"
(Get-Content "$deployDir\docker-compose.yml") -replace 'localhost:5000', 'localhost:8080' | Set-Content "$deployDir\docker-compose.yml"

Compress-Archive -Path "$deployDir\*" -DestinationPath $deployZip -Force
Remove-Item $deployDir -Recurse -Force

$zipSize = [math]::Round((Get-Item $deployZip).Length/1MB, 2)
Write-Host "   Package created: $deployZip ($zipSize MB)" -ForegroundColor Green
Write-Host ""

# Step 3: Test SSH
Write-Host "[3/9] Testing SSH connection..." -ForegroundColor Yellow
if (-not (Test-Path $SshKeyPath)) {
    Write-Host "SSH key not found: $SshKeyPath" -ForegroundColor Red
    exit 1
}

$null = & ssh -i "$SshKeyPath" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${SshUser}@${ServerHost}" "echo OK" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "SSH connection failed" -ForegroundColor Red
    exit 1
}
Write-Host "   SSH connection OK" -ForegroundColor Green
Write-Host ""

# Step 4: Backup current deployment
Write-Host "[4/9] Creating backup on server..." -ForegroundColor Yellow

$backupScript = "cd /opt && " +
    "BACKUP_DIR=`"/opt/backups/abc-payment-`$(date +%Y%m%d_%H%M%S)`" && " +
    "mkdir -p `"`$BACKUP_DIR`" && " +
    "if [ -d `"/opt/abc-payment`" ]; then cp -r /opt/abc-payment/* `"`$BACKUP_DIR/`" 2>/dev/null || true; echo `"Files backed up`"; fi && " +
    "if docker images | grep -q abc-payment-gateway; then CURRENT_IMAGE=`$(docker images abc-payment-gateway:latest --format `"{{.ID}}`") && docker tag `"`$CURRENT_IMAGE`" `"abc-payment-gateway:backup-`$(date +%Y%m%d_%H%M%S)`" 2>/dev/null || true; echo `"Image backed up`"; fi && " +
    "if docker ps -a | grep -q abc-payment-gateway; then docker inspect abc-payment-gateway > `"`$BACKUP_DIR/container-config.json`" 2>/dev/null || true; fi && " +
    "echo `"BACKUP_SUCCESS`" && " +
    "echo `"BACKUP_PATH=`$BACKUP_DIR`""

$backupResult = & ssh -i "$SshKeyPath" "${SshUser}@${ServerHost}" "$backupScript" 2>&1

if ($backupResult -match "BACKUP_SUCCESS") {
    $backupPath = ($backupResult | Select-String "BACKUP_PATH=(.+)" | ForEach-Object { $_.Matches.Groups[1].Value })
    Write-Host "   Backup created: $backupPath" -ForegroundColor Green
} else {
    Write-Host "   Warning: Backup may have issues, continuing..." -ForegroundColor Yellow
}
Write-Host ""

# Step 5: Upload package
Write-Host "[5/9] Uploading deployment package..." -ForegroundColor Yellow

$null = & ssh -i "$SshKeyPath" "${SshUser}@${ServerHost}" "mkdir -p $DeployPath" 2>&1
& scp -i "$SshKeyPath" -o StrictHostKeyChecking=no "$deployZip" "${SshUser}@${ServerHost}:${DeployPath}/" 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "Upload failed" -ForegroundColor Red
    exit 1
}
Write-Host "   Upload completed" -ForegroundColor Green
Write-Host ""

Remove-Item $deployZip -Force

# Step 6: Extract and configure
Write-Host "[6/9] Extracting and configuring..." -ForegroundColor Yellow

$extractScript = "cd $DeployPath && " +
    "unzip -o deploy_*.zip && " +
    "rm -f deploy_*.zip && " +
    "docker network inspect traefik-public >/dev/null 2>&1 || docker network create traefik-public && " +
    "echo EXTRACT_SUCCESS"

$extractResult = & ssh -i "$SshKeyPath" "${SshUser}@${ServerHost}" "$extractScript" 2>&1

if ($extractResult -match "EXTRACT_SUCCESS") {
    Write-Host "   Configuration completed" -ForegroundColor Green
} else {
    Write-Host "Extraction failed" -ForegroundColor Red
    Write-Host $extractResult
    exit 1
}
Write-Host ""

# Step 7: Stop old container (gracefully)
Write-Host "[7/9] Stopping current container..." -ForegroundColor Yellow

$stopScript = "cd /opt/abc-payment && " +
    "if docker ps | grep -q abc-payment-gateway; then echo Stopping... && docker-compose down --timeout 30; fi && " +
    "echo STOP_SUCCESS"

$stopResult = & ssh -i "$SshKeyPath" "${SshUser}@${ServerHost}" "$stopScript" 2>&1

if ($stopResult -match "STOP_SUCCESS") {
    Write-Host "   Container stopped" -ForegroundColor Green
} else {
    Write-Host "Warning: Stop may have issues" -ForegroundColor Yellow
}
Write-Host ""

# Step 8: Build and start new container
Write-Host "[8/9] Building and starting new container..." -ForegroundColor Yellow

$deployScript = "cd /opt/abc-payment && " +
    "echo Building... && " +
    "docker-compose build --no-cache && " +
    "echo Starting... && " +
    "docker-compose up -d && " +
    "sleep 10 && " +
    "if docker ps | grep -q abc-payment-gateway; then echo DEPLOY_SUCCESS && docker ps --filter name=abc-payment-gateway; else echo DEPLOY_FAILED && docker logs abc-payment-gateway --tail 50; exit 1; fi"

$deployResult = & ssh -i "$SshKeyPath" "${SshUser}@${ServerHost}" "$deployScript" 2>&1

if ($deployResult -match "DEPLOY_SUCCESS") {
    Write-Host "   Container started successfully" -ForegroundColor Green
} else {
    Write-Host "Deployment failed!" -ForegroundColor Red
    Write-Host $deployResult
    Write-Host ""
    Write-Host "Rolling back to backup..." -ForegroundColor Yellow
    
    # Rollback
    $rollbackScript = "cd /opt/abc-payment && " +
        "docker-compose down && " +
        "LATEST_BACKUP=`$(ls -t /opt/backups/abc-payment-* 2>/dev/null | head -1) && " +
        "if [ -n `"`$LATEST_BACKUP`" ]; then cp -r `"`$LATEST_BACKUP`"/* /opt/abc-payment/ && docker-compose up -d && echo ROLLBACK_SUCCESS; else echo ROLLBACK_FAILED; fi"
    
    $rollbackResult = & ssh -i "$SshKeyPath" "${SshUser}@${ServerHost}" "$rollbackScript" 2>&1
    
    if ($rollbackResult -match "ROLLBACK_SUCCESS") {
        Write-Host "Rollback completed" -ForegroundColor Green
    } else {
        Write-Host "Rollback failed! Please check server manually" -ForegroundColor Red
    }
    exit 1
}
Write-Host ""

# Step 9: Automated Testing
Write-Host "[9/9] Running automated tests..." -ForegroundColor Yellow
Write-Host ""

Write-Host "   Waiting for service to be ready (60 seconds)..." -ForegroundColor Gray
Start-Sleep -Seconds 60

$testsPassed = 0
$testsFailed = 0

# Test 1: Health Check
Write-Host "   [1/6] Testing health endpoint..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "https://$Domain/health" -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "      PASS - Health check OK" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "      FAIL - Status code: $($response.StatusCode)" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "      FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}

# Test 2: Wechat Health
Write-Host "   [2/6] Testing WeChat health..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "https://$Domain/Wechat/Health" -TimeoutSec 10 -UseBasicParsing
    $data = $response.Content | ConvertFrom-Json
    if ($data.status -eq "healthy") {
        Write-Host "      PASS - WeChat service healthy" -ForegroundColor Green
        Write-Host "      Certificate: $($data.certificatePath)" -ForegroundColor Gray
        $testsPassed++
    } else {
        Write-Host "      FAIL - Service not healthy" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "      FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}

# Test 3: Swagger
Write-Host "   [3/6] Testing Swagger API docs..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "https://$Domain/swagger/index.html" -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200 -and $response.Content -match "swagger") {
        Write-Host "      PASS - Swagger accessible" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "      FAIL - Swagger not working" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "      FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}

# Test 4: Test Page
Write-Host "   [4/6] Testing WeChat refund demo page..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "https://$Domain/wechat-refund-demo.html" -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "      PASS - Demo page accessible" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "      FAIL - Demo page not accessible" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "      FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}

# Test 5: Container Status
Write-Host "   [5/6] Checking container status..." -ForegroundColor Cyan
$containerStatus = & ssh -i "$SshKeyPath" "${SshUser}@${ServerHost}" "docker ps --filter name=abc-payment-gateway --format '{{.Status}}'" 2>&1
if ($containerStatus -match "Up") {
    Write-Host "      PASS - Container running: $containerStatus" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "      FAIL - Container not running properly" -ForegroundColor Red
    $testsFailed++
}

# Test 6: Traefik Status (ensure not affected)
Write-Host "   [6/6] Verifying Traefik status..." -ForegroundColor Cyan
$traefikStatus = & ssh -i "$SshKeyPath" "${SshUser}@${ServerHost}" "docker ps --filter name=traefik --format '{{.Status}}'" 2>&1
if ($traefikStatus -match "Up") {
    Write-Host "      PASS - Traefik still running: $traefikStatus" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "      FAIL - Traefik may have been affected!" -ForegroundColor Red
    $testsFailed++
}

Write-Host ""
Write-Host "========================================"
Write-Host "   Test Summary"
Write-Host "========================================"
Write-Host ""
Write-Host "Total Tests: $($testsPassed + $testsFailed)"
Write-Host "Passed: $testsPassed" -ForegroundColor Green
Write-Host "Failed: $testsFailed" -ForegroundColor Red
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "========================================"
    Write-Host "   DEPLOYMENT SUCCESSFUL" -ForegroundColor Green
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Service URLs:"
    Write-Host "  Main: https://$Domain" -ForegroundColor White
    Write-Host "  Swagger: https://$Domain/swagger" -ForegroundColor White
    Write-Host "  Health: https://$Domain/health" -ForegroundColor White
    Write-Host "  WeChat Test: https://$Domain/wechat-refund-demo.html" -ForegroundColor White
    Write-Host ""
    Write-Host "Management:"
    Write-Host "  View logs: ssh -i `"$SshKeyPath`" $SshUser@$ServerHost 'docker logs -f abc-payment-gateway'" -ForegroundColor Gray
    Write-Host "  Restart: ssh -i `"$SshKeyPath`" $SshUser@$ServerHost 'cd $DeployPath && docker-compose restart'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Backup location: $backupPath" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "========================================"
    Write-Host "   DEPLOYMENT COMPLETED WITH WARNINGS" -ForegroundColor Yellow
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Some tests failed. Please check the logs:" -ForegroundColor Yellow
    Write-Host "  ssh -i `"$SshKeyPath`" $SshUser@$ServerHost 'docker logs abc-payment-gateway'" -ForegroundColor Gray
    Write-Host ""
}

exit 0
