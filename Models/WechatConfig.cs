namespace AbcPaymentGateway.Models;

/// <summary>
/// 微信服务商支付配置
/// </summary>
public class WechatConfig
{
    /// <summary>
    /// 微信服务商商户号
    /// </summary>
    public string MchId { get; set; } = "1286651401";

    /// <summary>
    /// 服务商 AppId
    /// </summary>
    public string AppId { get; set; } = "wxc74a6aac13640229";

    /// <summary>
    /// 子商户 AppId（服务商模式）
    /// </summary>
    public string SubAppId { get; set; } = string.Empty;

    /// <summary>
    /// API 密钥
    /// </summary>
    public string ApiKey { get; set; } = string.Empty;

    /// <summary>
    /// 证书路径 (P12格式)
    /// </summary>
    public string CertPath { get; set; } = string.Empty;

    /// <summary>
    /// 证书密码（默认为商户号）
    /// </summary>
    public string CertPassword { get; set; } = string.Empty;

    /// <summary>
    /// 微信支付API地址
    /// </summary>
    public string ApiUrl { get; set; } = "https://api.mch.weixin.qq.com";

    /// <summary>
    /// 退款接口路径
    /// </summary>
    public string RefundUrl { get; set; } = "/secapi/pay/refund";

    /// <summary>
    /// 退款查询接口路径
    /// </summary>
    public string RefundQueryUrl { get; set; } = "/pay/refundquery";

    /// <summary>
    /// 超时时间（秒）
    /// </summary>
    public int Timeout { get; set; } = 30;

    /// <summary>
    /// 是否沙箱环境
    /// </summary>
    public bool IsSandbox { get; set; } = false;

    /// <summary>
    /// 运行环境 (Production/Development/Test)
    /// </summary>
    public string Environment { get; set; } = "Production";
}
