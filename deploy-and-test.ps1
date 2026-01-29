# 腾讯云自动化部署并测试脚本
# 支持微信退款API的完整部署和自动化测试

param(
    [string]$ServerHost = "tx.qsgl.net",
    [string]$SshKeyPath = "K:\Key\tx.qsgl.net_id_ed25519",
    [string]$SshUser = "root",
    [string]$DeployPath = "/opt/abc-payment",
    [string]$Domain = "payment.qsgl.net"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   农行支付网关 - 自动部署与测试" -ForegroundColor Green
Write-Host "   包含微信退款API支持" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 配置信息
Write-Host "📋 部署配置:" -ForegroundColor Yellow
Write-Host "   服务器: $ServerHost" -ForegroundColor Gray
Write-Host "   域名: https://$Domain" -ForegroundColor Gray
Write-Host "   部署路径: $DeployPath" -ForegroundColor Gray
Write-Host ""

# ============ 第一步：编译打包 ============
Write-Host "[1/8] 编译并打包项目..." -ForegroundColor Yellow

# 清理旧的发布文件
if (Test-Path ".\bin\Release\net10.0\publish") {
    Remove-Item ".\bin\Release\net10.0\publish" -Recurse -Force
}

# 编译项目
Write-Host "   编译项目..." -ForegroundColor Gray
dotnet build -c Release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 编译失败" -ForegroundColor Red
    exit 1
}

# 发布项目
Write-Host "   发布项目..." -ForegroundColor Gray
dotnet publish -c Release -o .\bin\Release\net10.0\publish
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 发布失败" -ForegroundColor Red
    exit 1
}

Write-Host "   ✅ 编译打包完成" -ForegroundColor Green
Write-Host ""

# ============ 第二步：准备部署包 ============
Write-Host "[2/8] 准备部署包..." -ForegroundColor Yellow

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$deployDir = ".\deploy-temp"
$deployZip = "AbcPaymentGateway_Deploy_$timestamp.zip"

# 清理临时目录
if (Test-Path $deployDir) {
    Remove-Item $deployDir -Recurse -Force
}
New-Item -ItemType Directory -Path $deployDir | Out-Null

# 复制发布文件
Write-Host "   复制发布文件..." -ForegroundColor Gray
Copy-Item ".\bin\Release\net10.0\publish\*" -Destination $deployDir -Recurse

# 复制Dockerfile
Write-Host "   复制Dockerfile..." -ForegroundColor Gray
Copy-Item ".\Dockerfile" -Destination $deployDir

# 复制docker-compose配置
Write-Host "   复制docker-compose配置..." -ForegroundColor Gray

# 直接复制现有的docker-compose.traefik.yml
Copy-Item "K:\payment\deploy\docker-compose.traefik.yml" -Destination "$deployDir\docker-compose.yml"

# 修改端口从5000到8080
(Get-Content "$deployDir\docker-compose.yml") -replace 'port=5000', 'port=8080' | Set-Content "$deployDir\docker-compose.yml"
(Get-Content "$deployDir\docker-compose.yml") -replace 'http://\+:5000', 'http://+:8080' | Set-Content "$deployDir\docker-compose.yml"
(Get-Content "$deployDir\docker-compose.yml") -replace 'localhost:5000', 'localhost:8080' | Set-Content "$deployDir\docker-compose.yml"

# 添加微信证书挂载
$composeContent = Get-Content "$deployDir\docker-compose.yml" -Raw
$composeContent = $composeContent -replace '(- \./cert:/app/cert:ro)', "`$1`n      - ../Wechat/cert:/app/Wechat/cert:ro"
$composeContent | Set-Content "$deployDir\docker-compose.yml" -NoNewline

# 打包
Write-Host "   打包部署文件..." -ForegroundColor Gray
Compress-Archive -Path "$deployDir\*" -DestinationPath $deployZip -Force

Write-Host "   ✅ 部署包准备完成: $deployZip" -ForegroundColor Green
Write-Host "   大小: $([math]::Round((Get-Item $deployZip).Length/1MB, 2)) MB" -ForegroundColor Gray
Write-Host ""

# 清理临时目录
Remove-Item $deployDir -Recurse -Force

# ============ 第三步：测试SSH连接 ============
Write-Host "[3/8] 测试SSH连接..." -ForegroundColor Yellow

if (-not (Test-Path $SshKeyPath)) {
    Write-Host "❌ SSH密钥不存在: $SshKeyPath" -ForegroundColor Red
    exit 1
}

$sshTest = & ssh -i "$SshKeyPath" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${SshUser}@${ServerHost}" "echo OK" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ SSH连接失败" -ForegroundColor Red
    Write-Host $sshTest
    exit 1
}

Write-Host "   ✅ SSH连接成功" -ForegroundColor Green
Write-Host ""

# ============ 第四步：上传部署包 ============
Write-Host "[4/8] 上传部署包到服务器..." -ForegroundColor Yellow

# 创建部署目录
& ssh -i "$SshKeyPath" "${SshUser}@${ServerHost}" "mkdir -p $DeployPath" 2>&1 | Out-Null

