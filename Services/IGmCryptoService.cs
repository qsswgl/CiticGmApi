using CiticGmApi.Models;

namespace CiticGmApi.Services;

/// <summary>
/// 国密加解密服务接口
/// </summary>
public interface IGmCryptoService
{
    /// <summary>
    /// SM2加密
    /// </summary>
    ApiResponse<EncryptResult> Sm2Encrypt(Sm2EncryptRequest request);

    /// <summary>
    /// SM2解密
    /// </summary>
    ApiResponse<DecryptResult> Sm2Decrypt(Sm2DecryptRequest request);

    /// <summary>
    /// SM3WithSM2签名
    /// </summary>
    ApiResponse<SignResult> Sm2Sign(Sm2SignRequest request);

    /// <summary>
    /// SM3WithSM2验签
    /// </summary>
    ApiResponse<VerifyResult> Sm2Verify(Sm2VerifyRequest request);

    /// <summary>
    /// SM4-CBC加密
    /// </summary>
    ApiResponse<EncryptResult> Sm4Encrypt(Sm4EncryptRequest request);

    /// <summary>
    /// SM4-CBC解密
    /// </summary>
    ApiResponse<DecryptResult> Sm4Decrypt(Sm4DecryptRequest request);

    /// <summary>
    /// 生成SM2密钥对
    /// </summary>
    ApiResponse<KeyPairResult> GenerateSm2KeyPair();

    /// <summary>
    /// 生成SM4密钥
    /// </summary>
    ApiResponse<Sm4KeyResult> GenerateSm4Key();
}
