using Ozi.Domain.Shared;

namespace Ozi.Application.EventHandling;

/// <summary>Alan olaylarını ilgili işleyicilere (handler) dağıtır.</summary>
public interface IDomainEventDispatcher
{
    Task DispatchAsync(IReadOnlyCollection<IDomainEvent> domainEvents, CancellationToken cancellationToken = default);
}

/// <summary>Belirli bir alan olayı türünü işleyen bileşen.</summary>
public interface IDomainEventHandler<in TEvent> where TEvent : IDomainEvent
{
    Task HandleAsync(TEvent domainEvent, CancellationToken cancellationToken = default);
}
