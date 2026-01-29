# 微信退款日志增强 - 2026-01-28

## 📝 问题

用户测试微信退款时返回：
```json
{
  "success": false,
  "returnCode": "FAIL",
  "returnMsg": "错误的签名，验签失败"
}
```

## 🔍 分析

**"错误的签名，验签失败"** 通常有以下几种可能：

1. **API 密钥错误**: 使用的 `api_key` 与微信后台配置不一致
2. **签名参数遗漏**: 某些必需参数未包含在签名中
3. **签名算法错误**: MD5 签名格式或编码问题
4. **参数值错误**: 商户号、AppId 等参数与实际不符
5. **字符串拼接顺序**: 参数排序或拼接格式不正确

## ✅ 解决方案 - 增强日志

### 1. 增强签名生成日志

**修改位置**: `WechatRefundService.cs` - `GenerateSign` 方法

**增强内容**:
- ✅ 记录每个参与签名的参数及其值
- ✅ 记录完整的签名字符串
- ✅ 记录生成的签名值
- ✅ API 密钥脱敏显示（前4位+后4位）

```csharp
private string GenerateSign(SortedDictionary<string, string> parameters, string apiKey)
{
    var sb = new StringBuilder();
    _logger.LogInformation("🔐 开始生成签名，参数如下：");
    
    foreach (var kvp in parameters)
    {
        if (!string.IsNullOrEmpty(kvp.Value) && kvp.Key != "sign")
        {
            sb.Append($"{kvp.Key}={kvp.Value}&");
            _logger.LogInformation("   {Key}={Value}", kvp.Key, kvp.Value);
        }
    }

    sb.Append($"key={apiKey}");
    _logger.LogInformation("   key={Key} (已脱敏)", 
        apiKey.Length > 8 ? apiKey.Substring(0, 4) + "***" + apiKey.Substring(apiKey.Length - 4) : "***");

    var stringToSign = sb.ToString();
    _logger.LogWarning("🔐 完整签名字符串: {String}", stringToSign);

    using var md5 = MD5.Create();
    var hash = md5.ComputeHash(Encoding.UTF8.GetBytes(stringToSign));
    var sign = BitConverter.ToString(hash).Replace("-", "").ToUpper();

    _logger.LogWarning("🔐 生成的签名: {Sign}", sign);
    return sign;
}
```

### 2. 增强退款流程日志

**修改位置**: `WechatRefundService.cs` - `RefundAsync` 方法

**增强内容**:
- ✅ 记录参数构建完成和数量
- ✅ 记录完整的请求 XML (LogWarning 级别)
- ✅ 记录完整的响应 XML (LogWarning 级别)

```csharp
var parameters = BuildRefundParameters(request);
_logger.LogInformation("📋 退款参数构建完成，参数数量: {Count}", parameters.Count);

var sign = GenerateSign(parameters, request.ApiKey);
parameters["sign"] = sign;

var xmlRequest = BuildXmlRequest(parameters);
_logger.LogWarning("📤 微信退款请求XML: {Xml}", xmlRequest);

var xmlResponse = await SendRefundRequestAsync(xmlRequest, request.MchId);
_logger.LogWarning("📥 微信退款响应XML: {Xml}", xmlResponse);
```

### 3. 增强响应解析日志

**修改位置**: `WechatRefundService.cs` - `ParseRefundResponse` 方法

**增强内容**:
- ✅ 记录解析开始
- ✅ 详细记录所有关键字段值
- ✅ 成功/失败分支都有明确日志

```csharp
_logger.LogInformation("📄 开始解析微信响应XML...");

// 解析后
_logger.LogWarning("📋 解析基本字段: return_code={ReturnCode}, return_msg={ReturnMsg}, result_code={ResultCode}, err_code={ErrCode}, err_code_des={ErrCodeDes}",
    response.ReturnCode, response.ReturnMsg, response.ResultCode, response.ErrCode, response.ErrCodeDes);

if (response.Success)
{
    _logger.LogInformation("✅ 退款成功，解析详细字段...");
}
else
{
    _logger.LogError("❌ 退款失败: {ErrCode} - {ErrCodeDes}, return_msg={ReturnMsg}",
        response.ErrCode, response.ErrCodeDes, response.ReturnMsg);
}
```

## 📊 部署状态

### 更新内容
- ✅ 增强日志记录代码
- ✅ 重新编译发布 (`dotnet publish`)
- ✅ 上传到服务器 (`/opt/abc-payment/`)
- ✅ 重新构建 Docker 镜像
- ✅ 重启容器

### 部署时间
- **开始时间**: 2026-01-28 18:40
- **容器重启**: 2026-01-28 18:42
- **状态**: 运行中

### 容器信息
```
CONTAINER ID: 8052aaa007ff
IMAGE: abc-payment-gateway:latest
STATUS: Up Less than a second
PORTS: 8080/tcp
NETWORK: traefik-net
```

