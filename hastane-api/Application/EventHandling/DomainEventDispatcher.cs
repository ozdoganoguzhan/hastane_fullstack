using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Ozi.Domain.Shared;

namespace Ozi.Application.EventHandling;

/// <summary>
/// Kayıtlı <see cref="IDomainEventHandler{TEvent}"/> bileşenlerini DI üzerinden bulup çalıştırır.
/// Handler yoksa olayı yalnızca loglar (hafif, bağımlılıksız in-process mediator).
/// </summary>
public sealed class DomainEventDispatcher(
    IServiceProvider serviceProvider,
    ILogger<DomainEventDispatcher> logger) : IDomainEventDispatcher
{
    public async Task DispatchAsync(
        IReadOnlyCollection<IDomainEvent> domainEvents, CancellationToken cancellationToken = default)
    {
        foreach (var domainEvent in domainEvents)
        {
            var eventType = domainEvent.GetType();
            logger.LogInformation("Alan olayı işleniyor: {Event}", eventType.Name);

            var handlerType = typeof(IDomainEventHandler<>).MakeGenericType(eventType);
            var method = handlerType.GetMethod(nameof(IDomainEventHandler<IDomainEvent>.HandleAsync));

            foreach (var handler in serviceProvider.GetServices(handlerType))
            {
                if (handler is null || method is null)
                    continue;

                if (method.Invoke(handler, [domainEvent, cancellationToken]) is Task task)
                    await task;
            }
        }
    }
}
