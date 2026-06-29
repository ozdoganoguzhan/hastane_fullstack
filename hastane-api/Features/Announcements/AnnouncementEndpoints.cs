using Microsoft.EntityFrameworkCore;
using Ozi.Application.Common;
using Ozi.Domain.Entities;
using Ozi.Infrastructure.Data.Context;

namespace Ozi.Features.Announcements;

public static class AnnouncementEndpoints
{
    public static void MapAnnouncementEndpoints(this IEndpointRouteBuilder app)
    {
        // ── Mobil (public): yayınlanmış duyurular ──────────────────────────────
        app.MapGet("/announcements", async (AppDbContext db, CancellationToken ct) =>
        {
            var items = await db.Announcements
                .AsNoTracking()
                .Where(a => a.IsPublished)
                .OrderByDescending(a => a.PublishDate)
                .Select(a => new PublicAnnouncementDto(a.Id, a.Type, a.Title, a.Body, a.PublishDate))
                .ToListAsync(ct);

            return Results.Ok(items);
        })
        .WithTags("Announcements");

        // ── Panel (admin): tam CRUD ────────────────────────────────────────────
        var admin = app.MapGroup("/admin/announcements")
            .RequireAuthorization()
            .WithTags("Announcements (Admin)");

        admin.MapGet("", async (int? page, int? pageSize, AppDbContext db, CancellationToken ct) =>
        {
            var currentPage = page is null or < 1 ? 1 : page.Value;
            var size = pageSize is null or < 1 ? 10 : Math.Min(pageSize.Value, 100);

            var query = db.Announcements.AsNoTracking().OrderByDescending(a => a.PublishDate);
            var total = await query.CountAsync(ct);
            var items = await query
                .Skip((currentPage - 1) * size)
                .Take(size)
                .Select(a => Map(a))
                .ToListAsync(ct);

            return Results.Ok(new PagedResult<AnnouncementDto>(items, total, currentPage, size));
        });

        admin.MapGet("/stats", async (AppDbContext db, CancellationToken ct) =>
        {
            var total = await db.Announcements.CountAsync(ct);
            var published = await db.Announcements.CountAsync(a => a.IsPublished, ct);

            return Results.Ok(new { total, published, draft = total - published });
        });

        admin.MapGet("/{id:guid}", async (Guid id, AppDbContext db, CancellationToken ct) =>
        {
            var entity = await db.Announcements.AsNoTracking().FirstOrDefaultAsync(a => a.Id == id, ct);
            return entity is null
                ? ApiResults.Error(StatusCodes.Status404NotFound, "Duyuru bulunamadı.")
                : Results.Ok(Map(entity));
        });

        admin.MapPost("", async (SaveAnnouncementRequest request, AppDbContext db, CancellationToken ct) =>
        {
            if (Validate(request) is { } error)
                return ApiResults.Error(StatusCodes.Status400BadRequest, error);

            var entity = Announcement.Create(
                request.Type, request.Title.Trim(), request.Body.Trim(),
                request.IsPublished, request.PublishDate ?? DateTime.Now);

            db.Announcements.Add(entity);
            await db.SaveChangesAsync(ct);

            return Results.Created($"/admin/announcements/{entity.Id}", Map(entity));
        });

        admin.MapPut("/{id:guid}", async (Guid id, SaveAnnouncementRequest request, AppDbContext db, CancellationToken ct) =>
        {
            if (Validate(request) is { } error)
                return ApiResults.Error(StatusCodes.Status400BadRequest, error);

            var entity = await db.Announcements.FirstOrDefaultAsync(a => a.Id == id, ct);
            if (entity is null)
                return ApiResults.Error(StatusCodes.Status404NotFound, "Duyuru bulunamadı.");

            entity.Update(
                request.Type, request.Title.Trim(), request.Body.Trim(),
                request.IsPublished, request.PublishDate ?? entity.PublishDate);

            await db.SaveChangesAsync(ct);
            return Results.Ok(Map(entity));
        });

        admin.MapDelete("/{id:guid}", async (Guid id, AppDbContext db, CancellationToken ct) =>
        {
            var entity = await db.Announcements.FirstOrDefaultAsync(a => a.Id == id, ct);
            if (entity is null)
                return ApiResults.Error(StatusCodes.Status404NotFound, "Duyuru bulunamadı.");

            db.Announcements.Remove(entity); // SaveChanges içinde soft-delete'e çevrilir
            await db.SaveChangesAsync(ct);
            return Results.NoContent();
        });
    }

    private static AnnouncementDto Map(Announcement a) =>
        new(a.Id, a.Type, a.Title, a.Body, a.IsPublished, a.PublishDate, a.CreatedAt, a.UpdatedAt);

    private static string? Validate(SaveAnnouncementRequest r)
    {
        if (string.IsNullOrWhiteSpace(r.Title))
            return "Başlık zorunludur.";
        if (r.Title.Length > 200)
            return "Başlık en fazla 200 karakter olabilir.";
        if (string.IsNullOrWhiteSpace(r.Body))
            return "İçerik zorunludur.";
        if (r.Body.Length > 4000)
            return "İçerik en fazla 4000 karakter olabilir.";
        return null;
    }
}