# 上传部署包
Write-Host "   上传文件 ($(([math]::Round((Get-Item $deployZip).Length/1MB, 2))) MB)..." -ForegroundColor Gray
& scp -i "$SshKeyPath" -o StrictHostKeyChecking=no "$deployZip" "${SshUser}@${ServerHost}:${DeployPath}/" 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 上传失败" -ForegroundColor Red
    exit 1
}

Write-Host "   ✅ 上传完成" -ForegroundColor Green
Write-Host ""

# ============ 第五步：解压并配置 ============
Write-Host "[5/8] 解压并配置文件..." -ForegroundColor Yellow

$deployScript = @"
#!/bin/bash
set -e
cd $DeployPath

# 解压部署包
echo "解压部署包..."
unzip -o $deployZip
rm -f $deployZip

# 设置权限
chmod +x *.dll || true

# 检查Traefik网络
if ! docker network inspect traefik-public >/dev/null 2>&1; then
    echo "创建traefik-public网络..."
    docker network create traefik-public
fi

echo "配置完成"
"@

$deployScript | & ssh -i "$SshKeyPath" "${SshUser}@${ServerHost}" "cat > $DeployPath/deploy.sh && chmod +x $DeployPath/deploy.sh && bash $DeployPath/deploy.sh"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 配置失败" -ForegroundColor Red
    exit 1
}

Write-Host "   ✅ 配置完成" -ForegroundColor Green
Write-Host ""

# ============ 第六步：停止旧容器并构建新镜像 ============
Write-Host "[6/8] 停止旧容器并构建新镜像..." -ForegroundColor Yellow

$buildScript = @"
#!/bin/bash
set -e
cd $DeployPath

# 停止并删除旧容器（不影响Traefik）
if docker ps -a | grep -q abc-payment-gateway; then
    echo "停止旧容器..."
    docker-compose down --remove-orphans || true
fi

# 构建新镜像
echo "构建Docker镜像..."
docker-compose build --no-cache

echo "构建完成"
"@

$buildScript | & ssh -i "$SshKeyPath" "${SshUser}@${ServerHost}" "cat > $DeployPath/build.sh && chmod +x $DeployPath/build.sh && bash $DeployPath/build.sh"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 构建失败" -ForegroundColor Red
    exit 1
}

Write-Host "   ✅ 镜像构建完成" -ForegroundColor Green
Write-Host ""

# ============ 第七步：启动容器 ============
Write-Host "[7/8] 启动容器..." -ForegroundColor Yellow

$startScript = @"
#!/bin/bash
set -e
cd $DeployPath

# 启动容器
echo "启动容器..."
docker-compose up -d

# 等待容器启动
sleep 5

# 检查容器状态
if docker ps | grep -q abc-payment-gateway; then
    echo "✅ 容器启动成功"
    docker ps --filter name=abc-payment-gateway --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    echo "❌ 容器启动失败"
    docker logs abc-payment-gateway --tail 50
    exit 1
fi
"@

$startScript | & ssh -i "$SshKeyPath" "${SshUser}@${ServerHost}" "cat > $DeployPath/start.sh && chmod +x $DeployPath/start.sh && bash $DeployPath/start.sh"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 启动失败" -ForegroundColor Red
    exit 1
}

Write-Host "   ✅ 容器启动成功" -ForegroundColor Green
Write-Host ""

# 清理本地部署包
Remove-Item $deployZip -Force

# ============ 第八步：自动化测试 ============
Write-Host "[8/8] 执行自动化测试..." -ForegroundColor Yellow
Write-Host ""

# 等待服务就绪
Write-Host "   等待服务就绪 (60秒)..." -ForegroundColor Gray
Start-Sleep -Seconds 60

# 测试结果
$testResults = @()

# 测试1: 健康检查
Write-Host "   [测试 1/5] 健康检查端点..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "https://$Domain/health" -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "      ✅ 健康检查通过 (200 OK)" -ForegroundColor Green
        $testResults += @{Test="健康检查"; Status="✅ 通过"; Details=$response.Content}
    } else {
        Write-Host "      ❌ 健康检查失败 (状态码: $($response.StatusCode))" -ForegroundColor Red
        $testResults += @{Test="健康检查"; Status="❌ 失败"; Details="状态码: $($response.StatusCode)"}
    }
} catch {
    Write-Host "      ❌ 健康检查失败: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test="健康检查"; Status="❌ 失败"; Details=$_.Exception.Message}
}
Write-Host ""

# 测试2: 微信退款健康检查
Write-Host "   [测试 2/5] 微信退款健康检查..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "https://$Domain/Wechat/Health" -TimeoutSec 10 -UseBasicParsing
    $content = $response.Content | ConvertFrom-Json
    if ($content.status -eq "healthy") {
        Write-Host "      ✅ 微信服务健康 (证书路径: $($content.certificatePath))" -ForegroundColor Green
        $testResults += @{Test="微信服务健康"; Status="✅ 通过"; Details="证书: $($content.certificatePath)"}
    } else {
        Write-Host "      ⚠️  微信服务健康检查警告" -ForegroundColor Yellow
        $testResults += @{Test="微信服务健康"; Status="⚠️  警告"; Details=$response.Content}
    }
} catch {
    Write-Host "      ❌ 微信服务健康检查失败: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test="微信服务健康"; Status="❌ 失败"; Details=$_.Exception.Message}
}
Write-Host ""

