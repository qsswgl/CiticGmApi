using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Xml.Linq;
using AbcPaymentGateway.Models;
using Microsoft.Extensions.Options;

namespace AbcPaymentGateway.Services;

/// <summary>
/// 微信退款服务实现
/// </summary>
public class WechatRefundService : IWechatRefundService
{
    private readonly WechatConfig _config;
    private readonly ILogger<WechatRefundService> _logger;
    private readonly IHttpClientFactory _httpClientFactory;
    private X509Certificate2? _clientCertificate;

    public WechatRefundService(
        IOptions<WechatConfig> config,
        ILogger<WechatRefundService> logger,
        IHttpClientFactory httpClientFactory)
    {
        _config = config.Value;
        _logger = logger;
        _httpClientFactory = httpClientFactory;
        LoadCertificate();
    }

    /// <summary>
    /// 加载客户端证书
    /// </summary>
    private void LoadCertificate()
    {
        try
        {
            if (string.IsNullOrEmpty(_config.CertPath))
            {
                _logger.LogWarning("⚠️ 微信证书路径未配置");
                return;
            }

            if (!File.Exists(_config.CertPath))
            {
                _logger.LogError("❌ 微信证书文件不存在: {Path}", _config.CertPath);
                return;
            }

            // 加载P12证书，密码默认为商户号
            var password = string.IsNullOrEmpty(_config.CertPassword) 
                ? _config.MchId 
                : _config.CertPassword;

            _clientCertificate = new X509Certificate2(
                _config.CertPath,
                password,
                X509KeyStorageFlags.MachineKeySet | X509KeyStorageFlags.PersistKeySet | X509KeyStorageFlags.Exportable
            );

            _logger.LogInformation("✅ 微信客户端证书加载成功: {Subject}", _clientCertificate.Subject);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ 加载微信客户端证书失败");
            throw;
        }
    }

    /// <summary>
    /// 执行退款
    /// </summary>
    public async Task<WechatRefundResponse> RefundAsync(WechatRefundRequest request)
    {
        try
        {
            _logger.LogInformation("🔄 开始微信退款: TransactionId={TransactionId}, OutTradeNo={OutTradeNo}, RefundFee={RefundFee}",
                request.TransactionId, request.OutTradeNo, request.RefundFee);

            // 参数验证
            ValidateRefundRequest(request);

            // 生成退款单号
            if (string.IsNullOrEmpty(request.OutRefundNo))
            {
                request.OutRefundNo = $"RF{DateTime.Now:yyyyMMddHHmmss}{new Random().Next(1000, 9999)}";
            }

            // 构建请求参数
            var parameters = BuildRefundParameters(request);
            
            _logger.LogInformation("📋 退款参数构建完成，参数数量: {Count}", parameters.Count);

            // 生成签名
            var sign = GenerateSign(parameters, request.ApiKey);
            parameters["sign"] = sign;

            // 构建XML请求
            var xmlRequest = BuildXmlRequest(parameters);
            _logger.LogWarning("📤 微信退款请求XML: {Xml}", xmlRequest);

            // 发送请求
            var xmlResponse = await SendRefundRequestAsync(xmlRequest, request.MchId);
            _logger.LogWarning("📥 微信退款响应XML: {Xml}", xmlResponse);

            // 解析响应
            var response = ParseRefundResponse(xmlResponse);

            if (response.Success)
            {
                _logger.LogInformation("✅ 微信退款成功: RefundId={RefundId}, OutRefundNo={OutRefundNo}",
                    response.RefundId, response.OutRefundNo);
            }
            else
            {
                _logger.LogWarning("❌ 微信退款失败: {ErrCode} - {ErrCodeDes}",
                    response.ErrCode, response.ErrCodeDes);
            }

            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ 微信退款异常");
            return new WechatRefundResponse
            {
                Success = false,
                ReturnCode = "FAIL",
                ReturnMsg = "系统异常",
                Message = ex.Message
            };
        }
    }

    /// <summary>
    /// 查询退款
    /// </summary>
    public async Task<WechatRefundResponse> QueryRefundAsync(string outRefundNo, string mchId, string apiKey)
    {
        try
        {
            _logger.LogInformation("🔍 查询微信退款: OutRefundNo={OutRefundNo}", outRefundNo);

            var parameters = new SortedDictionary<string, string>
            {
                ["appid"] = _config.AppId,
                ["mch_id"] = mchId,
                ["nonce_str"] = GenerateNonceStr(),
                ["out_refund_no"] = outRefundNo
            };

            var sign = GenerateSign(parameters, apiKey);
            parameters["sign"] = sign;

            var xmlRequest = BuildXmlRequest(parameters);
            var xmlResponse = await SendQueryRequestAsync(xmlRequest);

            return ParseRefundResponse(xmlResponse);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ 查询微信退款异常");
            return new WechatRefundResponse
            {
                Success = false,
                ReturnCode = "FAIL",
                ReturnMsg = "查询异常",
                Message = ex.Message
            };
        }
    }

