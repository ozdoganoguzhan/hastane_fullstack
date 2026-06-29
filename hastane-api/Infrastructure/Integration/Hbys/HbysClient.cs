using System.Net.Http.Headers;
using System.Text;
using System.Text.Json.Nodes;
using Microsoft.Extensions.Logging;
using Ozi.Application.Infrastructure.Config;

namespace Ozi.Infrastructure.Integration.Hbys;

/// <summary>
/// Turkcell HBYS Yemekhane servislerine bağlanan tipli istemci (aylık menü + personel kartı).
/// <c>UseMock=true</c> iken örnek veri döner. Yanıtlar HBYS gövdesiyle birebir (proxy) döndürülür.
/// </summary>
public class HbysClient(
    IHttpClientFactory httpClientFactory,
    HbysTokenProvider tokenProvider,
    HbysSettings settings,
    ILogger<HbysClient> logger)
{
    public const string HttpClientName = "hbys";

    /// <summary>Aylık yemek listesi — HBYS <c>{ "data": [ ... ] }</c> gövdesini aynen döner.</summary>
    public async Task<JsonNode> GetMonthlyMenuAsync(int yil, int ay, CancellationToken ct)
    {
        if (settings.UseMock)
            return HbysMockData.MonthlyMenu(yil, ay);

        var url = $"{settings.MenuBaseUrl.TrimEnd('/')}/aylik-yemek-listesi/get-kayit-list";
        var filter = BuildMenuFilter(yil, ay);

        var body = await SendWithAuthAsync(
            () => new HttpRequestMessage(HttpMethod.Get, url)
            {
                Content = new StringContent(filter.ToJsonString(), Encoding.UTF8, "application/json")
            },
            "Aylık menü alınamadı.",
            ct);

        return JsonNode.Parse(body) ?? new JsonObject { ["data"] = new JsonArray() };
    }

    /// <summary>Cep telefonuna göre personel kartı — HBYS gövdesini aynen döner.</summary>
    public async Task<JsonNode> GetPersonnelByPhoneAsync(string cepTel, CancellationToken ct)
    {
        if (settings.UseMock)
            return HbysMockData.Personnel(cepTel);

        var url = $"{settings.PersonnelBaseUrl.TrimEnd('/')}/personel/get-personel-karti-by-cep-tel?cepTel={Uri.EscapeDataString(cepTel)}";

        var body = await SendWithAuthAsync(
            () => new HttpRequestMessage(HttpMethod.Post, url),
            "Personel kartı alınamadı.",
            ct);

        return JsonNode.Parse(body) ?? new JsonObject { ["present"] = false };
    }

    /// <summary>
    /// İsteği Bearer token ile gönderir; token/auth hatası alırsa token'ı yenileyip
    /// bir kez daha dener (doc: "Exception alınırsa entegre-login ile yeni token alın").
    /// </summary>
    private async Task<string> SendWithAuthAsync(
        Func<HttpRequestMessage> requestFactory, string errorMessage, CancellationToken ct)
    {
        var client = httpClientFactory.CreateClient(HttpClientName);

        for (var attempt = 1; attempt <= 2; attempt++)
        {
            var token = await tokenProvider.GetTokenAsync(forceRefresh: attempt == 2, ct);

            using var request = requestFactory();
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

            using var response = await client.SendAsync(request, ct);
            var body = await response.Content.ReadAsStringAsync(ct);

            var isAuthError = HbysResponse.IsAuthError(body, (int)response.StatusCode);

            if (response.IsSuccessStatusCode && !isAuthError)
                return body;

            if (isAuthError && attempt == 1)
            {
                logger.LogWarning("HBYS auth hatası, token yenilenip tekrar denenecek.");
                tokenProvider.Invalidate();
                continue;
            }

            throw HbysResponse.ToException(body, (int)response.StatusCode, errorMessage);
        }

        throw new HbysException(errorMessage, 502);
    }

    private static JsonObject BuildMenuFilter(int yil, int ay) => new()
    {
        ["page"] = 0,
        ["rows"] = 100,
        ["first"] = 0,
        ["sortField"] = "id",
        ["sortOrder"] = 0,
        ["filters"] = new JsonObject
        {
            ["yil"] = new JsonObject { ["value"] = yil, ["type"] = "int", ["matchMode"] = "equals" },
            ["ay"] = new JsonObject { ["value"] = ay, ["type"] = "int", ["matchMode"] = "equals" }
        }
    };
}
