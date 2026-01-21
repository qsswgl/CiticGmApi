using CiticGmApi.Models;
using CiticGmApi.Services;
using Microsoft.AspNetCore.Mvc;

namespace CiticGmApi.Controllers;

/// <summary>
/// 国密加解密API控制器
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class CryptoController : ControllerBase
{
    private readonly IGmCryptoService _cryptoService;

    public CryptoController(IGmCryptoService cryptoService)
    {
        _cryptoService = cryptoService;
    }

    #region SM2非对称加解密

    /// <summary>
    /// SM2非对称加密
    /// </summary>
    /// <remarks>
    /// 使用SM2国密算法进行非对称加密。
    /// 
    /// 请求示例:
    /// 
    ///     POST /api/Crypto/sm2/encrypt
    ///     {
    ///        "plaintext": "Hello World",
    ///        "publicKey": "MIIB2jCCAYWgAwIBAgIGBzRJk5c4...",
    ///        "isBase64Input": false
    ///     }
    /// 
    /// </remarks>
    /// <param name="request">加密请求</param>
    /// <returns>加密结果（Base64编码的密文）</returns>
    /// <response code="200">加密成功</response>
    /// <response code="400">请求参数错误</response>
    [HttpPost("sm2/encrypt")]
    [ProducesResponseType(typeof(ApiResponse<EncryptResult>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<EncryptResult>), StatusCodes.Status400BadRequest)]
    public ActionResult<ApiResponse<EncryptResult>> Sm2Encrypt([FromBody] Sm2EncryptRequest request)
    {
        if (string.IsNullOrEmpty(request.Plaintext) || string.IsNullOrEmpty(request.PublicKey))
        {
            return BadRequest(new ApiResponse<EncryptResult>
            {
                Success = false,
                Message = "明文和公钥不能为空"
            });
        }

        var result = _cryptoService.Sm2Encrypt(request);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    /// <summary>
    /// SM2非对称解密
    /// </summary>
    /// <remarks>
    /// 使用SM2国密算法进行非对称解密。
    /// 
    /// 请求示例:
    /// 
    ///     POST /api/Crypto/sm2/decrypt
    ///     {
    ///        "ciphertext": "Base64编码的密文...",
    ///        "privateKey": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
    ///     }
    /// 
    /// </remarks>
    /// <param name="request">解密请求</param>
    /// <returns>解密结果（明文）</returns>
    /// <response code="200">解密成功</response>
    /// <response code="400">请求参数错误或解密失败</response>
    [HttpPost("sm2/decrypt")]
    [ProducesResponseType(typeof(ApiResponse<DecryptResult>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<DecryptResult>), StatusCodes.Status400BadRequest)]
    public ActionResult<ApiResponse<DecryptResult>> Sm2Decrypt([FromBody] Sm2DecryptRequest request)
    {
        if (string.IsNullOrEmpty(request.Ciphertext) || string.IsNullOrEmpty(request.PrivateKey))
        {
            return BadRequest(new ApiResponse<DecryptResult>
            {
                Success = false,
                Message = "密文和私钥不能为空"
            });
        }

        var result = _cryptoService.Sm2Decrypt(request);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    #endregion

    #region SM3WithSM2签名验签

    /// <summary>
    /// SM3WithSM2签名
    /// </summary>
    /// <remarks>
    /// 使用SM3摘要算法和SM2私钥进行数字签名。
    /// 
    /// 请求示例:
    /// 
    ///     POST /api/Crypto/sm2/sign
    ///     {
    ///        "data": "待签名的数据",
    ///        "privateKey": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----",
    ///        "userId": "1234567812345678"
    ///     }
    /// 
    /// </remarks>
    /// <param name="request">签名请求</param>
    /// <returns>签名结果（Base64编码）</returns>
    /// <response code="200">签名成功</response>
    /// <response code="400">请求参数错误</response>
    [HttpPost("sm2/sign")]
    [ProducesResponseType(typeof(ApiResponse<SignResult>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<SignResult>), StatusCodes.Status400BadRequest)]
    public ActionResult<ApiResponse<SignResult>> Sm2Sign([FromBody] Sm2SignRequest request)
    {
        if (string.IsNullOrEmpty(request.Data) || string.IsNullOrEmpty(request.PrivateKey))
        {
            return BadRequest(new ApiResponse<SignResult>
            {
                Success = false,
                Message = "数据和私钥不能为空"
            });
        }

        var result = _cryptoService.Sm2Sign(request);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    /// <summary>
    /// SM3WithSM2验签
    /// </summary>
    /// <remarks>
    /// 使用SM3摘要算法和SM2公钥进行数字签名验证。
    /// 
    /// 请求示例:
    /// 
    ///     POST /api/Crypto/sm2/verify
    ///     {
    ///        "data": "原始数据",
    ///        "signature": "Base64编码的签名",
    ///        "publicKey": "MIIB2jCCAYWgAwIBAgIGBzRJk5c4...",
    ///        "userId": "1234567812345678"
    ///     }
    /// 
    /// </remarks>
    /// <param name="request">验签请求</param>
    /// <returns>验签结果</returns>
    /// <response code="200">验签完成</response>
    /// <response code="400">请求参数错误</response>
    [HttpPost("sm2/verify")]
    [ProducesResponseType(typeof(ApiResponse<VerifyResult>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<VerifyResult>), StatusCodes.Status400BadRequest)]
    public ActionResult<ApiResponse<VerifyResult>> Sm2Verify([FromBody] Sm2VerifyRequest request)
    {
        if (string.IsNullOrEmpty(request.Data) || string.IsNullOrEmpty(request.Signature) || string.IsNullOrEmpty(request.PublicKey))
        {
            return BadRequest(new ApiResponse<VerifyResult>
            {
                Success = false,
                Message = "数据、签名和公钥不能为空"
            });
        }

        var result = _cryptoService.Sm2Verify(request);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    #endregion

    #region SM4对称加解密

    /// <summary>
    /// SM4-CBC对称加密
    /// </summary>
    /// <remarks>
    /// 使用SM4国密算法进行CBC模式对称加密。
    /// 
    /// 请求示例:
    /// 
    ///     POST /api/Crypto/sm4/encrypt
    ///     {
    ///        "plaintext": "待加密的数据",
    ///        "key": "0123456789abcdef0123456789abcdef",
    ///        "iv": "30303030303030303030303030303030"
    ///     }
    /// 
    /// 注意：
    /// - key必须是32个Hex字符（16字节）
    /// - iv如不提供则使用"0000000000000000"
    /// </remarks>
    /// <param name="request">加密请求</param>
    /// <returns>加密结果（Base64编码的密文）</returns>
    /// <response code="200">加密成功</response>
    /// <response code="400">请求参数错误</response>
    [HttpPost("sm4/encrypt")]
    [ProducesResponseType(typeof(ApiResponse<EncryptResult>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<EncryptResult>), StatusCodes.Status400BadRequest)]
    public ActionResult<ApiResponse<EncryptResult>> Sm4Encrypt([FromBody] Sm4EncryptRequest request)
    {
        if (string.IsNullOrEmpty(request.Plaintext) || string.IsNullOrEmpty(request.Key))
        {
            return BadRequest(new ApiResponse<EncryptResult>
            {
                Success = false,
                Message = "明文和密钥不能为空"
            });
        }

        if (request.Key.Length != 32)
        {
            return BadRequest(new ApiResponse<EncryptResult>
            {
                Success = false,
                Message = "SM4密钥必须是32个Hex字符（16字节）"
            });
        }

        var result = _cryptoService.Sm4Encrypt(request);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    /// <summary>
    /// SM4-CBC对称解密
    /// </summary>
    /// <remarks>
    /// 使用SM4国密算法进行CBC模式对称解密。
    /// 
    /// 请求示例:
    /// 
    ///     POST /api/Crypto/sm4/decrypt
    ///     {
    ///        "ciphertext": "Base64编码的密文",
    ///        "key": "0123456789abcdef0123456789abcdef",
    ///        "iv": "30303030303030303030303030303030"
    ///     }
    /// 
    /// </remarks>
    /// <param name="request">解密请求</param>
    /// <returns>解密结果（明文）</returns>
    /// <response code="200">解密成功</response>
    /// <response code="400">请求参数错误或解密失败</response>
    [HttpPost("sm4/decrypt")]
    [ProducesResponseType(typeof(ApiResponse<DecryptResult>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<DecryptResult>), StatusCodes.Status400BadRequest)]
    public ActionResult<ApiResponse<DecryptResult>> Sm4Decrypt([FromBody] Sm4DecryptRequest request)
    {
        if (string.IsNullOrEmpty(request.Ciphertext) || string.IsNullOrEmpty(request.Key))
        {
            return BadRequest(new ApiResponse<DecryptResult>
            {
                Success = false,
                Message = "密文和密钥不能为空"
            });
        }

        if (request.Key.Length != 32)
        {
            return BadRequest(new ApiResponse<DecryptResult>
            {
                Success = false,
                Message = "SM4密钥必须是32个Hex字符（16字节）"
            });
        }

        var result = _cryptoService.Sm4Decrypt(request);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    #endregion

    #region 密钥生成

    /// <summary>
    /// 生成SM2密钥对
    /// </summary>
    /// <remarks>
    /// 生成一对SM2非对称密钥（公钥和私钥），返回Hex编码格式。
    /// </remarks>
    /// <returns>密钥对（Hex编码）</returns>
    /// <response code="200">生成成功</response>
    [HttpGet("sm2/keypair")]
    [ProducesResponseType(typeof(ApiResponse<KeyPairResult>), StatusCodes.Status200OK)]
    public ActionResult<ApiResponse<KeyPairResult>> GenerateSm2KeyPair()
    {
        var result = _cryptoService.GenerateSm2KeyPair();
        return Ok(result);
    }

    /// <summary>
    /// 生成SM4密钥
    /// </summary>
    /// <remarks>
    /// 生成一个16字节的SM4对称密钥，返回Hex编码格式（32个字符）。
    /// </remarks>
    /// <returns>SM4密钥（Hex编码）</returns>
    /// <response code="200">生成成功</response>
    [HttpGet("sm4/key")]
    [ProducesResponseType(typeof(ApiResponse<Sm4KeyResult>), StatusCodes.Status200OK)]
    public ActionResult<ApiResponse<Sm4KeyResult>> GenerateSm4Key()
    {
        var result = _cryptoService.GenerateSm4Key();
        return Ok(result);
    }

    #endregion

    /// <summary>
    /// 健康检查
    /// </summary>
    /// <returns>服务状态</returns>
    [HttpGet("health")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public ActionResult Health()
    {
        return Ok(new { status = "healthy", timestamp = DateTime.UtcNow });
    }
}
