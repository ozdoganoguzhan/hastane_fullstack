namespace Ozi.Domain.Shared;

/// <summary>Bir aggregate üzerinde gerçekleşen ve yan etkileri tetikleyen alan olayı.</summary>
public interface IDomainEvent
{
    DateTime OccurredOnUtc => DateTime.UtcNow;
}
