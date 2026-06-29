using Ozi.Domain.Enums;
using Ozi.Domain.Events;
using Ozi.Domain.Shared;

namespace Ozi.Domain.Entities;

/// <summary>
/// Yemekhane duyurusu. Panel'den girilir; mobil uygulama yayınlanmış olanları
/// <c>GET /announcements</c> ile çeker.
/// </summary>
public class Announcement : EntityBase
{
    public string Title { get; set; } = string.Empty;

    public string Body { get; set; } = string.Empty;

    public AnnouncementType Type { get; set; } = AnnouncementType.Info;

    /// <summary>Yayınlanmamış duyurular mobil listede görünmez.</summary>
    public bool IsPublished { get; set; } = true;

    /// <summary>Mobil uygulamada gösterilen duyuru tarihi.</summary>
    public DateTime PublishDate { get; set; }

    /// <summary>Yeni duyuru oluşturur; yayınlıysa alan olayı (domain event) üretir.</summary>
    public static Announcement Create(
        AnnouncementType type, string title, string body, bool isPublished, DateTime publishDate)
    {
        var announcement = new Announcement
        {
            Type = type,
            Title = title,
            Body = body,
            IsPublished = isPublished,
            PublishDate = publishDate
        };

        if (isPublished)
            announcement.AddDomainEvent(new AnnouncementPublishedDomainEvent(announcement.Id, title));

        return announcement;
    }

    /// <summary>Alanları günceller; yayın durumu kapalıdan açığa geçerse olay üretir.</summary>
    public void Update(AnnouncementType type, string title, string body, bool isPublished, DateTime publishDate)
    {
        var newlyPublished = isPublished && !IsPublished;

        Type = type;
        Title = title;
        Body = body;
        IsPublished = isPublished;
        PublishDate = publishDate;

        if (newlyPublished)
            AddDomainEvent(new AnnouncementPublishedDomainEvent(Id, title));
    }
}
