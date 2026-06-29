using Ozi.Domain.Enums;

namespace Ozi.Features.Announcements;

/// <summary>Panel için tam duyuru gösterimi.</summary>
public record AnnouncementDto(
    Guid Id,
    AnnouncementType Type,
    string Title,
    string Body,
    bool IsPublished,
    DateTime PublishDate,
    DateTime CreatedAt,
    DateTime? UpdatedAt);

/// <summary>Mobil uygulamaya dönen sade duyuru (yayınlanmış olanlar).</summary>
public record PublicAnnouncementDto(
    Guid Id,
    AnnouncementType Type,
    string Title,
    string Body,
    DateTime Date);

/// <summary>Duyuru oluşturma/güncelleme isteği.</summary>
public record SaveAnnouncementRequest(
    AnnouncementType Type,
    string Title,
    string Body,
    bool IsPublished,
    DateTime? PublishDate);
