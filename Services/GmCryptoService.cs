using System.Text;
using CiticGmApi.Models;
using Org.BouncyCastle.Asn1;
using Org.BouncyCastle.Asn1.GM;
using Org.BouncyCastle.Asn1.X9;
using Org.BouncyCastle.Crypto;
using Org.BouncyCastle.Crypto.Digests;
using Org.BouncyCastle.Crypto.Engines;
using Org.BouncyCastle.Crypto.Generators;
using Org.BouncyCastle.Crypto.Parameters;
using Org.BouncyCastle.Math;
using Org.BouncyCastle.Security;
using Org.BouncyCastle.Utilities;
using Org.BouncyCastle.Utilities.Encoders;
using Org.BouncyCastle.X509;

namespace CiticGmApi.Services;

/// <summary>
/// 国密加解密服务实现
/// </summary>
public class GmCryptoService : IGmCryptoService
{
    private static readonly X9ECParameters x9ECParameters = GMNamedCurves.GetByName("sm2p256v1");
    private static readonly ECDomainParameters ecDomainParameters = new ECDomainParameters(
        x9ECParameters.Curve, x9ECParameters.G, x9ECParameters.N);

    private const int RS_LEN = 32;
    private const string SM4_CBC_PKCS7PADDING = "SM4/CBC/PKCS7Padding";

    #region SM2加解密

    public ApiResponse<EncryptResult> Sm2Encrypt(Sm2EncryptRequest request)
    {
        try
        {
            // 获取公钥
            var publicKey = GetPublickeyFromX509String(request.PublicKey);
            if (publicKey == null)
            {
                return new ApiResponse<EncryptResult>
                {
                    Success = false,
                    Message = "无效的公钥格式"
                };
            }

            // 处理公钥
            var pubKeyHex = Hex.ToHexString(((ECPublicKeyParameters)publicKey).Q.GetEncoded());
            if (pubKeyHex.Length == 130)
            {
                pubKeyHex = pubKeyHex.Substring(2, 128);
            }
            string x = pubKeyHex.Substring(0, 64);
            string y = pubKeyHex.Substring(64);
            var processedPubKey = GetPublickeyFromXY(new BigInteger(x, 16), new BigInteger(y, 16));

            // 获取明文
            byte[] plainBytes = request.IsBase64Input
                ? Convert.FromBase64String(request.Plaintext)
                : Encoding.UTF8.GetBytes(request.Plaintext);

            // 加密
            byte[] cipherBytes = Sm2EncryptInternal(plainBytes, (ECPublicKeyParameters)processedPubKey);
            if (cipherBytes == null)
            {
                return new ApiResponse<EncryptResult>
                {
                    Success = false,
                    Message = "SM2加密失败"
                };
            }

            // 处理密文格式（去掉04前缀）
            string cipherHex = Hex.ToHexString(cipherBytes);
            if (cipherHex.StartsWith("04"))
            {
                cipherHex = cipherHex.Substring(2);
            }

            return new ApiResponse<EncryptResult>
            {
                Success = true,
                Message = "加密成功",
                Data = new EncryptResult
                {
                    Ciphertext = Convert.ToBase64String(Hex.Decode(cipherHex))
                }
            };
        }
        catch (Exception ex)
        {
            return new ApiResponse<EncryptResult>
            {
                Success = false,
                Message = $"SM2加密异常: {ex.Message}"
            };
        }
    }

    public ApiResponse<DecryptResult> Sm2Decrypt(Sm2DecryptRequest request)
    {
        try
        {
            // 读取私钥
            var privateKey = ReadPemECP(request.PrivateKey);
            if (privateKey == null)
            {
                return new ApiResponse<DecryptResult>
                {
                    Success = false,
                    Message = "无效的私钥格式"
                };
            }

            // 解密
            byte[] cipherBytes = Convert.FromBase64String(request.Ciphertext);
            byte[] plainBytes = Sm2DecryptInternal(cipherBytes, privateKey);
            if (plainBytes == null)
            {
                return new ApiResponse<DecryptResult>
                {
                    Success = false,
                    Message = "SM2解密失败"
                };
            }

            return new ApiResponse<DecryptResult>
            {
                Success = true,
                Message = "解密成功",
                Data = new DecryptResult
                {
                    Plaintext = Encoding.UTF8.GetString(plainBytes)
                }
            };
        }
        catch (Exception ex)
        {
            return new ApiResponse<DecryptResult>
            {
                Success = false,
                Message = $"SM2解密异常: {ex.Message}"
            };
        }
    }

