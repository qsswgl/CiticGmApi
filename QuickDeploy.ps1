# Quick Deploy Script
$sshKey = "K:\Key\tx.qsgl.net_id_ed25519"
$server = "root@tx.qsgl.net"
$deployPath = "/opt/citic-gm-api"

Write-Host "=== Checking Docker Build Status ===" -ForegroundColor Cyan
ssh.exe -i $sshKey $server "cd $deployPath && docker images | head -20"

Write-Host "`n=== Building Docker Image ===" -ForegroundColor Cyan
ssh.exe -i $sshKey $server "cd $deployPath && docker build -t citic-gm-api:latest ."

Write-Host "`n=== Starting Container ===" -ForegroundColor Cyan
ssh.exe -i $sshKey $server "cd $deployPath && docker-compose up -d"

Write-Host "`n=== Waiting for Service ===" -ForegroundColor Cyan
Start-Sleep -Seconds 15

Write-Host "`n=== Checking Status ===" -ForegroundColor Cyan
ssh.exe -i $sshKey $server "docker ps | grep citic && docker logs citic-gm-api --tail 20"

Write-Host "`n=== Testing Health ===" -ForegroundColor Cyan
ssh.exe -i $sshKey $server "curl -s http://localhost:8080/api/Crypto/health"

Write-Host "`n`nDeployment Complete!" -ForegroundColor Green
Write-Host "Access Swagger at: https://citic.qsgl.net/" -ForegroundColor Yellow
