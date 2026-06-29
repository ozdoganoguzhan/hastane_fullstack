using System.Text.Json;

namespace Ozi.Infrastructure.Integration.Hbys;

/// <summary>
/// HBYS hata zarfını çözümleyen yardımcılar:
/// <c>{ "httpStatus": 555, "exception": { "errorCode", "errorMessage", ... } }</c>.
/// </summary>
public static class HbysResponse
{
    public static HbysException ToException(string body, int httpStatus, string defaultMessage)
    {
        try
        {
            using var doc = JsonDocument.Parse(body);
            var root = doc.RootElement;
            if (root.TryGetProperty("exception", out var ex) && ex.ValueKind == JsonValueKind.Object)
            {
                var code = ex.TryGetProperty("errorCode", out var c) ? c.GetString() : null;
                var msg = ex.TryGetProperty("errorMessage", out var m) ? m.GetString() : null;
                var status = root.TryGetProperty("httpStatus", out var hs) && hs.TryGetInt32(out var s)
                    ? s
                    : httpStatus;
                return new HbysException(msg ?? defaultMessage, status, code);
            }
        }
        catch (JsonException)
        {
            // gövde JSON değil — varsayılan mesaja düş
        }

        return new HbysException(defaultMessage, httpStatus);
    }

    /// <summary>Yanıt token/auth kaynaklı bir hata mı (yeniden login gerekir mi)?</summary>
    public static bool IsAuthError(string body, int httpStatus)
    {
        if (httpStatus is 401 or 403)
            return true;

        try
        {
            using var doc = JsonDocument.Parse(body);
            if (doc.RootElement.TryGetProperty("exception", out var ex) &&
                ex.TryGetProperty("errorCode", out var c) &&
                c.GetString() is { } code)
            {
                return code.StartsWith("AUTH", StringComparison.OrdinalIgnoreCase);
            }
        }
        catch (JsonException)
        {
            // yoksay
        }

        return false;
    }
}
