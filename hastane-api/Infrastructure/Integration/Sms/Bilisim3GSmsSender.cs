using System.Text;
using Microsoft.Extensions.Logging;
using Ozi.Application.Infrastructure.Config;

namespace Ozi.Infrastructure.Integration.Sms;

/// <summary>
/// 3G Bilişim SMS gateway istemcisi (tek uç: <c>SendSmsGet.aspx</c>).
///
/// Başarılı yanıt <c>"ID:&lt;mesaj-id&gt;"</c> ile başlar; aksi hâlde gateway
/// bir hata kodu döner ve olduğu gibi yüzeye çıkarılır (uydurma kod eşlemesi
/// yapmıyoruz — gerçek kod loglanır ve mesajda görünür).
/// </summary>
public sealed class Bilisim3GSmsSender(
    IHttpClientFactory httpClientFactory,
    SmsSettings settings,
    ILogger<Bilisim3GSmsSender> logger) : ISmsSender
{
    public const string HttpClientName = "sms-3gbilisim";

    private const string SuccessPrefix = "ID:";

    public async Task<SmsResult> SendAsync(
        string phoneNumber, string content, CancellationToken ct = default)
    {
        if (!settings.Enabled)
        {
            logger.LogWarning(
                "SMS kapalı (Sms:Enabled=false). Gönderilmedi → {Phone}: {Content}",
                phoneNumber, content);
            return SmsResult.Ok("SMS gönderimi kapalı; kod loglandı.");
        }

        if (string.IsNullOrWhiteSpace(settings.Username) ||
            string.IsNullOrWhiteSpace(settings.Password))
        {
            return SmsResult.Fail("SMS servisi kimlik bilgileri eksik (Sms:Username/Password).");
        }

        var url = $"{settings.BaseUrl.TrimEnd('/')}/SendSmsGet.aspx" +
                  $"?user={Uri.EscapeDataString(settings.Username)}" +
                  $"&password={Uri.EscapeDataString(settings.Password)}" +
                  $"&to={Uri.EscapeDataString(phoneNumber)}" +
                  $"&text={Uri.EscapeDataString(content)}" +
                  $"&origin={Uri.EscapeDataString(settings.Originator)}";

        try
        {
            var client = httpClientFactory.CreateClient(HttpClientName);
            using var response = await client.GetAsync(url, ct);
            var body = await ReadBodyAsync(response, ct);

            if (!response.IsSuccessStatusCode)
            {
                logger.LogError("SMS gateway HTTP {Status}: {Body}", (int)response.StatusCode, body);
                return SmsResult.Fail($"SMS servisi yanıt vermedi (HTTP {(int)response.StatusCode}).");
            }

            if (string.IsNullOrWhiteSpace(body))
                return SmsResult.Fail("SMS servisinden boş yanıt alındı.");

            if (body.StartsWith(SuccessPrefix, StringComparison.OrdinalIgnoreCase))
            {
                var messageId = body[SuccessPrefix.Length..].Trim();

                logger.LogInformation("SMS gönderildi → {Phone} (mesaj id: {Id})", phoneNumber, messageId);
                return SmsResult.Ok(messageId);
            }

            logger.LogError("SMS gateway hata kodu döndü → {Phone}: {Body}", phoneNumber, body);
            return SmsResult.Fail($"SMS gönderilemedi (servis yanıtı: {body}).");
        }
        catch (TaskCanceledException)
        {
            logger.LogError("SMS gateway zaman aşımı → {Phone}", phoneNumber);
            return SmsResult.Fail("SMS servisi zaman aşımına uğradı.");
        }
        catch (HttpRequestException e)
        {
            logger.LogError(e, "SMS gateway'e ulaşılamadı → {Phone}", phoneNumber);
            return SmsResult.Fail("SMS servisine ulaşılamadı.");
        }
    }

    /// <summary>
    /// Gateway yanıtını gövde byte'larından çözer.
    ///
    /// ⚠️ 3G Bilişim <c>Content-Type: text/html; charset=ISO-8859-9</c> (Latin-5)
    /// döner. .NET Core bu kod sayfasını yalnızca CodePages sağlayıcısı kayıtlıysa
    /// tanır (bkz. Program.cs). Yine de tanınmazsa UTF-8'e düşeriz — yanıt
    /// pratikte ASCII ("ID:123..." veya hata kodu) olduğu için güvenlidir.
    /// </summary>
    private static async Task<string> ReadBodyAsync(HttpResponseMessage response, CancellationToken ct)
    {
        var bytes = await response.Content.ReadAsByteArrayAsync(ct);
        var charset = response.Content.Headers.ContentType?.CharSet?.Trim('"', ' ');

        var encoding = Encoding.UTF8;
        if (!string.IsNullOrWhiteSpace(charset))
        {
            try
            {
                encoding = Encoding.GetEncoding(charset);
            }
            catch (ArgumentException)
            {
                encoding = Encoding.UTF8;
            }
        }

        return encoding.GetString(bytes).Trim();
    }
}
