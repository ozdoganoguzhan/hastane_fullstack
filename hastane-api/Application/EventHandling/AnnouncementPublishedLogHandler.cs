using Microsoft.Extensions.Logging;
using Ozi.Domain.Events;

namespace Ozi.Application.EventHandling;

/// <summary>
/// Duyuru yayınlandığında çalışan örnek handler. Şimdilik loglar; ileride buradan
/// push bildirimi / e-posta / cache invalidation tetiklenebilir.
/// </summary>
public sealed class AnnouncementPublishedLogHandler(ILogger<AnnouncementPublishedLogHandler> logger)
    : IDomainEventHandler<AnnouncementPublishedDomainEvent>
{
    public Task HandleAsync(AnnouncementPublishedDomainEvent domainEvent, CancellationToken cancellationToken = default)
    {
        logger.LogInformation(
            "Duyuru yayınlandı: '{Title}' ({Id}).", domainEvent.Title, domainEvent.AnnouncementId);
        return Task.CompletedTask;
    }
}
