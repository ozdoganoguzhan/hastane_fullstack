namespace Ozi.Application.Infrastructure.ApplicationContext;

/// <summary>İstek bağlamı: o anki kullanıcı vb. DbContext denetim alanlarını doldururken kullanılır.</summary>
public interface IApplicationContext
{
    IUserContext? UserContext { get; }
}

public interface IUserContext
{
    CurrentUser User { get; }
}

/// <summary>JWT claim'lerinden çözülen mevcut kullanıcı.</summary>
public sealed class CurrentUser
{
    public Guid? Id { get; init; }
    public string? Username { get; init; }
    public string? Role { get; init; }
}
