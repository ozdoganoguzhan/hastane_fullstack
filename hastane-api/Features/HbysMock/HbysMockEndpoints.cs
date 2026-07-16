using System.Text.Json;
using System.Text.Json.Nodes;
using Ozi.Application.Infrastructure.Config;
using Ozi.Infrastructure.Integration.Hbys;

namespace Ozi.Features.HbysMock;

/// <summary>
/// Turkcell HBYS Yemekhane servislerinin **birebir** mock'u (entegrasyon dokümanı v1.0).
/// Veritabanına gitmez; tamamen bellek içi dummy veri üretir.
///
/// Amaç: Turkcell intranet'ine erişemediğimiz sürece mobil uygulama bu mock'a,
/// erişim açıldığında ise TEK BİR CONFIG BOOL'U ile gerçek Turkcell host'larına
/// bağlanır — uygulama kodu değişmez, protokol aynıdır.
///
/// Uçlar (doküman ile aynı yol/gövde/başlık):
///  • POST /auth/entegre-login
///  • GET  /aylik-yemek-listesi/get-kayit-list      (PrimeNG filter gövdesi + Bearer)
///  • POST /personel/get-personel-karti-by-cep-tel  (?cepTel= + Bearer)
/// </summary>
public static class HbysMockEndpoints
{
    public static void MapHbysMockEndpoints(this IEndpointRouteBuilder app)
    {
        // ── 1) ENTEGRE-LOGIN ────────────────────────────────────────────────
        app.MapPost("/auth/entegre-login", (
            EntegreLoginRequest request,
            HbysSettings settings,
            HbysMockTokenStore tokens) =>
        {
            if (!string.Equals(request.Username, settings.Username, StringComparison.Ordinal))
                return HbysMockErrors.Envelope("AUTH-101", "Kullanıcı bulunamadı");

            if (!string.Equals(request.Password, settings.Password, StringComparison.Ordinal))
                return HbysMockErrors.Envelope("AUTH-102", "Kullanıcı adı veya şifre hatalı");

            if (request.OrganizationId != settings.OrganizationId)
                return HbysMockErrors.Envelope("AUTH-103", "Organizasyon bulunamadı");

            var (token, expiresAt) = tokens.Issue();

            return Results.Ok(new JsonObject
            {
                ["name"] = $"TCELL_{request.Username.ToUpperInvariant()}",
                ["access_token"] = token,
                ["expires_in"] = expiresAt,
            });
        })
        .WithTags("HBYS Mock");

        // ── 2) AYLIK-YEMEK-LIST ─────────────────────────────────────────────
        // Doküman GET + filter gövdesi kullanıyor; gövdeyi elle okuyoruz.
        app.MapGet("/aylik-yemek-listesi/get-kayit-list", async (
            HttpContext context,
            HbysMockTokenStore tokens) =>
        {
            if (!IsAuthorized(context, tokens))
                return HbysMockErrors.Envelope("AUTH-101", "Token geçersiz veya süresi dolmuş");

            using var reader = new StreamReader(context.Request.Body);
            var rawBody = await reader.ReadToEndAsync();
            var (yil, ay) = ParseMenuFilter(rawBody);

            if (yil is null || ay is null)
                return HbysMockErrors.Envelope("----", "Kayıt bulunamadı");

            var payload = HbysMockData.MonthlyMenu(yil.Value, ay.Value);

            if (payload["data"] is JsonArray { Count: 0 })
                return HbysMockErrors.Envelope("----", "Kayıt bulunamadı");

            return Results.Ok(payload);
        })
        .WithTags("HBYS Mock");

        // ── 3) GET-PERSONEL-KARTI-BY-CEP-TEL ────────────────────────────────
        app.MapPost("/personel/get-personel-karti-by-cep-tel", (
            string? cepTel,
            HttpContext context,
            HbysMockTokenStore tokens) =>
        {
            if (!IsAuthorized(context, tokens))
                return HbysMockErrors.Envelope("AUTH-101", "Token geçersiz veya süresi dolmuş");

            if (string.IsNullOrWhiteSpace(cepTel))
                return HbysMockErrors.Envelope("----", "Kayıt bulunamadı");

            return Results.Ok(HbysMockData.Personnel(cepTel));
        })
        .WithTags("HBYS Mock");
    }

    private static bool IsAuthorized(HttpContext context, HbysMockTokenStore tokens)
    {
        var header = context.Request.Headers.Authorization.ToString();

        if (!header.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
            return false;

        return tokens.IsValid(header["Bearer ".Length..].Trim());
    }

    /// <summary>PrimeNG filter gövdesinden <c>filters.yil.value</c> / <c>filters.ay.value</c> okur.</summary>
    private static (int? Yil, int? Ay) ParseMenuFilter(string rawBody)
    {
        if (string.IsNullOrWhiteSpace(rawBody))
            return (null, null);

        try
        {
            var filters = JsonNode.Parse(rawBody)?["filters"];

            return (ReadInt(filters?["yil"]?["value"]), ReadInt(filters?["ay"]?["value"]));
        }
        catch (JsonException)
        {
            return (null, null);
        }
    }

    private static int? ReadInt(JsonNode? node)
    {
        if (node is null) return null;

        try
        {
            return node.GetValue<int>();
        }
        catch (InvalidOperationException)
        {
            return int.TryParse(node.ToString(), out var parsed) ? parsed : null;
        }
        catch (FormatException)
        {
            return null;
        }
    }
}

/// <summary>Doküman: <c>{ "username", "password", "organizationId" }</c>.</summary>
public record EntegreLoginRequest(string Username, string Password, int OrganizationId);