# 测试3: Swagger文档
Write-Host "   [测试 3/5] Swagger API文档..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "https://$Domain/swagger/index.html" -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200 -and $response.Content -match "swagger") {
        Write-Host "      ✅ Swagger文档可访问" -ForegroundColor Green
        $testResults += @{Test="Swagger文档"; Status="✅ 通过"; Details="https://$Domain/swagger"}
    } else {
        Write-Host "      ❌ Swagger文档不可用" -ForegroundColor Red
        $testResults += @{Test="Swagger文档"; Status="❌ 失败"; Details="无法加载Swagger UI"}
    }
} catch {
    Write-Host "      ❌ Swagger文档访问失败: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test="Swagger文档"; Status="❌ 失败"; Details=$_.Exception.Message}
}
Write-Host ""

# 测试4: 测试页面
Write-Host "   [测试 4/5] 微信退款测试页面..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "https://$Domain/wechat-refund-demo.html" -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200 -and $response.Content -match "微信服务商退款") {
        Write-Host "      ✅ 测试页面可访问" -ForegroundColor Green
        $testResults += @{Test="测试页面"; Status="✅ 通过"; Details="https://$Domain/wechat-refund-demo.html"}
    } else {
        Write-Host "      ❌ 测试页面不可用" -ForegroundColor Red
        $testResults += @{Test="测试页面"; Status="❌ 失败"; Details="页面内容异常"}
    }
} catch {
    Write-Host "      ❌ 测试页面访问失败: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test="测试页面"; Status="❌ 失败"; Details=$_.Exception.Message}
}
Write-Host ""

# 测试5: 容器状态检查
Write-Host "   [测试 5/5] 容器运行状态..." -ForegroundColor Cyan
$containerStatus = & ssh -i "$SshKeyPath" "${SshUser}@${ServerHost}" "docker ps --filter name=abc-payment-gateway --format '{{.Status}}'" 2>&1
if ($containerStatus -match "Up") {
    Write-Host "      ✅ 容器运行正常" -ForegroundColor Green
    Write-Host "      状态: $containerStatus" -ForegroundColor Gray
    $testResults += @{Test="容器状态"; Status="✅ 通过"; Details=$containerStatus}
} else {
    Write-Host "      ❌ 容器状态异常" -ForegroundColor Red
    $testResults += @{Test="容器状态"; Status="❌ 失败"; Details=$containerStatus}
}
Write-Host ""

# ============ 测试总结 ============
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   📊 测试报告" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$passCount = ($testResults | Where-Object { $_.Status -match "✅" }).Count
$failCount = ($testResults | Where-Object { $_.Status -match "❌" }).Count
$warnCount = ($testResults | Where-Object { $_.Status -match "⚠️" }).Count

foreach ($result in $testResults) {
    Write-Host "  $($result.Test): $($result.Status)" -ForegroundColor $(
        if ($result.Status -match "✅") { "Green" }
        elseif ($result.Status -match "❌") { "Red" }
        else { "Yellow" }
    )
}

Write-Host ""
Write-Host "总计: $($testResults.Count) 个测试" -ForegroundColor Gray
Write-Host "  ✅ 通过: $passCount" -ForegroundColor Green
Write-Host "  ❌ 失败: $failCount" -ForegroundColor Red
if ($warnCount -gt 0) {
    Write-Host "  ⚠️  警告: $warnCount" -ForegroundColor Yellow
}
Write-Host ""

# ============ 部署信息 ============
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   🚀 部署完成" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📍 访问地址:" -ForegroundColor Yellow
Write-Host "   主页: https://$Domain" -ForegroundColor White
Write-Host "   Swagger: https://$Domain/swagger" -ForegroundColor White
Write-Host "   健康检查: https://$Domain/health" -ForegroundColor White
Write-Host "   微信退款测试: https://$Domain/wechat-refund-demo.html" -ForegroundColor White
Write-Host ""
Write-Host "🔧 管理命令:" -ForegroundColor Yellow
Write-Host "   查看日志:" -ForegroundColor Gray
Write-Host "   ssh -i `"$SshKeyPath`" $SshUser@$ServerHost 'docker logs -f abc-payment-gateway'" -ForegroundColor DarkGray
Write-Host ""
Write-Host "   重启服务:" -ForegroundColor Gray
Write-Host "   ssh -i `"$SshKeyPath`" $SshUser@$ServerHost 'cd $DeployPath && docker-compose restart'" -ForegroundColor DarkGray
Write-Host ""
Write-Host "   停止服务:" -ForegroundColor Gray
Write-Host "   ssh -i `"$SshKeyPath`" $SshUser@$ServerHost 'cd $DeployPath && docker-compose down'" -ForegroundColor DarkGray
Write-Host ""

if ($failCount -gt 0) {
    Write-Host "⚠️  部分测试失败，请检查日志" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "✅ 所有测试通过，部署成功！" -ForegroundColor Green
    exit 0
}
