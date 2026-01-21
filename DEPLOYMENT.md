# CITIC Bank GM API - 部署总结

## 📦 容器镜像备份

### 服务器备份信息
- **备份时间**: 2026-01-21 11:08:09
- **容器名称**: citic-gm-api
- **镜像标签**: citic-gm-api:backup-20260121-110809
- **镜像大小**: 241MB
- **导出文件**: /tmp/citic-gm-api-backup-20260121-110809.tar.gz (95MB)
- **服务器**: root@tx.qsgl.net

### 备份恢复命令
```bash
# 从备份文件恢复镜像
ssh root@tx.qsgl.net "gunzip -c /tmp/citic-gm-api-backup-20260121-110809.tar.gz | docker load"

# 或使用镜像直接运行
ssh root@tx.qsgl.net "docker run -d --name citic-gm-api-restored citic-gm-api:backup-20260121-110809"
```

---

## 🚀 GitHub 仓库

### 仓库信息
- **仓库名称**: CiticGmApi
- **仓库地址**: https://github.com/qsswgl/CiticGmApi
- **描述**: 中信银行国密加解密 API - SM2/SM3/SM4 Cryptography Web API Service
- **语言**: C#
- **可见性**: Public
- **创建时间**: 2026-01-21T03:09:48Z

### Git 配置
- **主分支**: main
- **SSH密钥**: K:\key\github\id_rsa
- **访问方式**: SSH over HTTPS
- **初始提交**: f1c638a
- **版本标签**: v1.0.0

### 克隆命令
```bash
# SSH 方式
git clone git@github.com:qsswgl/CiticGmApi.git

# HTTPS 方式
git clone https://github.com/qsswgl/CiticGmApi.git
```

### 推送配置
```bash
# 配置 SSH 密钥推送
$env:GIT_SSH_COMMAND = "ssh -i K:/key/github/id_rsa -o StrictHostKeyChecking=no"
git push origin main
```

---

## 📁 项目文件清单

已提交到GitHub的文件（19个文件，2498行代码）：

### 核心代码
- ✅ `Controllers/CryptoController.cs` - API 控制器（8个端点）
- ✅ `Controllers/TestController.cs` - 测试控制器
- ✅ `Services/GmCryptoService.cs` - 国密加解密服务实现
- ✅ `Services/IGmCryptoService.cs` - 服务接口定义
- ✅ `Models/CryptoModels.cs` - 数据模型（请求/响应/结果）
- ✅ `Program.cs` - 应用入口与配置

### 配置文件
- ✅ `CiticGmApi.csproj` - 项目配置（.NET 10）
- ✅ `appsettings.json` - 应用配置
- ✅ `Dockerfile` - Docker 构建文件
- ✅ `Dockerfile.published` - 发布版 Dockerfile
- ✅ `docker-compose.yml` - Docker Compose 配置
- ✅ `.dockerignore` - Docker 忽略文件
- ✅ `.gitignore` - Git 忽略文件

### 部署脚本
- ✅ `Deploy.ps1` - Windows 部署脚本
- ✅ `QuickDeploy.ps1` - 快速部署脚本
- ✅ `deploy.sh` - Linux 部署脚本

### 测试脚本
- ✅ `TestApi.ps1` - API 测试脚本（原版）
- ✅ `TestApiFixed.ps1` - API 测试脚本（修复版）

### 文档
- ✅ `README.md` - 项目说明文档

---

## 🔧 技术栈

### 开发环境
- .NET SDK: 10.0.101
- ASP.NET Core Web API
- C# 13
- BouncyCastle.Cryptography 2.5.0
- Swashbuckle.AspNetCore 7.2.0

### 部署环境
- 服务器: Ubuntu 24.04
- Docker: 28.5.1
- Docker Compose: v2.40.0
- Traefik: v3.2 (反向代理)
- 域名: citic.qsgl.net
- HTTPS: Let's Encrypt 自动证书

### 国密算法
- SM2: 椭圆曲线公钥密码（加密/解密/签名/验签）
- SM3: 密码杂凑算法（用于 SM3WithSM2 签名）
- SM4: 分组密码算法（CBC 模式加解密）

---

## ✅ 部署验证

### API 端点测试结果
- ✅ Health Check - `/api/Crypto/health`
- ✅ SM2 KeyPair Generation - `/api/Crypto/sm2/keypair`
- ✅ SM4 Key Generation - `/api/Crypto/sm4/key`
- ✅ SM4 Encryption - `/api/Crypto/sm4/encrypt`
- ✅ SM4 Decryption - `/api/Crypto/sm4/decrypt`
- ✅ SM2 Encryption - `/api/Crypto/sm2/encrypt`
- ✅ SM2 Decryption - `/api/Crypto/sm2/decrypt`
- ✅ SM3WithSM2 Sign - `/api/Crypto/sm2/sign`
- ✅ SM3WithSM2 Verify - `/api/Crypto/sm2/verify`

### 生产环境
- **URL**: https://citic.qsgl.net
- **Swagger**: https://citic.qsgl.net/swagger
- **状态**: 运行中 ✅ Healthy
- **容器**: citic-gm-api (fd3200d74675)
- **镜像**: citic-gm-api-citic-gm-api:latest

### 测试参数（中信银行微信支付）
- 测试商户号: 731691000000096
- 终端号: C8000023
- 微信AppID: wx3f64e658810cca0f
- 终端类型: 11
- APP版本: 1.000000
- 交易码: QrLaasApiService:weixinApppay

---

## 📊 项目统计

- **总代码行数**: 2,498 行
- **文件数量**: 19 个
- **控制器**: 2 个（Crypto + Test）
- **API 端点**: 9 个
- **测试用例**: 6 个核心功能测试
- **Docker 镜像大小**: 241MB
- **压缩备份大小**: 95MB

---

## 🔐 安全说明

⚠️ **生产环境安全检查清单**:
- [ ] 更换默认的测试密钥
- [ ] 启用 API 认证（JWT/OAuth2）
- [ ] 配置速率限制（Rate Limiting）
- [ ] 启用请求日志审计
- [ ] 私钥使用 HSM 或密钥管理服务
- [ ] 定期更新依赖包（安全补丁）
- [ ] 配置 CORS 策略
- [ ] 启用请求体大小限制

---

## 📝 版本历史

### v1.0.0 (2026-01-21)
- ✅ 初始版本发布
- ✅ SM2/SM3/SM4 核心功能实现
- ✅ Swagger API 文档
- ✅ Docker 容器化部署
- ✅ Traefik HTTPS 配置
- ✅ 自动化测试脚本
- ✅ 生产环境部署验证
- ✅ GitHub 仓库创建
- ✅ 容器镜像备份

---

## 📞 联系方式

- GitHub: https://github.com/qsswgl/CiticGmApi
- API 文档: https://citic.qsgl.net/swagger
- 问题反馈: https://github.com/qsswgl/CiticGmApi/issues

---

**部署完成时间**: 2026-01-21 11:10:00  
**部署状态**: ✅ 成功  
**备份状态**: ✅ 完成  
**GitHub推送**: ✅ 完成  
