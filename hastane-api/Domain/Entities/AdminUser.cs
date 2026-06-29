using Ozi.Domain.Shared;

namespace Ozi.Domain.Entities;

/// <summary>Panel'e JWT ile giriş yapan yönetici kullanıcı.</summary>
public class AdminUser : EntityBase
{
    public string Username { get; set; } = string.Empty;

    /// <summary>PBKDF2 hash (ASP.NET Core <c>PasswordHasher</c>). Asla düz metin tutulmaz.</summary>
    public string PasswordHash { get; set; } = string.Empty;

    public string DisplayName { get; set; } = string.Empty;

    public string Role { get; set; } = "admin";

    public DateTime? LastLoginAt { get; set; }
}