## 🧪 测试步骤

### 1. 等待服务启动 (约 45 秒)

```bash
# 等待 Traefik 健康检查完成
sleep 45

# 验证服务
curl https://payment.qsgl.net/Wechat/Health
```

### 2. 访问测试页面

```
https://payment.qsgl.net/wechat-refund-test.html
```

### 3. 发起退款测试

使用真实数据填写表单并提交

### 4. 查看详细日志

```bash
# SSH 登录服务器
ssh -i K:\Key\tx.qsgl.net_id_ed25519 root@tx.qsgl.net

# 查看实时日志 (包含新增的详细日志)
docker logs -f --tail 100 abc-payment-gateway

# 或查看最近的日志
docker logs --tail 200 abc-payment-gateway | grep -E '🔐|📋|📤|📥|❌|✅'
```

## 📋 日志示例

### 成功案例
```
info: 🔐 开始生成签名，参数如下：
info:    appid=wxc74a6aac13640229
info:    mch_id=1286651401
info:    nonce_str=a1b2c3d4e5f67890
info:    out_refund_no=RF20260128123456
info:    refund_fee=5000
info:    sub_mch_id=1641962649
info:    total_fee=5000
info:    transaction_id=4200002973202601249679270528
info:    key=YOUR***KEY (已脱敏)
warn: 🔐 完整签名字符串: appid=wxc74a6aac13640229&mch_id=1286651401&nonce_str=...&key=YOUR_API_KEY
warn: 🔐 生成的签名: A1B2C3D4E5F67890ABCDEF1234567890
warn: 📤 微信退款请求XML: <xml><appid>wxc74a6aac13640229</appid>...</xml>
warn: 📥 微信退款响应XML: <xml><return_code>SUCCESS</return_code>...</xml>
warn: 📋 解析基本字段: return_code=SUCCESS, return_msg=OK, result_code=SUCCESS
info: ✅ 退款成功，解析详细字段...
```

### 失败案例（签名错误）
```
info: 🔐 开始生成签名，参数如下：
info:    appid=wxc74a6aac13640229
info:    mch_id=1286651401
...
warn: 🔐 完整签名字符串: appid=...&key=WRONG_KEY
warn: 🔐 生成的签名: WRONGSIGNATURE1234567890ABCDEF
warn: 📤 微信退款请求XML: <xml>...</xml>
warn: 📥 微信退款响应XML: <xml><return_code>FAIL</return_code><return_msg>错误的签名，验签失败</return_msg></xml>
error: ❌ 退款失败: FAIL - , return_msg=错误的签名，验签失败
```

## 🔍 如何根据日志排查问题

### 1. 检查签名参数

从日志中查看参与签名的参数：
- 所有参数是否正确？
- 参数值是否与实际业务一致？
- 是否缺少必需参数？

### 2. 检查签名字符串

- 参数是否按字典序排序？
- 参数拼接格式是否正确 (`key=value&`)?
- API 密钥是否正确添加？

### 3. 检查 API 密钥

对比日志中的密钥（脱敏后）：
- 前4位和后4位是否与预期一致？
- 密钥长度是否正确（通常32位）？

### 4. 检查微信返回

从响应 XML 中查看：
- `return_code`: 通信标识
- `return_msg`: 返回信息
- `result_code`: 业务结果
- `err_code`: 错误代码
- `err_code_des`: 错误描述

## 🛠️ 常见问题解决

### 问题1: "错误的签名，验签失败"

**可能原因**:
1. API 密钥错误
2. 参数值错误（商户号、AppId等）
3. 缺少必需参数

**解决方法**:
1. 检查日志中的签名字符串
2. 对比微信商户平台的配置
3. 确认所有参数值正确

### 问题2: "商户号不存在"

**可能原因**:
- `mch_id` 或 `sub_mch_id` 错误

**解决方法**:
- 从日志中确认发送的商户号
- 登录微信商户平台核对

### 问题3: "订单不存在"

**可能原因**:
- `transaction_id` 或 `out_trade_no` 错误
- 订单号不属于该商户

**解决方法**:
- 使用真实存在的订单号
- 确认订单属于正确的商户

## 📝 下一步操作

1. ✅ 等待容器完全启动（45秒）
2. ✅ 访问测试页面进行退款测试
3. ✅ 实时查看日志输出
4. ✅ 根据日志内容分析问题
5. ✅ 调整参数后重新测试

## 📖 相关文档

- `WECHAT_TEST_PAGE.md` - 微信退款测试页面使用说明
- `WECHAT_CERT_FIX.md` - 微信证书配置修复记录
- `DEPLOYMENT_SUCCESS_20260128.md` - 项目部署记录

---

**更新时间**: 2026-01-28 18:42  
**状态**: ✅ 日志增强完成，容器已重启  
**下一步**: 进行退款测试并查看详细日志
