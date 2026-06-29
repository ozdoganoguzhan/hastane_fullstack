using Microsoft.EntityFrameworkCore;
using Ozi.Application.Common;
using Ozi.Infrastructure.Data.Context;
using Entity = Ozi.Domain.Entities.HospitalInfo;

namespace Ozi.Features.HospitalInfo;

public static class HospitalInfoEndpoints
{
    public static void MapHospitalInfoEndpoints(this IEndpointRouteBuilder app)
    {
        // ── Mobil (public): "Bilgi" sayfası ────────────────────────────────────
        app.MapGet("/hospital-info", async (AppDbContext db, CancellationToken ct) =>
        {
            var info = await db.HospitalInfos.AsNoTracking().OrderBy(h => h.CreatedAt).FirstOrDefaultAsync(ct);
            return info is null
                ? ApiResults.Error(StatusCodes.Status404NotFound, "Hastane bilgisi bulunamadı.")
                : Results.Ok(Map(info));
        })
        .WithTags("HospitalInfo");

        // ── Panel (admin): düzenleme ───────────────────────────────────────────
        var admin = app.MapGroup("/admin/hospital-info")
            .RequireAuthorization()
            .WithTags("HospitalInfo (Admin)");

        admin.MapGet("", async (AppDbContext db, CancellationToken ct) =>
        {
            var info = await db.HospitalInfos.AsNoTracking().OrderBy(h => h.CreatedAt).FirstOrDefaultAsync(ct);
            return info is null
                ? ApiResults.Error(StatusCodes.Status404NotFound, "Hastane bilgisi bulunamadı.")
                : Results.Ok(Map(info));
        });

        admin.MapPut("", async (UpdateHospitalInfoRequest request, AppDbContext db, CancellationToken ct) =>
        {
            if (string.IsNullOrWhiteSpace(request.HospitalName))
                return ApiResults.Error(StatusCodes.Status400BadRequest, "Hastane adı zorunludur.");

            var info = await db.HospitalInfos.OrderBy(h => h.CreatedAt).FirstOrDefaultAsync(ct);
            if (info is null)
            {
                info = new Entity();
                db.HospitalInfos.Add(info);
            }

            info.HospitalName = request.HospitalName.Trim();
            info.Subtitle = request.Subtitle?.Trim() ?? string.Empty;
            info.Description = request.Description?.Trim() ?? string.Empty;
            info.WorkingHours = request.WorkingHours?.Trim() ?? string.Empty;
            info.Location = request.Location?.Trim() ?? string.Empty;
            info.Contact = request.Contact?.Trim() ?? string.Empty;

            await db.SaveChangesAsync(ct);
            return Results.Ok(Map(info));
        });
    }

    private static HospitalInfoDto Map(Entity h) =>
        new(h.HospitalName, h.Subtitle, h.Description, h.WorkingHours, h.Location, h.Contact,
            h.UpdatedAt ?? h.CreatedAt);
}
