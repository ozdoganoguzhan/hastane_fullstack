using Ozi.Domain.Shared;

namespace Ozi.Domain.Events;

/// <summary>Bir duyuru yayınlandığında tetiklenir (örn. push bildirimi, log, cache temizleme).</summary>
public sealed record AnnouncementPublishedDomainEvent(Guid AnnouncementId, string Title) : IDomainEvent;
