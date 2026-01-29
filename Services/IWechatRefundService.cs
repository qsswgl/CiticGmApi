using AbcPaymentGateway.Models;

namespace AbcPaymentGateway.Services;

/// <summary>
/// 微信退款服务接口
/// </summary>
public interface IWechatRefundService
{
    /// <summary>
    /// 执行退款
    /// </summary>
    /// <param name="request">退款请求参数</param>
    /// <returns>退款结果</returns>
    Task<WechatRefundResponse> RefundAsync(WechatRefundRequest request);

    /// <summary>
    /// 查询退款
    /// </summary>
    /// <param name="outRefundNo">商户退款单号</param>
    /// <param name="mchId">商户号</param>
    /// <param name="apiKey">API密钥</param>
    /// <returns>退款查询结果</returns>
    Task<WechatRefundResponse> QueryRefundAsync(string outRefundNo, string mchId, string apiKey);
}
