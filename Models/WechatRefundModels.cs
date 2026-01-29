namespace AbcPaymentGateway.Models;

/// <summary>
/// 微信退款请求参数
/// </summary>
public class WechatRefundRequest
{
    /// <summary>
    /// 数据库名称
    /// </summary>
    public string DBName { get; set; } = string.Empty;

    /// <summary>
    /// 服务商商户号
    /// </summary>
    public string MchId { get; set; } = string.Empty;

    /// <summary>
    /// 服务商 AppId
    /// </summary>
    public string AppId { get; set; } = string.Empty;

    /// <summary>
    /// 子商户 AppId（服务商模式）
    /// </summary>
    public string SubAppId { get; set; } = string.Empty;

    /// <summary>
    /// API密钥
    /// </summary>
    public string ApiKey { get; set; } = string.Empty;

    /// <summary>
    /// 特约商户号
    /// </summary>
    public string SubMchId { get; set; } = string.Empty;

    /// <summary>
    /// 商户订单号
    /// </summary>
    public string OutTradeNo { get; set; } = string.Empty;

    /// <summary>
    /// 微信订单号（优先使用）
    /// </summary>
    public string TransactionId { get; set; } = string.Empty;

    /// <summary>
    /// 订单总金额（分）
    /// </summary>
    public int TotalFee { get; set; }

    /// <summary>
    /// 退款金额（分）
    /// </summary>
    public int RefundFee { get; set; }

    /// <summary>
    /// 退款原因
    /// </summary>
    public string RefundDesc { get; set; } = "客户申请退款";

    /// <summary>
    /// 退款单号（自动生成）
    /// </summary>
    public string OutRefundNo { get; set; } = string.Empty;

    /// <summary>
    /// 退款通知URL
    /// </summary>
    public string NotifyUrl { get; set; } = string.Empty;
}

/// <summary>
/// 微信退款响应结果
/// </summary>
public class WechatRefundResponse
{
    /// <summary>
    /// 是否成功
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// 返回代码
    /// </summary>
    public string ReturnCode { get; set; } = string.Empty;

    /// <summary>
    /// 返回信息
    /// </summary>
    public string ReturnMsg { get; set; } = string.Empty;

    /// <summary>
    /// 业务结果代码
    /// </summary>
    public string ResultCode { get; set; } = string.Empty;

    /// <summary>
    /// 错误代码
    /// </summary>
    public string ErrCode { get; set; } = string.Empty;

    /// <summary>
    /// 错误描述
    /// </summary>
    public string ErrCodeDes { get; set; } = string.Empty;

    /// <summary>
    /// 微信订单号
    /// </summary>
    public string TransactionId { get; set; } = string.Empty;

    /// <summary>
    /// 商户订单号
    /// </summary>
    public string OutTradeNo { get; set; } = string.Empty;

    /// <summary>
    /// 商户退款单号
    /// </summary>
    public string OutRefundNo { get; set; } = string.Empty;

    /// <summary>
    /// 微信退款单号
    /// </summary>
    public string RefundId { get; set; } = string.Empty;

    /// <summary>
    /// 退款金额
    /// </summary>
    public int RefundFee { get; set; }

    /// <summary>
    /// 订单总金额
    /// </summary>
    public int TotalFee { get; set; }

    /// <summary>
    /// 现金退款金额
    /// </summary>
    public int CashRefundFee { get; set; }

    /// <summary>
    /// 退款渠道
    /// </summary>
    public string RefundChannel { get; set; } = string.Empty;

    /// <summary>
    /// 退款入账账户
    /// </summary>
    public string RefundRecvAccout { get; set; } = string.Empty;

    /// <summary>
    /// 原始XML响应
    /// </summary>
    public string RawXml { get; set; } = string.Empty;

    /// <summary>
    /// 错误消息（用户友好）
    /// </summary>
    public string Message { get; set; } = string.Empty;
}