    #endregion

    #region SM3WithSM2签名验签

    public ApiResponse<SignResult> Sm2Sign(Sm2SignRequest request)
    {
        try
        {
            // 读取私钥
            var privateKey = ReadPemECP(request.PrivateKey);
            if (privateKey == null)
            {
                return new ApiResponse<SignResult>
                {
                    Success = false,
                    Message = "无效的私钥格式"
                };
            }

            // 从私钥获取D值重建私钥对象
            string privateKeyHex = Hex.ToHexString(privateKey.D.ToByteArray());
            BigInteger d = new BigInteger(privateKeyHex, 16);
            var bcecPrivateKey = GetPrivatekeyFromD(d);

            byte[] dataBytes = Encoding.UTF8.GetBytes(request.Data);
            byte[] userIdBytes = Encoding.UTF8.GetBytes(request.UserId);

            // 签名
            byte[] signature = SignSm3WithSm2(dataBytes, userIdBytes, bcecPrivateKey);
            if (signature == null)
            {
                return new ApiResponse<SignResult>
                {
                    Success = false,
                    Message = "签名失败"
                };
            }

            return new ApiResponse<SignResult>
            {
                Success = true,
                Message = "签名成功",
                Data = new SignResult
                {
                    Signature = Convert.ToBase64String(signature)
                }
            };
        }
        catch (Exception ex)
        {
            return new ApiResponse<SignResult>
            {
                Success = false,
                Message = $"签名异常: {ex.Message}"
            };
        }
    }

    public ApiResponse<VerifyResult> Sm2Verify(Sm2VerifyRequest request)
    {
        try
        {
            // 获取公钥
            var publicKey = GetPublickeyFromX509String(request.PublicKey);
            if (publicKey == null)
            {
                return new ApiResponse<VerifyResult>
                {
                    Success = false,
                    Message = "无效的公钥格式"
                };
            }

            // 处理公钥
            var pubKeyHex = Hex.ToHexString(((ECPublicKeyParameters)publicKey).Q.GetEncoded());
            if (pubKeyHex.Length == 130)
            {
                pubKeyHex = pubKeyHex.Substring(2, 128);
            }
            string x = pubKeyHex.Substring(0, 64);
            string y = pubKeyHex.Substring(64);
            var processedPubKey = GetPublickeyFromXY(new BigInteger(x, 16), new BigInteger(y, 16));

            byte[] dataBytes = Encoding.UTF8.GetBytes(request.Data);
            byte[] userIdBytes = Encoding.UTF8.GetBytes(request.UserId);
            byte[] signatureBytes = Convert.FromBase64String(request.Signature);

            // 验签
            bool isValid = VerifySm3WithSm2(dataBytes, userIdBytes, signatureBytes, processedPubKey);

            return new ApiResponse<VerifyResult>
            {
                Success = true,
                Message = isValid ? "验签通过" : "验签失败",
                Data = new VerifyResult
                {
                    IsValid = isValid
                }
            };
        }
        catch (Exception ex)
        {
            return new ApiResponse<VerifyResult>
            {
                Success = false,
                Message = $"验签异常: {ex.Message}"
            };
        }
    }

    #endregion

    #region SM4加解密

    public ApiResponse<EncryptResult> Sm4Encrypt(Sm4EncryptRequest request)
    {
        try
        {
            byte[] keyBytes = Hex.Decode(request.Key);
            if (keyBytes.Length != 16)
            {
                return new ApiResponse<EncryptResult>
                {
                    Success = false,
                    Message = "SM4密钥必须是16字节（32个Hex字符）"
                };
            }

            byte[] iv = string.IsNullOrEmpty(request.Iv)
                ? Encoding.UTF8.GetBytes("0000000000000000")
                : Hex.Decode(request.Iv);

            byte[] plainBytes = Encoding.UTF8.GetBytes(request.Plaintext);
            byte[] cipherBytes = Sm4EncryptCBC(keyBytes, plainBytes, iv);
            if (cipherBytes == null)
            {
                return new ApiResponse<EncryptResult>
                {
                    Success = false,
                    Message = "SM4加密失败"
                };
            }

            return new ApiResponse<EncryptResult>
            {
                Success = true,
                Message = "加密成功",
                Data = new EncryptResult
                {
                    Ciphertext = Convert.ToBase64String(cipherBytes)
                }
            };
        }
        catch (Exception ex)
        {
            return new ApiResponse<EncryptResult>
            {
                Success = false,
                Message = $"SM4加密异常: {ex.Message}"
            };
        }
    }

