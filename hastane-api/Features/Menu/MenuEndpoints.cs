using Ozi.Application.Common;
using Ozi.Infrastructure.Integration.Hbys;

namespace Ozi.Features.Menu;

public static class MenuEndpoints
{
    public static void MapMenuEndpoints(this IEndpointRouteBuilder app)
    {
        // Mobil uygulama buradan aylık menüyü çeker. Gövde HBYS ile birebir:
        // { "data": [ { id, yil, ay, tarih, kahvaltiY1Adi, ... } ] }
        app.MapGet("/menu/aylik", async (int? yil, int? ay, HbysClient hbys, CancellationToken ct) =>
        {
            var year = yil ?? DateTime.Now.Year;
            var month = ay ?? DateTime.Now.Month;

            if (month is < 1 or > 12)
                return ApiResults.Error(StatusCodes.Status400BadRequest, "Geçersiz ay. 1-12 arasında olmalıdır.");
            if (year is < 2000 or > 2100)
                return ApiResults.Error(StatusCodes.Status400BadRequest, "Geçersiz yıl.");

            var data = await hbys.GetMonthlyMenuAsync(year, month, ct);
            return Results.Ok(data);
        })
        .WithTags("Menu");
    }
}