    /// <summary>
    /// 验证退款请求参数
    /// </summary>
    private void ValidateRefundRequest(WechatRefundRequest request)
    {
        if (string.IsNullOrEmpty(request.TransactionId) && string.IsNullOrEmpty(request.OutTradeNo))
        {
            throw new ArgumentException("微信订单号和商户订单号至少提供一个");
        }

        if (request.RefundFee <= 0)
        {
            throw new ArgumentException("退款金额必须大于0");
        }

        if (request.TotalFee <= 0)
        {
            throw new ArgumentException("订单总金额必须大于0");
        }

        if (request.RefundFee > request.TotalFee)
        {
            throw new ArgumentException("退款金额不能大于订单总金额");
        }

        if (string.IsNullOrEmpty(request.MchId))
        {
            throw new ArgumentException("商户号不能为空");
        }

        if (string.IsNullOrEmpty(request.ApiKey))
        {
            throw new ArgumentException("API密钥不能为空");
        }

        if (_clientCertificate == null)
        {
            throw new InvalidOperationException("客户端证书未加载");
        }
    }

    /// <summary>
    /// 构建退款参数
    /// </summary>
    private SortedDictionary<string, string> BuildRefundParameters(WechatRefundRequest request)
    {
        var parameters = new SortedDictionary<string, string>
        {
            ["appid"] = request.AppId,
            ["mch_id"] = request.MchId,
            ["nonce_str"] = GenerateNonceStr(),
            ["out_refund_no"] = request.OutRefundNo,
            ["total_fee"] = request.TotalFee.ToString(),
            ["refund_fee"] = request.RefundFee.ToString(),
            ["refund_desc"] = request.RefundDesc
        };

        // 子商户AppId（服务商模式必填）
        if (!string.IsNullOrEmpty(request.SubAppId))
        {
            parameters["sub_appid"] = request.SubAppId;
            _logger.LogInformation("🔑 添加 sub_appid 参数: {SubAppId}", request.SubAppId);
        }

        // 特约商户号（服务商模式）
        if (!string.IsNullOrEmpty(request.SubMchId))
        {
            parameters["sub_mch_id"] = request.SubMchId;
        }

        // 优先使用微信订单号
        if (!string.IsNullOrEmpty(request.TransactionId))
        {
            parameters["transaction_id"] = request.TransactionId;
        }
        else
        {
            parameters["out_trade_no"] = request.OutTradeNo;
        }

        // 退款通知URL（可选）
        if (!string.IsNullOrEmpty(request.NotifyUrl))
        {
            parameters["notify_url"] = request.NotifyUrl;
        }

        return parameters;
    }

    /// <summary>
    /// 生成随机字符串
    /// </summary>
    private string GenerateNonceStr()
    {
        return Guid.NewGuid().ToString("N");
    }

    /// <summary>
    /// 生成签名
    /// </summary>
    private string GenerateSign(SortedDictionary<string, string> parameters, string apiKey)
    {
        // 拼接参数
        var sb = new StringBuilder();
        _logger.LogWarning("🔐 ========== 开始生成签名 ==========");
        _logger.LogWarning("🔐 API密钥: {Key}", apiKey.Length > 8 ? apiKey.Substring(0, 4) + "***" + apiKey.Substring(apiKey.Length - 4) : "***");
        _logger.LogWarning("🔐 参数个数: {Count}", parameters.Count);
        _logger.LogWarning("🔐 参数明细（按字典序）：");
        
        int paramIndex = 1;
        foreach (var kvp in parameters)
        {
            if (!string.IsNullOrEmpty(kvp.Value) && kvp.Key != "sign")
            {
                sb.Append($"{kvp.Key}={kvp.Value}&");
                _logger.LogWarning("   [{Index}] {Key} = {Value}", paramIndex++, kvp.Key, kvp.Value);
            }
        }

        // 添加API密钥
        sb.Append($"key={apiKey}");
        _logger.LogWarning("   [{Index}] key = {Key} (完整密钥已添加)", paramIndex, apiKey.Length > 8 ? apiKey.Substring(0, 4) + "***" + apiKey.Substring(apiKey.Length - 4) : "***");

        var stringToSign = sb.ToString();
        _logger.LogWarning("🔐 待签名字符串长度: {Length} 字节", Encoding.UTF8.GetByteCount(stringToSign));
        _logger.LogWarning("🔐 完整签名字符串: {String}", stringToSign);

        // MD5签名并转大写
        using var md5 = MD5.Create();
        var hash = md5.ComputeHash(Encoding.UTF8.GetBytes(stringToSign));
        var sign = BitConverter.ToString(hash).Replace("-", "").ToUpper();

        _logger.LogWarning("🔐 MD5签名结果: {Sign}", sign);
        _logger.LogWarning("🔐 ========== 签名生成完成 ==========");
        return sign;
    }

    /// <summary>
    /// 构建XML请求
    /// </summary>
    private string BuildXmlRequest(SortedDictionary<string, string> parameters)
    {
        var root = new XElement("xml");
        foreach (var kvp in parameters)
        {
            root.Add(new XElement(kvp.Key, kvp.Value));
        }
        return root.ToString();
    }

