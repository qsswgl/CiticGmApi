namespace CiticGmApi.Models;

/// <summary>
/// SM2加密请求模型
/// </summary>
public class Sm2EncryptRequest
{
    /// <summary>
    /// 待加密的明文数据（Base64编码或UTF8字符串）
    /// </summary>
    public string Plaintext { get; set; } = string.Empty;

    /// <summary>
    /// 公钥（Base64编码的X509证书内容，不含BEGIN/END标记）
    /// </summary>
    public string PublicKey { get; set; } = string.Empty;

    /// <summary>
    /// 是否将明文作为Base64解码（默认false，直接作为UTF8字符串）
    /// </summary>
    public bool IsBase64Input { get; set; } = false;
}

/// <summary>
/// SM2解密请求模型
/// </summary>
public class Sm2DecryptRequest
{
    /// <summary>
    /// 待解密的密文数据（Base64编码）
    /// </summary>
    public string Ciphertext { get; set; } = string.Empty;

    /// <summary>
    /// 私钥（PEM格式，包含BEGIN/END标记）
    /// </summary>
    public string PrivateKey { get; set; } = string.Empty;
}

/// <summary>
/// SM3WithSM2签名请求模型
/// </summary>
public class Sm2SignRequest
{
    /// <summary>
    /// 待签名的数据（UTF8字符串）
    /// </summary>
    public string Data { get; set; } = string.Empty;

    /// <summary>
    /// 私钥（PEM格式，包含BEGIN/END标记）
    /// </summary>
    public string PrivateKey { get; set; } = string.Empty;

    /// <summary>
    /// 用户ID（默认1234567812345678）
    /// </summary>
    public string UserId { get; set; } = "1234567812345678";
}

/// <summary>
/// SM3WithSM2验签请求模型
/// </summary>
public class Sm2VerifyRequest
{
    /// <summary>
    /// 原始数据（UTF8字符串）
    /// </summary>
    public string Data { get; set; } = string.Empty;

    /// <summary>
    /// 签名（Base64编码）
    /// </summary>
    public string Signature { get; set; } = string.Empty;

    /// <summary>
    /// 公钥（Base64编码的X509证书内容，不含BEGIN/END标记）
    /// </summary>
    public string PublicKey { get; set; } = string.Empty;

    /// <summary>
    /// 用户ID（默认1234567812345678）
    /// </summary>
    public string UserId { get; set; } = "1234567812345678";
}

/// <summary>
/// SM4加密请求模型
/// </summary>
public class Sm4EncryptRequest
{
    /// <summary>
    /// 待加密的明文数据（UTF8字符串）
    /// </summary>
    public string Plaintext { get; set; } = string.Empty;

    /// <summary>
    /// 密钥（16字节，Hex编码，32个字符）
    /// </summary>
    public string Key { get; set; } = string.Empty;

    /// <summary>
    /// 初始化向量IV（16字节，Hex编码，32个字符）。如不提供则使用全0
    /// </summary>
    public string? Iv { get; set; }
}

/// <summary>
/// SM4解密请求模型
/// </summary>
public class Sm4DecryptRequest
{
    /// <summary>
    /// 待解密的密文数据（Base64编码）
    /// </summary>
    public string Ciphertext { get; set; } = string.Empty;

    /// <summary>
    /// 密钥（16字节，Hex编码，32个字符）
    /// </summary>
    public string Key { get; set; } = string.Empty;

    /// <summary>
    /// 初始化向量IV（16字节，Hex编码，32个字符）。如不提供则使用全0
    /// </summary>
    public string? Iv { get; set; }
}

/// <summary>
/// 通用响应模型
/// </summary>
public class ApiResponse<T>
{
    /// <summary>
    /// 是否成功
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// 消息
    /// </summary>
    public string Message { get; set; } = string.Empty;

    /// <summary>
    /// 数据
    /// </summary>
    public T? Data { get; set; }
}

/// <summary>
/// 加密结果
/// </summary>
public class EncryptResult
{
    /// <summary>
    /// 密文（Base64编码）
    /// </summary>
    public string Ciphertext { get; set; } = string.Empty;
}

/// <summary>
/// 解密结果
/// </summary>
public class DecryptResult
{
    /// <summary>
    /// 明文
    /// </summary>
    public string Plaintext { get; set; } = string.Empty;
}

/// <summary>
/// 签名结果
/// </summary>
public class SignResult
{
    /// <summary>
    /// 签名（Base64编码）
    /// </summary>
    public string Signature { get; set; } = string.Empty;
}

/// <summary>
/// 验签结果
/// </summary>
public class VerifyResult
{
    /// <summary>
    /// 验签是否通过
    /// </summary>
    public bool IsValid { get; set; }
}

/// <summary>
/// 密钥对生成结果
/// </summary>
public class KeyPairResult
{
    /// <summary>
    /// 公钥（Hex编码）
    /// </summary>
    public string PublicKeyHex { get; set; } = string.Empty;

    /// <summary>
    /// 私钥（Hex编码）
    /// </summary>
    public string PrivateKeyHex { get; set; } = string.Empty;
}

/// <summary>
/// SM4密钥生成结果
/// </summary>
public class Sm4KeyResult
{
    /// <summary>
    /// SM4密钥（Hex编码，32个字符）
    /// </summary>
    public string KeyHex { get; set; } = string.Empty;
}
