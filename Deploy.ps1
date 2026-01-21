# ================================================
# CITIC Bank GM API - Automated Deployment Script
# ================================================

param(
    [string]$ServerHost = "tx.qsgl.net",
    [string]$ServerUser = "root",
    [string]$SshKeyPath = "K:\Key\tx.qsgl.net_id_ed25519",
    [string]$AppName = "citic-gm-api",
    [string]$DeployPath = "/opt/citic-gm-api"
)

$ErrorActionPreference = "Stop"
$env:Path += ";C:\Program Files\dotnet"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  CITIC Bank GM API Deployment Tool" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Clean old build files
Write-Host "[1/7] Cleaning old build files..." -ForegroundColor Yellow
@(".\publish", ".\bin", ".\obj") | ForEach-Object {
    if (Test-Path $_) {
        Remove-Item -Path $_ -Recurse -Force
    }
}
Write-Host "  Done" -ForegroundColor Green

# Step 2: Restore dependencies
Write-Host ""
Write-Host "[2/7] Restoring NuGet packages..." -ForegroundColor Yellow
dotnet restore
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Restore failed" -ForegroundColor Red
    exit 1
}
Write-Host "  Done" -ForegroundColor Green

# Step 3: Build project
Write-Host ""
Write-Host "[3/7] Building project..." -ForegroundColor Yellow
dotnet build -c Release
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Build failed" -ForegroundColor Red
    exit 1
}
Write-Host "  Done" -ForegroundColor Green

# Step 4: Publish project
Write-Host ""
Write-Host "[4/7] Publishing project..." -ForegroundColor Yellow
dotnet publish -c Release -o .\publish --self-contained true -r linux-x64
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Publish failed" -ForegroundColor Red
    exit 1
}
Write-Host "  Done" -ForegroundColor Green

# Step 5: Prepare deployment files
Write-Host ""
Write-Host "[5/7] Preparing deployment package..." -ForegroundColor Yellow

Copy-Item -Path ".\Dockerfile" -Destination ".\publish\" -Force
Copy-Item -Path ".\Dockerfile.published" -Destination ".\publish\Dockerfile" -Force
Copy-Item -Path ".\docker-compose.yml" -Destination ".\publish\" -Force
if (Test-Path ".\.dockerignore") {
    Copy-Item -Path ".\.dockerignore" -Destination ".\publish\" -Force
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$tarFile = "citic-gm-api-$timestamp.tar.gz"

Push-Location .\publish
tar -czf "..\$tarFile" *
Pop-Location

if (-not (Test-Path $tarFile)) {
    Write-Host "  ERROR: Failed to create package" -ForegroundColor Red
    exit 1
}

Write-Host "  Done: $tarFile" -ForegroundColor Green

# Step 6: Upload to server
Write-Host ""
Write-Host "[6/7] Uploading to server..." -ForegroundColor Yellow

$remoteCmd1 = 'mkdir -p /opt/citic-gm-api && rm -rf /opt/citic-gm-api/*'
ssh.exe -i $SshKeyPath -o StrictHostKeyChecking=no "$ServerUser@$ServerHost" $remoteCmd1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Failed to create remote directory" -ForegroundColor Red
    exit 1
}

scp.exe -i $SshKeyPath -o StrictHostKeyChecking=no $tarFile "${ServerUser}@${ServerHost}:${DeployPath}/"
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Failed to upload files" -ForegroundColor Red
    exit 1
}

Write-Host "  Done" -ForegroundColor Green

# Step 7: Deploy on server
Write-Host ""
Write-Host "[7/7] Deploying on server..." -ForegroundColor Yellow

# Create deployment script
$deployScript = @'
#!/bin/bash
set -e

cd /opt/citic-gm-api

echo "Extracting files..."
tar -xzf citic-gm-api-*.tar.gz
rm -f citic-gm-api-*.tar.gz

echo "Checking Docker..."
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is not running"
    exit 1