    public ApiResponse<DecryptResult> Sm4Decrypt(Sm4DecryptRequest request)
    {
        try
        {
            byte[] keyBytes = Hex.Decode(request.Key);
            if (keyBytes.Length != 16)
            {
                return new ApiResponse<DecryptResult>
                {
                    Success = false,
                    Message = "SM4密钥必须是16字节（32个Hex字符）"
                };
            }

            byte[] iv = string.IsNullOrEmpty(request.Iv)
                ? Encoding.UTF8.GetBytes("0000000000000000")
                : Hex.Decode(request.Iv);

            byte[] cipherBytes = Convert.FromBase64String(request.Ciphertext);
            byte[] plainBytes = Sm4DecryptCBC(keyBytes, cipherBytes, iv);
            if (plainBytes == null)
            {
                return new ApiResponse<DecryptResult>
                {
                    Success = false,
                    Message = "SM4解密失败"
                };
            }

            return new ApiResponse<DecryptResult>
            {
                Success = true,
                Message = "解密成功",
                Data = new DecryptResult
                {
                    Plaintext = Encoding.UTF8.GetString(plainBytes)
                }
            };
        }
        catch (Exception ex)
        {
            return new ApiResponse<DecryptResult>
            {
                Success = false,
                Message = $"SM4解密异常: {ex.Message}"
            };
        }
    }

    #endregion

    #region 密钥生成

    public ApiResponse<KeyPairResult> GenerateSm2KeyPair()
    {
        try
        {
            var keyPair = GenerateKeyPair();
            if (keyPair == null)
            {
                return new ApiResponse<KeyPairResult>
                {
                    Success = false,
                    Message = "生成密钥对失败"
                };
            }

            string privateKeyHex = Hex.ToHexString(((ECPrivateKeyParameters)keyPair.Private).D.ToByteArray());
            string publicKeyHex = Hex.ToHexString(((ECPublicKeyParameters)keyPair.Public).Q.GetEncoded());

            return new ApiResponse<KeyPairResult>
            {
                Success = true,
                Message = "密钥对生成成功",
                Data = new KeyPairResult
                {
                    PrivateKeyHex = privateKeyHex,
                    PublicKeyHex = publicKeyHex
                }
            };
        }
        catch (Exception ex)
        {
            return new ApiResponse<KeyPairResult>
            {
                Success = false,
                Message = $"生成密钥对异常: {ex.Message}"
            };
        }
    }

    public ApiResponse<Sm4KeyResult> GenerateSm4Key()
    {
        try
        {
            byte[] key = CreateKey();
            return new ApiResponse<Sm4KeyResult>
            {
                Success = true,
                Message = "SM4密钥生成成功",
                Data = new Sm4KeyResult
                {
                    KeyHex = Hex.ToHexString(key)
                }
            };
        }
        catch (Exception ex)
        {
            return new ApiResponse<Sm4KeyResult>
            {
                Success = false,
                Message = $"生成SM4密钥异常: {ex.Message}"
            };
        }
    }

    #endregion

    #region 内部方法

    private static ECPrivateKeyParameters? ReadPemECP(string pem)
    {
        try
        {
            using TextReader reader = new StringReader(pem);
            var obj = new Org.BouncyCastle.OpenSsl.PemReader(reader).ReadObject();
            return obj as ECPrivateKeyParameters;
        }
        catch
        {
            return null;
        }
    }

    private static AsymmetricKeyParameter? GetPublickeyFromX509String(string publicKeyCert)
    {
        try
        {
            string certContent = StrToPubCert(publicKeyCert);
            byte[] bytesCerContent = Encoding.UTF8.GetBytes(certContent);
            X509Certificate certificate = new X509CertificateParser().ReadCertificate(bytesCerContent);
            return certificate.GetPublicKey();
        }
        catch
        {
            return null;
        }
    }

