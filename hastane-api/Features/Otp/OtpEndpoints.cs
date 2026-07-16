using System.Text.RegularExpressions;
using Microsoft.Extensions.Logging;
using Ozi.Application.Common;
using Ozi.Application.Infrastructure.Config;
using Ozi.Infrastructure.Integration.Hbys;
using Ozi.Infrastructure.Integration.Sms;

namespace Ozi.Features.Otp;

public record OtpRequestBody(string CepTel);

public record OtpVerifyBody(string CepTel, string Code);

/// <summary>
/// SMS ile doğrulama (OTP) akışı.
///
/// ⚠️ Turkcell HBYS entegrasyon dokümanında SMS/OTP servisi YOKTUR; bu yüzden
/// kod üretimi/gönderimi/doğrulaması bu backend'dedir (3G Bilişim gateway).
/// Menü ve personel kartı ise mobil uygulamada DOĞRUDAN Turkcell'den çekilir.
///
///  • POST /auth/otp/request { cepTel }        → kod üretir + SMS gönderir
///  • POST /auth/otp/verify  { cepTel, code }  → kodu doğrular
/// </summary>
public static class OtpEndpoints
{
    public static void MapOtpEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/auth/otp").WithTags("OTP (SMS)");

        group.MapPost("/request", async (
            OtpRequestBody body,
            OtpStore store,
            ISmsSender sms,
            HbysClient hbys,
            SmsSettings settings,
            ILoggerFactory loggerFactory,
            CancellationToken ct) =>
        {
            var logger = loggerFactory.CreateLogger("Otp");
            var phone = NormalizePhone(body.CepTel);

            if (phone is null)
                return ApiResults.Error(StatusCodes.Status400BadRequest,
                    "Geçerli bir cep telefonu girin (10 hane).");

            if (store.CooldownRemaining(phone) is { } remaining)
                return ApiResults.Error(StatusCodes.Status429TooManyRequests,
                    $"Yeni kod için {Math.Ceiling(remaining.TotalSeconds)} saniye bekleyin.");

            // Numara gerçekten personele mi ait? (HBYS personel kartı)
            try
            {
                var personnel = await hbys.GetPersonnelByPhoneAsync(phone, ct);

                if (personnel["present"]?.GetValue<bool>() != true)
                    return ApiResults.Error(StatusCodes.Status404NotFound,
                        "Bu numaraya kayıtlı personel bulunamadı.");
            }
            catch (HbysException e)
            {
                logger.LogError(e, "OTP: personel doğrulaması başarısız.");
                return ApiResults.Error(StatusCodes.Status502BadGateway,
                    "Personel bilgisi doğrulanamadı, lütfen tekrar deneyin.");
            }

            var code = store.Issue(phone);
            var text = $"Hastane Yemekhane dogrulama kodunuz: {code}";

            var result = await sms.SendAsync(phone, text, ct);

            if (!result.Success)
                return ApiResults.Error(StatusCodes.Status502BadGateway, result.Message);

            return Results.Ok(new
            {
                message = "Doğrulama kodu gönderildi.",
                expiresInSeconds = settings.CodeLifetimeSeconds,
            });
        });

        group.MapPost("/verify", (OtpVerifyBody body, OtpStore store) =>
        {
            var phone = NormalizePhone(body.CepTel);

            if (phone is null)
                return ApiResults.Error(StatusCodes.Status400BadRequest,
                    "Geçerli bir cep telefonu girin (10 hane).");

            if (string.IsNullOrWhiteSpace(body.Code) || body.Code.Trim().Length != 6)
                return ApiResults.Error(StatusCodes.Status400BadRequest,
                    "Doğrulama kodu 6 haneli olmalıdır.");

            return store.Verify(phone, body.Code.Trim()) switch
            {
                OtpVerifyResult.Success => Results.Ok(new { verified = true }),
                OtpVerifyResult.NotFound => ApiResults.Error(StatusCodes.Status400BadRequest,
                    "Önce doğrulama kodu isteyin."),
                OtpVerifyResult.Expired => ApiResults.Error(StatusCodes.Status400BadRequest,
                    "Kodun süresi doldu, yeni kod isteyin."),
                OtpVerifyResult.TooManyAttempts => ApiResults.Error(StatusCodes.Status429TooManyRequests,
                    "Çok fazla hatalı deneme. Yeni kod isteyin."),
                _ => ApiResults.Error(StatusCodes.Status400BadRequest, "Doğrulama kodu hatalı."),
            };
        });
    }

    /// <summary>"0555 555 55 11" / "+905555555511" → "5555555511" (son 10 hane).</summary>
    private static string? NormalizePhone(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return null;

        var digits = Regex.Replace(raw, @"\D", string.Empty);

        return digits.Length >= 10 ? digits[^10..] : null;
    }
}