fi

echo "Checking traefik network..."
if ! docker network inspect traefik-net > /dev/null 2>&1; then
    echo "Creating traefik-net..."
    docker network create traefik-net
fi

echo "Stopping old container..."
if docker ps -a --format '{{.Names}}' | grep -q '^citic-gm-api$'; then
    docker stop citic-gm-api || true
    docker rm citic-gm-api || true
fi

echo "Removing old images..."
docker images | grep citic-gm-api | awk '{print $3}' | xargs -r docker rmi -f || true

echo "Building Docker image..."
docker build -t citic-gm-api:latest .

echo "Starting container..."
docker-compose up -d

echo "Waiting for service to start..."
sleep 15

echo "Health check..."
for i in {1..10}; do
    if curl -s http://localhost:8080/api/Crypto/health | grep -q 'healthy'; then
        echo "SUCCESS: Service is running!"
        break
    fi
    if [ $i -eq 10 ]; then
        echo "ERROR: Service failed to start"
        docker logs citic-gm-api --tail 50
        exit 1
    fi
    echo "Waiting... ($i/10)"
    sleep 3
done

echo ""
echo "=========================================="
echo "  Deployment Complete!"
echo "=========================================="
echo ""
docker ps --filter 'name=citic-gm-api' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
echo ""
echo "URLs:"
echo "  - Swagger: https://citic.qsgl.net/"
echo "  - Health: https://citic.qsgl.net/api/Crypto/health"
echo ""
'@

# Save script to temp file
$tempScript = [System.IO.Path]::GetTempFileName()
$deployScript | Out-File -FilePath $tempScript -Encoding UTF8 -NoNewline

# Convert to Unix line endings
$content = Get-Content $tempScript -Raw
$content = $content -replace "`r`n", "`n"
[System.IO.File]::WriteAllText($tempScript, $content)

# Upload and execute script
scp.exe -i $SshKeyPath -o StrictHostKeyChecking=no $tempScript "${ServerUser}@${ServerHost}:${DeployPath}/deploy.sh"
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Failed to upload deployment script" -ForegroundColor Red
    Remove-Item $tempScript -Force
    exit 1
}

$remoteCmd2 = 'chmod +x /opt/citic-gm-api/deploy.sh && /opt/citic-gm-api/deploy.sh'
ssh.exe -i $SshKeyPath -o StrictHostKeyChecking=no "$ServerUser@$ServerHost" $remoteCmd2
$deployExitCode = $LASTEXITCODE

# Cleanup
Remove-Item $tempScript -Force

if ($deployExitCode -ne 0) {
    Write-Host "  ERROR: Deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "  Done" -ForegroundColor Green

# Step 8: Cleanup local files
Write-Host ""
Write-Host "Cleaning up local files..." -ForegroundColor Yellow
Remove-Item -Path $tarFile -Force
Write-Host "  Done" -ForegroundColor Green

# Complete
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  Deployment Successful!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Service Information:" -ForegroundColor Cyan
Write-Host "  - App Name: $AppName" -ForegroundColor White
Write-Host "  - Deploy Path: $DeployPath" -ForegroundColor White
Write-Host "  - Swagger: https://citic.qsgl.net/" -ForegroundColor White
Write-Host "  - Health: https://citic.qsgl.net/api/Crypto/health" -ForegroundColor White
Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor Cyan
Write-Host "  View logs: ssh.exe -i $SshKeyPath $ServerUser@$ServerHost 'docker logs -f $AppName'" -ForegroundColor White
Write-Host "  Stop: ssh.exe -i $SshKeyPath $ServerUser@$ServerHost 'cd $DeployPath && docker-compose down'" -ForegroundColor White
Write-Host "  Restart: ssh.exe -i $SshKeyPath $ServerUser@$ServerHost 'cd $DeployPath && docker-compose restart'" -ForegroundColor White
Write-Host ""
