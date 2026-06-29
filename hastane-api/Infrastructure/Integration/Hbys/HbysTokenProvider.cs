using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Ozi.Application.Infrastructure.Config;

namespace Ozi.Infrastructure.Integration.Hbys;

/// <summary>
/// HBYS <c>entegre-login</c> Bearer token'ını alır ve önbelleğe alır (~60 dk).
/// Süre dolunca ya da <see cref="Invalidate"/> sonrası yenilenir. Thread-safe.
/// </summary>
public class HbysTokenProvider(
    IHttpClientFactory httpClientFactory,
    HbysSettings settings,
    ILogger<HbysTokenProvider> logger)
{
    private readonly SemaphoreSlim _gate = new(1, 1);

    private string? _token;
    private DateTimeOffset _expiresAt = DateTimeOffset.MinValue;

    public async Task<string> GetTokenAsync(bool forceRefresh = false, CancellationToken ct = default)
    {
        if (!forceRefresh && IsValid())
            return _token!;

        await _gate.WaitAsync(ct);
        try
        {
            if (!forceRefresh && IsValid())
                return _token!;

            await LoginAsync(ct);
            return _token!;
        }
        finally
        {
            _gate.Release();
        }
    }

    public void Invalidate()
    {
        _token = null;
        _expiresAt = DateTimeOffset.MinValue;
    }

    private bool IsValid() =>
        _token is not null && DateTimeOffset.UtcNow < _expiresAt - TimeSpan.FromMinutes(2);

    private async Task LoginAsync(CancellationToken ct)
    {
        var client = httpClientFactory.CreateClient(HbysClient.HttpClientName);
        var url = $"{settings.AuthBaseUrl.TrimEnd('/')}/auth/entegre-login";

        logger.LogInformation("HBYS entegre-login çağrılıyor: {Url}", url);

        using var response = await client.PostAsJsonAsync(url, new
        {
            username = settings.Username,
            password = settings.Password,
            organizationId = settings.OrganizationId
        }, ct);

        var body = await response.Content.ReadAsStringAsync(ct);

        if (!response.IsSuccessStatusCode)
            throw HbysResponse.ToException(body, (int)response.StatusCode, "HBYS girişi başarısız.");

        using var doc = JsonDocument.Parse(body);
        var root = doc.RootElement;

        if (!root.TryGetProperty("access_token", out var tokenEl) ||
            tokenEl.GetString() is not { Length: > 0 } token)
        {
            throw new HbysException("HBYS giriş yanıtında access_token bulunamadı.", 502);
        }

        _token = token;
        _expiresAt = ResolveExpiry(root);
        logger.LogInformation("HBYS token alındı, geçerlilik: {ExpiresAt:u}", _expiresAt);
    }

    /// <summary>
    /// expires_in epoch-ms (örn. 1773779828239) veya string olabilir. Geçerli bir
    /// gelecek zaman çözülemezse varsayılan 55 dakika kullanılır (doc: ~60 dk).
    /// </summary>
    private static DateTimeOffset ResolveExpiry(JsonElement root)
    {
        var fallback = DateTimeOffset.UtcNow.AddMinutes(55);
        if (!root.TryGetProperty("expires_in", out var el))
            return fallback;

        long? epochMs = el.ValueKind switch
        {
            JsonValueKind.Number when el.TryGetInt64(out var n) => n,
            JsonValueKind.String when long.TryParse(el.GetString(), out var n) => n,
            _ => null
        };

        if (epochMs is null or <= 0)
            return fallback;

        var candidate = DateTimeOffset.FromUnixTimeMilliseconds(epochMs.Value);
        return candidate > DateTimeOffset.UtcNow ? candidate : fallback;
    }
}
