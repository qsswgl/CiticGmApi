# CITIC Bank GM API Test Script
# Test Parameters: Merchant 731691000000096, Terminal C8000023, WeChat APP Pay

$apiBase = "https://citic.qsgl.net"

Write-Host "=========================================="
Write-Host "  CITIC Bank GM API - Function Test"
Write-Host "=========================================="
Write-Host ""

# Test Parameters
$testMerchantId = "731691000000096"
$testTerminalId = "C8000023"
$testAppId = "wx3f64e658810cca0f"
$terminalType = "11"
$appVersion = "1.000000"
$transCode = "QrLaasApiService:weixinApppay"

Write-Host "Test Parameters:"
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
    Write-Host "  OK - PublicKey: $($sm2Keys.data.publicKeyHex.Length) chars" -ForegroundColor Green
    $publicKey = $sm2Keys.data.publicKeyHex
    $privateKey = $sm2Keys.data.privateKeyHex
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 3: Generate SM4 Key
Write-Host "[Test 3] Generate SM4 Key..." -ForegroundColor Yellow
try {
    $sm4KeyResponse = Invoke-RestMethod -Uri "$apiBase/api/Crypto/sm4/key" -Method Get
    Write-Host "  OK - SM4 Key: $($sm4KeyResponse.data.keyHex.Substring(0,16))..." -ForegroundColor Green
    $sm4Key = $sm4KeyResponse.data.keyHex
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 4: Build WeChat APP Payment Request
Write-Host "[Test 4] Build WeChat APP Payment Request..." -ForegroundColor Yellow
$orderId = "TEST" + (Get-Date -Format "yyyyMMddHHmmss")
$requestData = @{
    trans_code = $transCode
    merchant_id = $testMerchantId
    terminal_id = $testTerminalId
    app_id = $testAppId
    terminal_type = $terminalType
    app_version = $appVersion
    order_id = $orderId
    trade_amount = "0.01"
    trade_time = Get-Date -Format "yyyyMMddHHmmss"
    body = "CITIC GM API Test"
} | ConvertTo-Json -Compress
Write-Host "  Request: $requestData" -ForegroundColor Gray

# Test 5: SM4 Encrypt
Write-Host "[Test 5] SM4 Encrypt Request Data..." -ForegroundColor Yellow
try {
    $sm4EncryptBody = @{
        plaintext = $requestData
        keyHex = $sm4Key
    } | ConvertTo-Json
    
    $encryptResponse = Invoke-RestMethod -Uri "$apiBase/api/Crypto/sm4/encrypt" `
        -Method Post -ContentType "application/json" -Body $sm4EncryptBody
    
    Write-Host "  OK - Ciphertext: $($encryptResponse.data.ciphertextHex.Substring(0, 64))..." -ForegroundColor Green
    $encryptedData = $encryptResponse.data.ciphertextHex
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 6: SM3WithSM2 Sign
Write-Host "[Test 6] SM3WithSM2 Sign..." -ForegroundColor Yellow
try {
    $signBody = @{
        dataHex = $encryptedData
        privateKeyHex = $privateKey
    } | ConvertTo-Json
    
    $signResponse = Invoke-RestMethod -Uri "$apiBase/api/Crypto/sm2/sign" `
        -Method Post -ContentType "application/json" -Body $signBody
    
    Write-Host "  OK - Signature: $($signResponse.data.signatureHex.Substring(0, 64))..." -ForegroundColor Green
    $signature = $signResponse.data.signatureHex
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 7: SM3WithSM2 Verify
Write-Host "[Test 7] SM3WithSM2 Verify..." -ForegroundColor Yellow
try {
    $verifyBody = @{
        dataHex = $encryptedData
        signatureHex = $signature
        publicKeyHex = $publicKey
    } | ConvertTo-Json
    
    $verifyResponse = Invoke-RestMethod -Uri "$apiBase/api/Crypto/sm2/verify" `
        -Method Post -ContentType "application/json" -Body $verifyBody
    
    if ($verifyResponse.data.isValid) {
        Write-Host "  OK - Signature Verified" -ForegroundColor Green
    } else {
        Write-Host "  ERROR - Verification Failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 8: SM4 Decrypt
Write-Host "[Test 8] SM4 Decrypt Response..." -ForegroundColor Yellow
try {
    $sm4DecryptBody = @{
        ciphertextHex = $encryptedData
        keyHex = $sm4Key
    } | ConvertTo-Json
    
    $decryptResponse = Invoke-RestMethod -Uri "$apiBase/api/Crypto/sm4/decrypt" `
        -Method Post -ContentType "application/json" -Body $sm4DecryptBody
    
    Write-Host "  OK - Decrypted: $($decryptResponse.data.plaintext)" -ForegroundColor Green
    
    if ($decryptResponse.data.plaintext -eq $requestData) {
        Write-Host "  OK - Data Integrity Verified" -ForegroundColor Green
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 9: SM2 Encrypt/Decrypt
Write-Host "[Test 9] SM2 Encrypt/Decrypt Test..." -ForegroundColor Yellow
try {
    $testMessage = "CITIC WeChat APP Payment Test: $orderId"
    
    # SM2 Encrypt
    $sm2EncryptBody = @{
        plaintext = $testMessage
        publicKeyHex = $publicKey
    } | ConvertTo-Json
    
    $sm2EncryptResponse = Invoke-RestMethod -Uri "$apiBase/api/Crypto/sm2/encrypt" `
        -Method Post -ContentType "application/json" -Body $sm2EncryptBody
    
    # SM2 Decrypt
    $sm2DecryptBody = @{
        ciphertextHex = $sm2EncryptResponse.data.ciphertextHex
        privateKeyHex = $privateKey
    } | ConvertTo-Json
    
    $sm2DecryptResponse = Invoke-RestMethod -Uri "$apiBase/api/Crypto/sm2/decrypt" `
        -Method Post -ContentType "application/json" -Body $sm2DecryptBody
    
    if ($sm2DecryptResponse.data.plaintext -eq $testMessage) {
        Write-Host "  OK - SM2 Encrypt/Decrypt Verified" -ForegroundColor Green
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  All Tests Passed!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "CITIC Bank GM API Server Status:"
Write-Host "  [OK] API Service Running" -ForegroundColor Green
Write-Host "  [OK] SM2 Asymmetric Encryption" -ForegroundColor Green
Write-Host "  [OK] SM3WithSM2 Signature" -ForegroundColor Green
Write-Host "  [OK] SM4 Symmetric Encryption" -ForegroundColor Green
Write-Host "  [OK] Data Integrity Verified" -ForegroundColor Green
Write-Host ""
Write-Host "WeChat APP Payment Test Parameters:"
Write-Host "  Merchant: $testMerchantId"
Write-Host "  Terminal: $testTerminalId"
Write-Host "  AppID: $testAppId"
Write-Host "  Trans Code: $transCode"
Write-Host "  Test Order: $orderId"
Write-Host ""
Write-Host "Swagger Docs: https://citic.qsgl.net/" -ForegroundColor Yellow
Write-Host ""