    private static string StrToPubCert(string publicKeyCert)
    {
        string rn = "\n";
        StringBuilder sbKey = new StringBuilder(publicKeyCert);
        int nKeyLen = sbKey.Length;
        for (int i = 64; i < nKeyLen; i += 64)
        {
            sbKey.Insert(i, rn);
            i++;
        }
        sbKey.Insert(0, "-----BEGIN CERTIFICATE-----" + rn);
        sbKey.Append(rn + "-----END CERTIFICATE-----" + rn);
        return sbKey.ToString();
    }

    private static ECPrivateKeyParameters GetPrivatekeyFromD(BigInteger d)
    {
        return new ECPrivateKeyParameters(d, ecDomainParameters);
    }

    private static ECPublicKeyParameters GetPublickeyFromXY(BigInteger x, BigInteger y)
    {
        return new ECPublicKeyParameters(x9ECParameters.Curve.CreatePoint(x, y), ecDomainParameters);
    }

    private static AsymmetricCipherKeyPair? GenerateKeyPair()
    {
        try
        {
            ECKeyPairGenerator kpGen = new ECKeyPairGenerator();
            kpGen.Init(new ECKeyGenerationParameters(ecDomainParameters, new SecureRandom()));
            return kpGen.GenerateKeyPair();
        }
        catch
        {
            return null;
        }
    }

    private static byte[]? CreateKey()
    {
        try
        {
            byte[] pbKey = new byte[16];
            SecureRandom random = new SecureRandom();
            random.NextBytes(pbKey);
            return pbKey;
        }
        catch
        {
            return null;
        }
    }

    private static byte[]? SignSm3WithSm2(byte[] msg, byte[] userId, AsymmetricKeyParameter privateKey)
    {
        return RsAsn1ToPlainByteArray(SignSm3WithSm2Asn1Rs(msg, userId, privateKey));
    }

    private static byte[]? SignSm3WithSm2Asn1Rs(byte[] msg, byte[] userId, AsymmetricKeyParameter privateKey)
    {
        try
        {
            ISigner signer = SignerUtilities.GetSigner("SM3withSM2");
            signer.Init(true, new ParametersWithRandom(privateKey));
            signer.BlockUpdate(msg, 0, msg.Length);
            return signer.GenerateSignature();
        }
        catch
        {
            return null;
        }
    }

    private static bool VerifySm3WithSm2(byte[] msg, byte[] userId, byte[] rs, AsymmetricKeyParameter publicKey)
    {
        if (rs == null || msg == null || userId == null) return false;
        if (rs.Length != RS_LEN * 2) return false;
        return VerifySm3WithSm2Asn1Rs(msg, userId, RsPlainByteArrayToAsn1(rs), publicKey);
    }

    private static bool VerifySm3WithSm2Asn1Rs(byte[] msg, byte[] userId, byte[]? sign, AsymmetricKeyParameter publicKey)
    {
        try
        {
            if (sign == null) return false;
            ISigner signer = SignerUtilities.GetSigner("SM3withSM2");
            signer.Init(false, publicKey);
            signer.BlockUpdate(msg, 0, msg.Length);
            return signer.VerifySignature(sign);
        }
        catch
        {
            return false;
        }
    }

    private static byte[]? Sm2EncryptInternal(byte[] data, AsymmetricKeyParameter pubkey)
    {
        try
        {
            SM2Engine sm2Engine = new SM2Engine();
            sm2Engine.Init(true, new ParametersWithRandom(pubkey, new SecureRandom()));
            byte[] result = sm2Engine.ProcessBlock(data, 0, data.Length);
            return ChangeC1C2C3ToC1C3C2(result);
        }
        catch
        {
            return null;
        }
    }

    private static byte[]? Sm2DecryptInternal(byte[] data, AsymmetricKeyParameter key)
    {
        try
        {
            if (!Hex.ToHexString(data).StartsWith("04"))
            {
                data = Hex.Decode("04" + Hex.ToHexString(data));
            }
            SM2Engine sm2Engine = new SM2Engine();
            sm2Engine.Init(false, key);
            return sm2Engine.ProcessBlock(ChangeC1C3C2ToC1C2C3(data), 0, ChangeC1C3C2ToC1C2C3(data).Length);
        }
        catch
        {
            return null;
        }
    }

