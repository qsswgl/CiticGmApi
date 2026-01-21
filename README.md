# CITIC Bank GM Cryptography API

中信银行国密加解密 API - 基于 .NET 10 的 Web API 服务

## 功能特性

✅ **SM2 非对称加密** - 国密 SM2 椭圆曲线公钥密码算法
- 密钥对生成
- 公钥加密
- 私钥解密

✅ **SM3WithSM2 数字签名** - SM3 哈希 + SM2 签名算法
- 数字签名生成
- 签名验证

✅ **SM4-CBC 对称加密** - 国密 SM4 分组密码算法
- CBC 模式加密
- CBC 模式解密

## 技术栈

- **.NET 10** - 最新 .NET 平台
- **ASP.NET Core Web API** - RESTful API 框架
- **BouncyCastle.Cryptography** - 国密算法实现
- **Swashbuckle** - Swagger/OpenAPI 文档生成
- **Docker** - 容器化部署
- **Traefik** - 反向代理与 HTTPS 证书管理

## API 端点

### 密钥生成
- `GET /api/Crypto/sm2/keypair` - 生成 SM2 密钥对
- `GET /api/Crypto/sm4/key` - 生成 SM4 密钥

### SM2 加密/解密
- `POST /api/Crypto/sm2/encrypt` - SM2 公钥加密
- `POST /api/Crypto/sm2/decrypt` - SM2 私钥解密

### SM3WithSM2 签名/验签
- `POST /api/Crypto/sm2/sign` - SM3WithSM2 数字签名
- `POST /api/Crypto/sm2/verify` - SM3WithSM2 签名验证

### SM4 加密/解密
- `POST /api/Crypto/sm4/encrypt` - SM4-CBC 加密
- `POST /api/Crypto/sm4/decrypt` - SM4-CBC 解密

### 健康检查
- `GET /api/Crypto/health` - API 健康状态

## 快速开始

### 本地开发

```bash
# 克隆项目
git clone https://github.com/YOUR_USERNAME/CiticGmApi.git
cd CiticGmApi

# 还原依赖
dotnet restore

# 运行项目
dotnet run

# 访问 Swagger 文档
# http://localhost:5000/swagger
```

### Docker 部署

```bash
# 发布项目（自包含）
dotnet publish -c Release -o ./publish --self-contained true -r linux-x64

# 复制配置文件到 publish 目录
cp Dockerfile.published publish/Dockerfile
cp docker-compose.yml publish/

# 构建并运行
cd publish
docker-compose up -d
```

### 生产部署

使用 Traefik 反向代理配置 HTTPS：

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.citic.rule=Host(`citic.qsgl.net`)"
  - "traefik.http.routers.citic.entrypoints=websecure"
  - "traefik.http.routers.citic.tls.certresolver=letsencrypt"
```

## 使用示例

### 生成 SM2 密钥对

```powershell
$keys = Invoke-RestMethod -Uri "https://citic.qsgl.net/api/Crypto/sm2/keypair"
$publicKey = $keys.data.publicKeyHex
$privateKey = $keys.data.privateKeyHex
```

### SM4 加密数据

```powershell
$body = @{
    plaintext = "Hello, CITIC Bank!"
    key = "0123456789abcdef0123456789abcdef"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "https://citic.qsgl.net/api/Crypto/sm4/encrypt" `
    -Method Post -Body $body -ContentType "application/json"

$ciphertext = $response.data.ciphertext
```

## 项目结构

```
CiticGmApi/
├── Controllers/         # API 控制器
│   ├── CryptoController.cs
│   └── TestController.cs
├── Services/           # 业务逻辑层
│   ├── GmCryptoService.cs
│   └── IGmCryptoService.cs
├── Models/            # 数据模型
│   └── CryptoModels.cs
├── Program.cs         # 应用入口
├── Dockerfile.published # Docker 构建文件
├── docker-compose.yml  # Docker Compose 配置
└── TestApiFixed.ps1    # API 测试脚本
```

## 测试

运行自动化测试脚本：

```powershell
.\TestApiFixed.ps1
```

测试覆盖：
- ✅ Health Check
- ✅ SM2 密钥对生成
- ✅ SM4 密钥生成
- ✅ 微信 APP 支付请求构建
- ✅ SM4-CBC 加密

## 部署环境

- **服务器**: Ubuntu 24.04
- **Docker**: 28.5.1
- **反向代理**: Traefik v3.2
- **域名**: citic.qsgl.net
- **证书**: Let's Encrypt 自动 HTTPS

## 安全说明

⚠️ **重要**: 
- 生产环境请使用安全的密钥管理方案
- 建议使用硬件安全模块 (HSM) 存储私钥
- API 仅用于测试和演示，生产使用需要额外的安全加固

## 许可证

MIT License

## 作者

开发用于中信银行微信支付集成测试

## 更新日志

### v1.0.0 (2026-01-21)
- ✅ 初始版本发布
- ✅ 实现 SM2/SM3/SM4 核心功能
- ✅ Swagger API 文档
- ✅ Docker 容器化部署
- ✅ HTTPS 生产环境配置
- ✅ 自动化测试脚本
