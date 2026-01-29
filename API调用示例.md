# 农行支付接口前端调用示例| 参数名 | 类型 | 必填 | 说明 |// 支付请求函数
async function createAbcPayment() {
    try {
        cfunction createAbcPayment() {
    $.ajax({
      async function createAbcPayment() {
    try {
        const response = await axios.post('https://payment.qsgl.net/api/payment/abc/pagepay', {
            merchantId: '103881636900016',
            amount: 0.01,
            orderNo: 'TEST' + Date.now(),
            orderDesc: '测试订单-PaymentType=A',
                      const response = await fetch('https://payment.qsgl.### 3️⃣ cURL 命令测试

```bash```powershell
$body = @{
    merchantId = '103881636900016'
## 📞 技术支持

- 服务器地址: https://payment.qsgl.net
- GitHub: https://github.com/qsswgl/AbcPaymentGateway
- 文档版本: 1.1
- 更新时间: 2026-01-22ount = 0.01
    orderNo = 'TEST' + [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    orderDesc = '测试订单-PaymentType=A'
    payTypeID = 'ImmediatePay'
    notifyUrl = 'https://payment.qsgl.net/api/payment/abc/notify'
} | ConvertTo-Json

Invoke-RestMethod -Uri 'https://payment.qsgl.net/api/payment/abc/pagepay' `
    -Method POST `
    -ContentType 'application/json' `
    -Body $body
```https://payment.qsgl.net/api/payment/abc/pagepay \
  -H "Content-Type: application/json" \
  -d '{
    "merchantId": "103881636900016",
    "amount": 0.01,
    "orderNo": "TEST'$(date +%s000)'",
    "orderDesc": "测试订单-PaymentType=A",
    "payTypeID": "ImmediatePay",
    "notifyUrl": "https://payment.qsgl.net/api/payment/abc/notify"
  }'
```nt/abc/pagepay', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        merchantId: '103881636900016',
                        amount: parseFloat(document.getElementById('amount').value),
                        orderNo: 'TEST' + Date.now(),
                        orderDesc: document.getElementById('orderDesc').value,
                        payTypeID: 'ImmediatePay',
                        notifyUrl: 'https://payment.qsgl.net/api/payment/abc/notify',
                        merchantSuccessUrl: 'https://payment.qsgl.net/payment/success',
                        merchantErrorUrl: 'https://payment.qsgl.net/payment/error'
                    })
                });ID: 'ImmediatePay',
            notifyUrl: 'https://payment.qsgl.net/api/payment/abc/notify',
            merchantSuccessUrl: 'https://payment.qsgl.net/payment/success',
            merchantErrorUrl: 'https://payment.qsgl.net/payment/error'
        });ps://payment.qsgl.net/api/payment/abc/pagepay',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({
            merchantId: '103881636900016',
            amount: 0.01,
            orderNo: 'TEST' + Date.now(),
            orderDesc: '测试订单-PaymentType=A',
            payTypeID: 'ImmediatePay',
            notifyUrl: 'https://payment.qsgl.net/api/payment/abc/notify',
            merchantSuccessUrl: 'https://payment.qsgl.net/payment/success',
            merchantErrorUrl: 'https://payment.qsgl.net/payment/error'
        }),= await fetch('https://payment.qsgl.net/api/payment/abc/pagepay', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                merchantId: '103881636900016',
                amount: 0.01,
                orderNo: 'TEST' + Date.now(),  // 生成唯一订单号
                orderDesc: '测试订单-PaymentType=A',
                payTypeID: 'ImmediatePay',     // 交易类型: ImmediatePay/DividedPay/PreAuthPay
                notifyUrl: 'https://payment.qsgl.net/api/payment/abc/notify',
                merchantSuccessUrl: 'https://payment.qsgl.net/payment/success',
                merchantErrorUrl: 'https://payment.qsgl.net/payment/error'
            })
        });-----|------|------|------|
| merchantId | string | ✅ | 商户号 | "103881636900016" |
| amount | decimal | ✅ | 支付金额(元) | 0.01 |
| orderNo | string | ✅ | 订单号(唯一) | "TEST1737523456789" |
| orderDesc | string | ✅ | 订单描述 | "测试订单-PaymentType=A" |
| payTypeID | string | ✅ | 交易类型 | "ImmediatePay" (普通支付)<br>"DividedPay" (分期支付)<br>"PreAuthPay" (预授权支付) |
| notifyUrl | string | ✅ | 异步通知地址 | "https://payment.qsgl.net/api/payment/abc/notify" |
| merchantSuccessUrl | string | ⭕ | 支付成功跳转 | "https://payment.qsgl.net/payment/success" |
| merchantErrorUrl | string | ⭕ | 支付失败跳转 | "https://payment.qsgl.net/payment/error" | 服务器信息

- **生产环境**: https://payment.qsgl.net
- **接口地址**: `/api/payment/abc/pagepay`
- **完整URL**: `https://payment.qsgl.net/api/payment/abc/pagepay`
- **请求方法**: POST
- **Content-Type**: application/json

---

## 📋 请求参数

| 参数名 | 类型 | 必填 | 说明 | 示例 |
|--------|------|------|------|------|
| merchantId | string | ✅ | 商户号 | "103881636900016" |
| amount | decimal | ✅ | 支付金额(元) | 0.01 |
| orderNo | string | ✅ | 订单号(唯一) | "TEST1737523456789" |
| orderDesc | string | ✅ | 订单描述 | "测试订单-PaymentType=1" |
| notifyUrl | string | ✅ | 异步通知地址 | "https://payment.qsgl.net/api/payment/abc/notify" |
| merchantSuccessUrl | string | ⭕ | 支付成功跳转 | "https://payment.qsgl.net/payment/success" |
| merchantErrorUrl | string | ⭕ | 支付失败跳转 | "https://payment.qsgl.net/payment/error" |

---

## 🚀 方法一: 原生 Fetch API (推荐)

```javascript
// 支付请求函数
async function createAbcPayment() {
    try {
        const response = await fetch('https://payment.qsgl.net/api/payment/abc/pagepay', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                merchantId: '103881636900016',
                amount: 0.01,
                orderNo: 'TEST' + Date.now(),  // 生成唯一订单号
                orderDesc: '测试订单-PaymentType=1',
                notifyUrl: 'https://payment.qsgl.net/api/payment/abc/notify',
                merchantSuccessUrl: 'https://payment.qsgl.net/payment/success',
                merchantErrorUrl: 'https://payment.qsgl.net/payment/error'
            })
        });

        const result = await response.json();
        
        console.log('响应数据:', result);

        if (result.isSuccess && result.paymentURL) {
            // 成功: 跳转到农行支付页面
            console.log('支付链接:', result.paymentURL);
            window.location.href = result.paymentURL;
        } else {
            // 失败: 显示错误信息
            console.error('支付失败:', result.message);
            alert('支付失败: ' + result.message);
        }

    } catch (error) {
        console.error('请求异常:', error);
        alert('网络请求失败,请检查网络连接');
    }
}

// HTML 按钮调用
// <button onclick="createAbcPayment()">立即支付</button>
```

---

## 💡 方法二: jQuery.ajax

```javascript
// 需要先引入 jQuery
// <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>

function createAbcPayment() {
    $.ajax({
        url: 'https://payment.qsgl.net/api/payment/abc/pagepay',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({
            merchantId: '103881636900016',
            amount: 0.01,
            orderNo: 'TEST' + Date.now(),
            orderDesc: '测试订单-PaymentType=A',
            payTypeID: 'ImmediatePay',
            notifyUrl: 'https://payment.qsgl.net/api/payment/abc/notify',
            merchantSuccessUrl: 'https://payment.qsgl.net/payment/success',
            merchantErrorUrl: 'https://payment.qsgl.net/payment/error'
        }),
        success: function(result) {
            if (result.isSuccess && result.paymentURL) {
                window.location.href = result.paymentURL;
            } else {
                alert('支付失败: ' + result.message);
            }
        },
        error: function(xhr, status, error) {
            console.error('请求失败:', error);
            alert('网络请求失败');
        }
    });
}
```

---

## 🔧 方法三: Axios

```javascript
// 需要先引入 Axios
// <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>

async function createAbcPayment() {
    try {
        const response = await axios.post('https://payment.qsgl.net/api/payment/abc/pagepay', {
            merchantId: '103881636900016',
            amount: 0.01,
            orderNo: 'TEST' + Date.now(),
            orderDesc: '测试订单-PaymentType=1',
            notifyUrl: 'https://tx.qsgl.net/api/payment/abc/notify',
            merchantSuccessUrl: 'https://payment.qsgl.net/payment/success',
            merchantErrorUrl: 'https://payment.qsgl.net/payment/error'
        });

        const result = response.data;
        
        if (result.isSuccess && result.paymentURL) {
            window.location.href = result.paymentURL;
        } else {
            alert('支付失败: ' + result.message);
        }

    } catch (error) {
        console.error('请求异常:', error);
        alert('网络请求失败');
    }
}
```

---

## 📦 方法四: 原生 XMLHttpRequest

```javascript
function createAbcPayment() {
    var xhr = new XMLHttpRequest();
    xhr.open('POST', 'https://payment.qsgl.net/api/payment/abc/pagepay', true);
    xhr.setRequestHeader('Content-Type', 'application/json');
    
    xhr.onreadystatechange = function() {
        if (xhr.readyState === 4) {
            if (xhr.status === 200) {
                var result = JSON.parse(xhr.responseText);
                if (result.isSuccess && result.paymentURL) {
                    window.location.href = result.paymentURL;
                } else {
                    alert('支付失败: ' + result.message);
                }
            } else {
                alert('请求失败: HTTP ' + xhr.status);
            }
        }
    };
    
    var data = JSON.stringify({
        merchantId: '103881636900016',
        amount: 0.01,
        orderNo: 'TEST' + Date.now(),
        orderDesc: '测试订单-PaymentType=1',
        notifyUrl: 'https://payment.qsgl.net/api/payment/abc/notify'
    });
    
    xhr.send(data);
}
```

---

## 📄 响应数据格式

### ✅ 成功响应示例

```json
{
    "isSuccess": true,
    "orderNo": "TEST1737523456789",
    "paymentURL": "https://pay.abchina.com/EbusPerbankFront/PaymentModeNewAct?TOKEN=17690800432119282637",
    "status": "SUCCESS",
    "message": "交易成功",
    "errorCode": "0000"
}
```

**处理方式:**
```javascript
if (result.isSuccess && result.paymentURL) {
    // 跳转到农行支付页面
    window.location.href = result.paymentURL;
}
```

### ❌ 失败响应示例

```json
{
    "isSuccess": false,
    "orderNo": "TEST1737523456789",
    "paymentURL": null,
    "status": "FAILED",
    "message": "金额格式错误",
    "errorCode": "9998"
}
```

**处理方式:**
```javascript
if (!result.isSuccess) {
    alert('支付失败: ' + result.message);
    console.error('错误码:', result.errorCode);
}
```

---

## 🔐 完整的前端支付流程

```javascript
// 1. 页面加载时初始化
document.addEventListener('DOMContentLoaded', function() {
    // 绑定支付按钮点击事件
    document.getElementById('payBtn').addEventListener('click', handlePayment);
});

// 2. 处理支付请求
async function handlePayment() {
    // 2.1 显示加载状态
    showLoading(true);
    
    // 2.2 获取表单数据
    const amount = parseFloat(document.getElementById('amount').value);
    const orderDesc = document.getElementById('orderDesc').value;
    
    // 2.3 数据验证
    if (!amount || amount < 0.01) {
        alert('请输入正确的金额(最小0.01元)');
        showLoading(false);
        return;
    }
    
    // 2.4 生成唯一订单号
    const orderNo = 'TEST' + Date.now();
    
    try {
        // 2.5 发送支付请求
        const response = await fetch('https://payment.qsgl.net/api/payment/abc/pagepay', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                merchantId: '103881636900016',
                amount: amount,
                orderNo: orderNo,
                orderDesc: orderDesc,
                notifyUrl: 'https://payment.qsgl.net/api/payment/abc/notify',
                merchantSuccessUrl: 'https://payment.qsgl.net/payment/success',
                merchantErrorUrl: 'https://payment.qsgl.net/payment/error'
            })
        });
        
        // 2.6 解析响应
        const result = await response.json();
        
        // 2.7 处理结果
        if (result.isSuccess && result.paymentURL) {
            // 成功: 保存订单号到本地存储
            localStorage.setItem('currentOrderNo', orderNo);
            
            // 跳转到农行支付页面
            console.log('订单号:', orderNo);
            console.log('支付链接:', result.paymentURL);
            window.location.href = result.paymentURL;
        } else {
            // 失败: 显示错误信息
            showLoading(false);
            alert('支付请求失败\n错误码: ' + result.errorCode + '\n错误信息: ' + result.message);
        }
        
    } catch (error) {
        // 2.8 异常处理
        showLoading(false);
        console.error('支付请求异常:', error);
        alert('网络请求失败,请检查网络连接后重试');
    }
}

// 3. 显示/隐藏加载状态
function showLoading(show) {
    const loadingEl = document.getElementById('loading');
    const payBtn = document.getElementById('payBtn');
    
    if (show) {
        loadingEl.style.display = 'block';
        payBtn.disabled = true;
        payBtn.textContent = '处理中...';
    } else {
        loadingEl.style.display = 'none';
        payBtn.disabled = false;
        payBtn.textContent = '立即支付';
    }
}

// 4. 支付完成后返回页面处理
// 在 success.html 或 error.html 中
window.addEventListener('load', function() {
    const orderNo = localStorage.getItem('currentOrderNo');
    if (orderNo) {
        console.log('支付完成的订单号:', orderNo);
        
        // 可以调用查询接口查询支付结果
        // queryPaymentResult(orderNo);
        
        // 清除本地存储
        localStorage.removeItem('currentOrderNo');
    }
});
```

---

## 🎯 完整的 HTML 示例

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>农行支付</title>
    <style>
        .pay-form {
            max-width: 400px;
            margin: 50px auto;
            padding: 20px;
            border: 1px solid #ddd;
            border-radius: 8px;
        }
        .form-group {
            margin-bottom: 15px;
        }
        .form-group label {
            display: block;
            margin-bottom: 5px;
        }
        .form-group input {
            width: 100%;
            padding: 8px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        .pay-btn {
            width: 100%;
            padding: 12px;
            background: #1890ff;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
        }
        .pay-btn:disabled {
            background: #ccc;
            cursor: not-allowed;
        }
        .loading {
            display: none;
            text-align: center;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="pay-form">
        <h2>农行支付</h2>
        
        <div class="form-group">
            <label>支付金额(元)</label>
            <input type="number" id="amount" value="0.01" step="0.01" min="0.01">
        </div>
        
        <div class="form-group">
            <label>订单描述</label>
            <input type="text" id="orderDesc" value="测试订单-PaymentType=1">
        </div>
        
        <button id="payBtn" class="pay-btn">立即支付</button>
        
        <div id="loading" class="loading">
            <p>正在处理支付请求...</p>
        </div>
    </div>

    <script>
        document.getElementById('payBtn').addEventListener('click', async function() {
            const loadingEl = document.getElementById('loading');
            const payBtn = document.getElementById('payBtn');
            
            // 显示加载状态
            loadingEl.style.display = 'block';
            payBtn.disabled = true;
            payBtn.textContent = '处理中...';
            
            try {
                const response = await fetch('https://payment.qsgl.net/api/payment/abc/pagepay', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        merchantId: '103881636900016',
                        amount: parseFloat(document.getElementById('amount').value),
                        orderNo: 'TEST' + Date.now(),
                        orderDesc: document.getElementById('orderDesc').value,
                        payTypeID: 'ImmediatePay',
                        notifyUrl: 'https://payment.qsgl.net/api/payment/abc/notify',
                        merchantSuccessUrl: 'https://payment.qsgl.net/payment/success',
                        merchantErrorUrl: 'https://payment.qsgl.net/payment/error'
                    })
                });
                
                const result = await response.json();
                
                if (result.isSuccess && result.paymentURL) {
                    window.location.href = result.paymentURL;
                } else {
                    alert('支付失败: ' + result.message);
                    loadingEl.style.display = 'none';
                    payBtn.disabled = false;
                    payBtn.textContent = '立即支付';
                }
            } catch (error) {
                alert('网络请求失败');
                loadingEl.style.display = 'none';
                payBtn.disabled = false;
                payBtn.textContent = '立即支付';
            }
        });
    </script>
</body>
</html>
```

---

## 📱 测试方法

### 1️⃣ 在线测试 (推荐)

访问已部署的演示页面:
```
https://payment.qsgl.net/abc-payment-demo.html
```

### 2️⃣ 本地测试

1. 保存上面的 HTML 代码为 `test.html`
2. 用浏览器打开文件
3. 点击"立即支付"按钮
4. 观察浏览器控制台日志

### 3️⃣ cURL 命令测试

```bash
curl -X POST https://payment.qsgl.net/api/payment/abc/pagepay \
  -H "Content-Type: application/json" \
  -d '{
    "merchantId": "103881636900016",
    "amount": 0.01,
    "orderNo": "TEST'$(date +%s000)'",
    "orderDesc": "测试订单-PaymentType=1",
    "notifyUrl": "https://payment.qsgl.net/api/payment/abc/notify"
  }'
```

### 4️⃣ PowerShell 测试

```powershell
$body = @{
    merchantId = '103881636900016'
    amount = 0.01
    orderNo = 'TEST' + [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    orderDesc = '测试订单-PaymentType=1'
    notifyUrl = 'https://payment.qsgl.net/api/payment/abc/notify'
} | ConvertTo-Json

Invoke-RestMethod -Uri 'https://payment.qsgl.net/api/payment/abc/pagepay' `
    -Method POST `
    -ContentType 'application/json' `
    -Body $body
```

---

## ⚠️ 注意事项

1. **订单号唯一性**: 每次请求必须使用不同的 `orderNo`
2. **金额格式**: 单位为元,最小 0.01 元,保留两位小数
3. **HTTPS**: 生产环境必须使用 HTTPS 协议
4. **跨域**: 如果前端和API不在同一域名,需要配置 CORS
5. **回调地址**: `notifyUrl` 必须是公网可访问的 HTTPS 地址
6. **超时时间**: 建议设置 30 秒以上的请求超时

---

## 🐛 常见问题

### Q1: 为什么会跨域?
**A**: 如果前端页面域名和 API 域名不一致,浏览器会阻止请求。需要在服务器配置 CORS。

### Q2: 订单号重复怎么办?
**A**: 使用时间戳生成订单号: `'TEST' + Date.now()` 或 `'ORDER' + new Date().getTime()`

### Q3: 如何测试支付是否成功?
**A**: 查看响应的 `errorCode`:
- `0000`: 成功
- `9998`: 失败 (查看 `message` 了解原因)

### Q4: 支付页面没有跳转?
**A**: 检查:
1. `result.isSuccess` 是否为 `true`
2. `result.paymentURL` 是否有值
3. 浏览器控制台是否有错误

---

## 📞 技术支持

- 服务器地址: https://payment.qsgl.net
- GitHub: https://github.com/qsswgl/AbcPaymentGateway
- 文档版本: 1.0
- 更新时间: 2026-01-22