    /// <summary>
    /// 发送退款请求
    /// </summary>
    private async Task<string> SendRefundRequestAsync(string xmlRequest, string mchId)
    {
        if (_clientCertificate == null)
        {
            throw new InvalidOperationException("客户端证书未加载");
        }

        // 创建带证书的HttpClientHandler
        var handler = new HttpClientHandler();
        handler.ClientCertificates.Add(_clientCertificate);
        
        // 在测试环境可能需要忽略SSL错误
        if (_config.Environment != "Production")
        {
            handler.ServerCertificateCustomValidationCallback = 
                (message, cert, chain, errors) => true;
        }

        using var httpClient = new HttpClient(handler);
        httpClient.Timeout = TimeSpan.FromSeconds(_config.Timeout);

        var url = $"{_config.ApiUrl}{_config.RefundUrl}";
        var content = new StringContent(xmlRequest, Encoding.UTF8, "application/xml");

        _logger.LogInformation("📡 发送退款请求到: {Url}", url);

        var response = await httpClient.PostAsync(url, content);
        response.EnsureSuccessStatusCode();

        var responseXml = await response.Content.ReadAsStringAsync();
        return responseXml;
    }

    /// <summary>
    /// 发送查询请求
    /// </summary>
    private async Task<string> SendQueryRequestAsync(string xmlRequest)
    {
        var httpClient = _httpClientFactory.CreateClient();
        httpClient.Timeout = TimeSpan.FromSeconds(_config.Timeout);

        var url = $"{_config.ApiUrl}{_config.RefundQueryUrl}";
        var content = new StringContent(xmlRequest, Encoding.UTF8, "application/xml");

        _logger.LogInformation("📡 发送退款查询请求到: {Url}", url);

        var response = await httpClient.PostAsync(url, content);
        response.EnsureSuccessStatusCode();

        return await response.Content.ReadAsStringAsync();
    }

    /// <summary>
    /// 解析退款响应
    /// </summary>
    private WechatRefundResponse ParseRefundResponse(string xmlResponse)
    {
        var response = new WechatRefundResponse
        {
            RawXml = xmlResponse
        };

        try
        {
            _logger.LogInformation("📄 开始解析微信响应XML...");
            
            var doc = XDocument.Parse(xmlResponse);
            var root = doc.Root;

            if (root == null)
            {
                _logger.LogError("❌ 响应XML根节点为空");
                response.ReturnCode = "FAIL";
                response.ReturnMsg = "响应XML解析失败";
                return response;
            }

            // 解析基本字段
            response.ReturnCode = GetXmlValue(root, "return_code");
            response.ReturnMsg = GetXmlValue(root, "return_msg");
            response.ResultCode = GetXmlValue(root, "result_code");
            response.ErrCode = GetXmlValue(root, "err_code");
            response.ErrCodeDes = GetXmlValue(root, "err_code_des");

            _logger.LogWarning("📋 解析基本字段: return_code={ReturnCode}, return_msg={ReturnMsg}, result_code={ResultCode}, err_code={ErrCode}, err_code_des={ErrCodeDes}",
                response.ReturnCode, response.ReturnMsg, response.ResultCode, response.ErrCode, response.ErrCodeDes);

            // 判断是否成功
            response.Success = response.ReturnCode == "SUCCESS" && response.ResultCode == "SUCCESS";

            if (response.Success)
            {
                _logger.LogInformation("✅ 退款成功，解析详细字段...");
                
                // 解析成功响应字段
                response.TransactionId = GetXmlValue(root, "transaction_id");
                response.OutTradeNo = GetXmlValue(root, "out_trade_no");
                response.OutRefundNo = GetXmlValue(root, "out_refund_no");
                response.RefundId = GetXmlValue(root, "refund_id");
                response.RefundChannel = GetXmlValue(root, "refund_channel");
                response.RefundRecvAccout = GetXmlValue(root, "refund_recv_accout");

                // 解析金额字段
                int.TryParse(GetXmlValue(root, "refund_fee"), out var refundFee);
                int.TryParse(GetXmlValue(root, "total_fee"), out var totalFee);
                int.TryParse(GetXmlValue(root, "cash_refund_fee"), out var cashRefundFee);

                response.RefundFee = refundFee;
                response.TotalFee = totalFee;
                response.CashRefundFee = cashRefundFee;

                response.Message = "退款成功";
            }
            else
            {
                _logger.LogError("❌ 退款失败: {ErrCode} - {ErrCodeDes}, return_msg={ReturnMsg}",
                    response.ErrCode, response.ErrCodeDes, response.ReturnMsg);
                
                response.Message = $"{response.ErrCode}: {response.ErrCodeDes}";
                if (string.IsNullOrEmpty(response.Message))
                {
                    response.Message = response.ReturnMsg;
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ 解析退款响应XML失败");
            response.Success = false;
            response.ReturnCode = "FAIL";
            response.ReturnMsg = "响应解析异常";
            response.Message = ex.Message;
        }

        return response;
    }

    /// <summary>
    /// 从XML中获取字段值
    /// </summary>
    private string GetXmlValue(XElement root, string elementName)
    {
        return root.Element(elementName)?.Value ?? string.Empty;
    }
}
