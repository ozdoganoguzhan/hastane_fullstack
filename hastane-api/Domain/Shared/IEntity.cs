namespace Ozi.Domain.Shared;

/// <summary>Tüm kalıcı varlıkların ortak sözleşmesi (kimlik, soft-delete, denetim, alan olayları).</summary>
public interface IEntity
{
    Guid Id { get; set; }
    bool Deleted { get; set; }
    DateTime CreatedAt { get; set; }
    DateTime? UpdatedAt { get; set; }
    Guid? CreatedBy { get; set; }
    Guid? UpdatedBy { get; set; }

    IReadOnlyCollection<IDomainEvent> DomainEvents { get; }
    void AddDomainEvent(IDomainEvent domainEvent);
    void RemoveDomainEvent(IDomainEvent domainEvent);
    void ClearDomainEvents();
}
