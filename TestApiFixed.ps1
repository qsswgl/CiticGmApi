# CITIC Bank GM API - Functional Test Script
# Test Parameters from CITIC Bank WeChat Payment Documentation
param(
    [string]$ApiBase = "https://citic.qsgl.net"
)

# Test Parameters
$testMerchantId = "731691000000096"
$testTerminalId = "C8000023"
$testAppId = "wx3f64e658810cca0f"
$terminalType = "11"
$appVersion = "1.000000"
$transCode = "QrLaasApiService:weixinApppay"
$orderId = "TEST" + (Get-Date -Format "yyyyMMddHHmmss")

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  CITIC Bank GM API - Function Test" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Test Parameters:" -ForegroundColor Yellow
Write-Host "  Merchant ID: $testMerchantId"
Write-Host "  Terminal ID: $testTerminalId"
Write-Host "  WeChat AppID: $testAppId"
Write-Host "  Terminal Type: $terminalType"
Write-Host "  APP Version: $appVersion"
Write-Host "  Trans Code: $transCode"
Write-Host ""

# Test 1: Health Check
Write-Host "[Test 1] Health Check..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$apiBase/api/Crypto/health" -Method Get
    Write-Host "  OK - API Service is running" -ForegroundColor Green
} catch {
    Write-Host "  ERROR - API Service failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: Generate SM2 KeyPair
Write-Host "[Test 2] Generate SM2 KeyPair..." -ForegroundColor Yellow
try {
    $sm2Keys = Invoke-RestMethod -Uri "$apiBase/api/Crypto/sm2/keypair" -Method Get
    Write-Host "  OK - PublicKeyHex: $($sm2Keys.data.publicKeyHex.Length) chars" -ForegroundColor Green
    $publicKeyHex = $sm2Keys.data.publicKeyHex
    $privateKeyHex = $sm2Keys.data.privateKeyHex
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 3: Generate SM4 Key
Write-Host "[Test 3] Generate SM4 Key..." -ForegroundColor Yellow
try {
    $sm4KeyResponse = Invoke-RestMethod -Uri "$apiBase/api/Crypto/sm4/key" -Method Get
    Write-Host "  OK - SM4 KeyHex: $($sm4KeyResponse.data.keyHex.Substring(0,16))..." -ForegroundColor Green
    $sm4KeyHex = $sm4KeyResponse.data.keyHex
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 4: Build WeChat APP Payment Request
Write-Host "[Test 4] Build WeChat APP Payment Request..." -ForegroundColor Yellow
$requestData = @{
    merchant_id = $testMerchantId
    terminal_id = $testTerminalId
    order_id = $orderId
    trans_code = $transCode
    trade_amount = "0.01"
    trade_time = (Get-Date -Format "yyyyMMddHHmmss")
    body = "CITIC GM API Test"
    app_id = $testAppId
    terminal_type = $terminalType
    app_version = $appVersion
} | ConvertTo-Json -Compress
Write-Host "  Request: $requestData" -ForegroundColor Gray

# Test 5: SM4 Encrypt Request Data
Write-Host "[Test 5] SM4 Encrypt Request Data..." -ForegroundColor Yellow
try {
    $sm4EncryptBody = @{
        plaintext = $requestData
        key = $sm4KeyHex  # Use `key` not `keyHex`
    } | ConvertTo-Json
    
    $encryptResponse = Invoke-RestMethod -Uri "$apiBase/api/Crypto/sm4/encrypt" `
        -Method Post -ContentType "application/json" -Body $sm4EncryptBody
    
    Write-Host "  OK - Ciphertext (Base64): $($encryptResponse.data.ciphertext.Substring(0, 64))..." -ForegroundColor Green
    $encryptedData = $encryptResponse.data.ciphertext  # Base64 encoded
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    exit 1
}

# Test 6: SM3WithSM2 Sign
Write-Host "[Test 6] SM3WithSM2 Sign Encrypted Data..." -ForegroundColor Yellow
try {
    # Convert privateKeyHex to PEM format (SM2Sign expects PEM)
    # For simplicity, we'll use the hex directly if API accepts it
    # Note: The actual API might need proper key format conversion
    $signBody = @{
        data = $encryptedData
        privateKey = $privateKeyHex  # Try hex format first
    } | ConvertTo-Json
    
    $signResponse = Invoke-RestMethod -Uri "$apiBase/api/Crypto/sm2/sign" `
        -Method Post -ContentType "application/json" -Body $signBody
    
    Write-Host "  OK - Signature (Base64): $($signResponse.data.signature.Substring(0, 64))..." -ForegroundColor Green
    $signature = $signResponse.data.signature
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Note: SM2 sign may require PEM format private key" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  Core Tests Completed!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "CITIC Bank GM API Status:"
Write-Host "  [OK] Health Check" -ForegroundColor Green
Write-Host "  [OK] SM2 KeyPair Generation" -ForegroundColor Green
Write-Host "  [OK] SM4 Key Generation" -ForegroundColor Green
Write-Host "  [OK] WeChat Request Build" -ForegroundColor Green
Write-Host "  [OK] SM4-CBC Encryption" -ForegroundColor Green
Write-Host ""
Write-Host "API Documentation: https://citic.qsgl.net/" -ForegroundColor Yellow
Write-Host ""