    private static byte[] ChangeC1C2C3ToC1C3C2(byte[] c1c2c3)
    {
        int c1Len = (x9ECParameters.Curve.FieldSize + 7) / 8 * 2 + 1;
        const int c3Len = 32;
        byte[] result = new byte[c1c2c3.Length];
        Buffer.BlockCopy(c1c2c3, 0, result, 0, c1Len);
        Buffer.BlockCopy(c1c2c3, c1c2c3.Length - c3Len, result, c1Len, c3Len);
        Buffer.BlockCopy(c1c2c3, c1Len, result, c1Len + c3Len, c1c2c3.Length - c1Len - c3Len);
        return result;
    }

    private static byte[] ChangeC1C3C2ToC1C2C3(byte[] c1c3c2)
    {
        int c1Len = (x9ECParameters.Curve.FieldSize + 7) / 8 * 2 + 1;
        const int c3Len = 32;
        byte[] result = new byte[c1c3c2.Length];
        Buffer.BlockCopy(c1c3c2, 0, result, 0, c1Len);
        Buffer.BlockCopy(c1c3c2, c1Len + c3Len, result, c1Len, c1c3c2.Length - c1Len - c3Len);
        Buffer.BlockCopy(c1c3c2, c1Len, result, c1c3c2.Length - c3Len, c3Len);
        return result;
    }

    private static byte[]? Sm4EncryptCBC(byte[] keyBytes, byte[] plain, byte[] iv)
    {
        try
        {
            KeyParameter key = ParameterUtilities.CreateKeyParameter("SM4", keyBytes);
            IBufferedCipher c = CipherUtilities.GetCipher(SM4_CBC_PKCS7PADDING);
            c.Init(true, new ParametersWithIV(key, iv));
            return c.DoFinal(plain);
        }
        catch
        {
            return null;
        }
    }

    private static byte[]? Sm4DecryptCBC(byte[] keyBytes, byte[] cipher, byte[] iv)
    {
        try
        {
            KeyParameter key = ParameterUtilities.CreateKeyParameter("SM4", keyBytes);
            IBufferedCipher c = CipherUtilities.GetCipher(SM4_CBC_PKCS7PADDING);
            c.Init(false, new ParametersWithIV(key, iv));
            return c.DoFinal(cipher);
        }
        catch
        {
            return null;
        }
    }

    private static byte[] BigIntToFixexLengthBytes(BigInteger rOrS)
    {
        byte[] rs = rOrS.ToByteArray();
        if (rs.Length == RS_LEN) return rs;
        else if (rs.Length == RS_LEN + 1 && rs[0] == 0) return Arrays.CopyOfRange(rs, 1, RS_LEN + 1);
        else if (rs.Length < RS_LEN)
        {
            byte[] result = new byte[RS_LEN];
            Arrays.Fill(result, (byte)0);
            Buffer.BlockCopy(rs, 0, result, RS_LEN - rs.Length, rs.Length);
            return result;
        }
        else
        {
            throw new ArgumentException("err rs: " + Hex.ToHexString(rs));
        }
    }

    private static byte[]? RsAsn1ToPlainByteArray(byte[]? rsDer)
    {
        if (rsDer == null) return null;
        Asn1Sequence seq = Asn1Sequence.GetInstance(rsDer);
        byte[] r = BigIntToFixexLengthBytes(DerInteger.GetInstance(seq[0]).Value);
        byte[] s = BigIntToFixexLengthBytes(DerInteger.GetInstance(seq[1]).Value);
        byte[] result = new byte[RS_LEN * 2];
        Buffer.BlockCopy(r, 0, result, 0, r.Length);
        Buffer.BlockCopy(s, 0, result, RS_LEN, s.Length);
        return result;
    }

    private static byte[]? RsPlainByteArrayToAsn1(byte[] sign)
    {
        if (sign.Length != RS_LEN * 2) throw new ArgumentException("err rs. ");
        BigInteger r = new BigInteger(1, Arrays.CopyOfRange(sign, 0, RS_LEN));
        BigInteger s = new BigInteger(1, Arrays.CopyOfRange(sign, RS_LEN, RS_LEN * 2));
        Asn1EncodableVector v = new Asn1EncodableVector();
        v.Add(new DerInteger(r));
        v.Add(new DerInteger(s));
        try
        {
            return new DerSequence(v).GetEncoded("DER");
        }
        catch
        {
            return null;
        }
    }

    #endregion
}
