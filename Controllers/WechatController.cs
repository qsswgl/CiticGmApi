using Microsoft.AspNetCore.Mvc;
using AbcPaymentGateway.Models;
using AbcPaymentGateway.Services;
using System.Text.Json;
using Microsoft.Extensions.Configuration;

namespace AbcPaymentGateway.Controllers;

/// <summary>
/// 微信服务商退款控制器
/// </summary>
[ApiController]
[Route("[controller]")]
public class WechatController : ControllerBase
{
    private readonly IWechatRefundService _refundService;
    private readonly ILogger<WechatController> _logger;
    private readonly IConfiguration _configuration;

    public WechatController(
        IWechatRefundService refundService,
        ILogger<WechatController> logger,
        IConfiguration configuration)
    {
        _refundService = refundService;
        _logger = logger;
        _configuration = configuration;
    }

    /// <summary>
    /// 微信服务商退款接口（GET方式）
    /// </summary>
    /// <remarks>
    /// 🔄 微信服务商模式退款API - 支持全额或部分退款
    /// 
    /// **接口说明**：
    /// - 支持服务商代特约商户发起退款
    /// - 使用服务商商户号+特约商户号模式
    /// - 需要配置微信商户证书进行双向认证
    /// 
    /// **示例URL**:
    /// ```
    /// GET https://payment.qsgl.net/Wechat/Refund?DBName=qsoft782&amp;total_fee=5000&amp;refund_fee=5000&amp;mch_id=1286651401&amp;appid=wxc74a6aac13640229&amp;api_key=YOUR_API_KEY&amp;sub_mch_id=1641962649&amp;transaction_id=4200002973202601249679270528
    /// ```
    /// 
    /// **参数说明**:
    /// - **DBName**: 数据库名称（业务标识）
    /// - **total_fee**: 订单总金额，单位：分（例如100.00元 = 10000分）
    /// - **refund_fee**: 退款金额，单位：分（必须 ≤ total_fee）
    /// - **mch_id**: 服务商商户号（微信分配）
    /// - **appid**: 服务商AppId（微信分配）
    /// - **api_key**: API密钥（用于签名）
    /// - **sub_mch_id**: 特约商户号（子商户号）
    /// - **transaction_id**: 微信订单号（优先使用，与out_trade_no二选一）
    /// - **out_trade_no**: 商户订单号（transaction_id为空时必填）
    /// - **refund_desc**: 退款原因（可选，默认"客户申请退款"）
    /// - **notify_url**: 退款结果通知URL（可选）
    /// 
    /// **返回示例**:
    /// ```json
    /// {
    ///   "success": true,
    ///   "return_code": "SUCCESS",
    ///   "result_code": "SUCCESS",
    ///   "transaction_id": "4200002973202601249679270528",
    ///   "out_refund_no": "RF20260126143025",
    ///   "refund_id": "50302503132026012697533395801",
    ///   "refund_fee": 5000,
    ///   "total_fee": 5000
    /// }
    /// ```
    /// 
    /// **注意事项**:
    /// 1. 退款金额不能大于订单金额
    /// 2. 同一笔订单可以多次退款，累计退款金额不能超过订单总金额
    /// 3. 需要在微信商户平台配置退款证书
    /// 4. 退款有一定时效限制（通常为1年）
    /// </remarks>
    /// <param name="DBName">数据库名称</param>
    /// <param name="total_fee">订单总金额（分）</param>
    /// <param name="refund_fee">退款金额（分）</param>
    /// <param name="mch_id">服务商商户号</param>
    /// <param name="appid">服务商AppId</param>
    /// <param name="api_key">API密钥（可选，未提供时从配置读取）</param>
    /// <param name="sub_mch_id">特约商户号</param>
    /// <param name="transaction_id">微信订单号（优先）</param>
    /// <param name="out_trade_no">商户订单号</param>
    /// <param name="refund_desc">退款原因</param>
    /// <param name="notify_url">退款通知URL</param>
    /// <response code="200">退款成功</response>
    /// <response code="400">退款失败</response>
    [HttpGet("Refund")]
    [ProducesResponseType(typeof(WechatRefundResponse), 200)]
    [ProducesResponseType(400)]
    public async Task<IActionResult> Refund(
        [FromQuery] string DBName,
        [FromQuery] int total_fee,
        [FromQuery] int refund_fee,
        [FromQuery] string? mch_id = null,
        [FromQuery] string? appid = null,
        [FromQuery] string? api_key = null,
        [FromQuery] string? sub_mch_id = null,
        [FromQuery] string? transaction_id = null,
        [FromQuery] string? out_trade_no = null,
        [FromQuery] string? refund_desc = null,
        [FromQuery] string? notify_url = null)
    {
        try
        {
            _logger.LogInformation("🎯 收到微信退款请求: DBName={DBName}, TransactionId={TransactionId}, RefundFee={RefundFee}",
                DBName, transaction_id, refund_fee);

            // 从配置读取默认值
            var configMchId = _configuration["Wechat:MchId"] ?? "";
            var configAppId = _configuration["Wechat:AppId"] ?? "";
            var configSubAppId = _configuration["Wechat:SubAppId"] ?? "";
            var configApiKey = _configuration["Wechat:ApiKey"] ?? "";

            // 优先使用参数，否则使用配置
            var finalMchId = !string.IsNullOrEmpty(mch_id) ? mch_id : configMchId;
            var finalAppId = !string.IsNullOrEmpty(appid) ? appid : configAppId;
            var finalApiKey = !string.IsNullOrEmpty(api_key) ? api_key : configApiKey;

            if (string.IsNullOrEmpty(finalApiKey))
            {
                _logger.LogError("❌ API Key未配置，请在appsettings.json中配置或通过参数传递");
                return BadRequest(new { success = false, error = "API Key未配置" });
            }

            _logger.LogInformation("🔑 使用配置: MchId={MchId}, AppId={AppId}, SubAppId={SubAppId}, SubMchId={SubMchId}, ApiKey已配置={HasApiKey}",
                finalMchId, finalAppId, configSubAppId, sub_mch_id, !string.IsNullOrEmpty(finalApiKey));

            // 构建退款请求
            var request = new WechatRefundRequest
            {
                DBName = DBName,
                MchId = finalMchId,
                AppId = finalAppId,
                SubAppId = configSubAppId,
                ApiKey = finalApiKey,
                SubMchId = sub_mch_id ?? "",
                TransactionId = transaction_id ?? string.Empty,
                OutTradeNo = out_trade_no ?? string.Empty,
                TotalFee = total_fee,
                RefundFee = refund_fee,
                RefundDesc = refund_desc ?? "客户申请退款",
                NotifyUrl = notify_url ?? string.Empty
            };

            // 执行退款
            var response = await _refundService.RefundAsync(request);

            // 记录响应
            _logger.LogInformation("📊 微信退款响应: Success={Success}, RefundId={RefundId}, Message={Message}",
                response.Success, response.RefundId, response.Message);

            // 返回JSON响应
            return Ok(new
            {
                success = response.Success,
                return_code = response.ReturnCode,
                return_msg = response.ReturnMsg,
                result_code = response.ResultCode,
                err_code = response.ErrCode,
                err_code_des = response.ErrCodeDes,
                transaction_id = response.TransactionId,
                out_trade_no = response.OutTradeNo,
                out_refund_no = response.OutRefundNo,
                refund_id = response.RefundId,
                refund_fee = response.RefundFee,
                total_fee = response.TotalFee,
                cash_refund_fee = response.CashRefundFee,
                refund_channel = response.RefundChannel,
                refund_recv_accout = response.RefundRecvAccout,
                message = response.Message,
                raw_xml = response.RawXml
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ 微信退款接口异常");
            return BadRequest(new
            {
                success = false,
                error = ex.Message,
                stack_trace = ex.StackTrace
            });
        }
    }

    /// <summary>
    /// 查询微信退款状态
    /// </summary>
    /// <remarks>
    /// 🔍 查询退款单的处理状态
    /// 
    /// **接口说明**：
    /// - 通过商户退款单号查询退款状态
    /// - 用于确认退款是否成功
    /// - 可查询退款进度和退款金额
    /// 
    /// **示例URL**:
    /// ```
    /// GET https://payment.qsgl.net/Wechat/QueryRefund?out_refund_no=RF20260124123456&amp;mch_id=1286651401&amp;api_key=YOUR_API_KEY
    /// ```
    /// 
    /// **参数说明**:
    /// - **out_refund_no**: 商户退款单号（退款时返回的单号）
    /// - **mch_id**: 服务商商户号
    /// - **api_key**: API密钥
    /// 
    /// **返回示例**:
    /// ```json
    /// {
    ///   "success": true,
    ///   "return_code": "SUCCESS",
    ///   "result_code": "SUCCESS",
    ///   "refund_id": "50302503132026012697533395801",
    ///   "out_refund_no": "RF20260126143025",
    ///   "refund_fee": 5000,
    ///   "message": "退款成功"
    /// }
    /// ```
    /// </remarks>
    /// <param name="out_refund_no">商户退款单号</param>
    /// <param name="mch_id">服务商商户号</param>
    /// <param name="api_key">API密钥</param>
    /// <response code="200">查询成功</response>
    /// <response code="400">查询失败</response>
    [HttpGet("QueryRefund")]
    [ProducesResponseType(typeof(WechatRefundResponse), 200)]
    [ProducesResponseType(400)]
    public async Task<IActionResult> QueryRefund(
        [FromQuery] string out_refund_no,
        [FromQuery] string? mch_id = null,
        [FromQuery] string? api_key = null)
    {
        try
        {
            _logger.LogInformation("🔍 收到微信退款查询请求: OutRefundNo={OutRefundNo}", out_refund_no);

            // 从配置读取默认值
            var configMchId = _configuration["Wechat:MchId"] ?? "";
            var configApiKey = _configuration["Wechat:ApiKey"] ?? "";

            // 优先使用参数，否则使用配置
            var finalMchId = !string.IsNullOrEmpty(mch_id) ? mch_id : configMchId;
            var finalApiKey = !string.IsNullOrEmpty(api_key) ? api_key : configApiKey;

            if (string.IsNullOrEmpty(finalApiKey))
            {
                _logger.LogError("❌ API Key未配置");
                return BadRequest(new { success = false, error = "API Key未配置" });
            }

            var response = await _refundService.QueryRefundAsync(out_refund_no, finalMchId, finalApiKey);

            return Ok(new
            {
                success = response.Success,
                return_code = response.ReturnCode,
                return_msg = response.ReturnMsg,
                result_code = response.ResultCode,
                refund_id = response.RefundId,
                out_refund_no = response.OutRefundNo,
                refund_fee = response.RefundFee,
                message = response.Message
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ 微信退款查询异常");
            return BadRequest(new
            {
                success = false,
                error = ex.Message
            });
        }
    }

    /// <summary>
    /// 微信服务商退款接口（POST方式）
    /// </summary>
    /// <remarks>
    /// 🔄 使用JSON格式提交退款请求
    /// 
    /// **接口说明**：
    /// - 支持POST方式提交，参数通过请求体传递
    /// - 适合参数较多或安全性要求较高的场景
    /// - 所有功能与GET方式相同
    /// 
    /// **请求示例**:
    /// ```json
    /// POST https://payment.qsgl.net/Wechat/Refund
    /// Content-Type: application/json
    /// 
    /// {
    ///   "dbName": "qsoft782",
    ///   "mchId": "1286651401",
    ///   "appId": "wxc74a6aac13640229",
    ///   "apiKey": "YOUR_API_KEY",
    ///   "subMchId": "1641962649",
    ///   "transactionId": "4200002973202601249679270528",
    ///   "totalFee": 5000,
    ///   "refundFee": 5000,
    ///   "refundDesc": "客户申请退款"
    /// }
    /// ```
    /// 
    /// **响应示例**:
    /// ```json
    /// {
    ///   "success": true,
    ///   "returnCode": "SUCCESS",
    ///   "resultCode": "SUCCESS",
    ///   "transactionId": "4200002973202601249679270528",
    ///   "outRefundNo": "RF20260126143025",
    ///   "refundId": "50302503132026012697533395801",
    ///   "refundFee": 5000,
    ///   "totalFee": 5000,
    ///   "message": "退款成功"
    /// }
    /// ```
    /// 
    /// **优势**:
    /// - 参数不会在URL中暴露
    /// - 支持更复杂的数据结构
    /// - 更符合RESTful API规范
    /// </remarks>
    /// <param name="request">退款请求对象</param>
    /// <response code="200">退款成功</response>
    /// <response code="400">退款失败</response>
    [HttpPost("Refund")]
    [ProducesResponseType(typeof(WechatRefundResponse), 200)]
    [ProducesResponseType(typeof(WechatRefundResponse), 400)]
    public async Task<IActionResult> RefundPost([FromBody] WechatRefundRequest request)
    {
        try
        {
            _logger.LogInformation("🎯 收到微信退款POST请求: {@Request}", 
                JsonSerializer.Serialize(request, new JsonSerializerOptions { WriteIndented = true }));

            // 从配置读取默认值
            var configMchId = _configuration["Wechat:MchId"] ?? "";
            var configAppId = _configuration["Wechat:AppId"] ?? "";
            var configSubAppId = _configuration["Wechat:SubAppId"] ?? "";
            var configApiKey = _configuration["Wechat:ApiKey"] ?? "";

            // 优先使用请求中的参数，否则使用配置
            if (string.IsNullOrEmpty(request.MchId))
                request.MchId = configMchId;
            if (string.IsNullOrEmpty(request.AppId))
                request.AppId = configAppId;
            if (string.IsNullOrEmpty(request.SubAppId))
                request.SubAppId = configSubAppId;
            if (string.IsNullOrEmpty(request.ApiKey))
                request.ApiKey = configApiKey;

            if (string.IsNullOrEmpty(request.ApiKey))
            {
                _logger.LogError("❌ API Key未配置，请在appsettings.json中配置或通过请求体传递");
                return BadRequest(new WechatRefundResponse 
                { 
                    Success = false, 
                    ReturnCode = "FAIL",
                    ReturnMsg = "API Key未配置" 
                });
            }

            _logger.LogInformation("🔑 使用配置: MchId={MchId}, AppId={AppId}, SubAppId={SubAppId}, SubMchId={SubMchId}, ApiKey已配置={HasApiKey}",
                request.MchId, request.AppId, request.SubAppId, request.SubMchId, !string.IsNullOrEmpty(request.ApiKey));

            var response = await _refundService.RefundAsync(request);

            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ 微信退款POST接口异常");
            return BadRequest(new WechatRefundResponse
            {
                Success = false,
                ReturnCode = "FAIL",
                ReturnMsg = "系统异常",
                Message = ex.Message
            });
        }
    }

    /// <summary>
    /// 健康检查
    /// </summary>
    [HttpGet("Health")]
    public IActionResult Health()
    {
        return Ok(new
        {
            service = "微信服务商退款API",
            status = "运行中",
            timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"),
            version = "1.0.0"
        });
    }
}
