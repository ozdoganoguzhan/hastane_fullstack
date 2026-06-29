using Ozi.Application.Common;
using Ozi.Infrastructure.Integration.Hbys;

namespace Ozi.Features.Personnel;

public static class PersonnelEndpoints
{
    public static void MapPersonnelEndpoints(this IEndpointRouteBuilder app)
    {
        // Mobil giriş akışında personel kartı doğrulaması. Gövde HBYS ile birebir:
        // { "data": { adiSoyadi, personelKartNo }, "present": true }
        app.MapGet("/personel", async (string? cepTel, HbysClient hbys, CancellationToken ct) =>
        {
            if (string.IsNullOrWhiteSpace(cepTel))
                return ApiResults.Error(StatusCodes.Status400BadRequest, "cepTel parametresi zorunludur.");

            var data = await hbys.GetPersonnelByPhoneAsync(cepTel.Trim(), ct);
            return Results.Ok(data);
        })
        .WithTags("Personnel");
    }
}
