using Ozi.Domain.Enums;

namespace Ozi.Application.Infrastructure.Config;

/// <summary>appsettings.json'daki "Ozi" bölümünden bağlanan uygulama ayarları (tek merkez).</summary>
public class OziAppSettings
{
    public const string SectionName = "Ozi";

    public DatabaseSettings Database { get; set; } = new();
    public JwtSettings Jwt { get; set; } = new();
    public HbysSettings Hbys { get; set; } = new();
    public CorsSettings Cors { get; set; } = new();
    public SeedSettings Seed { get; set; } = new();
}

public class DatabaseSettings
{
    public DatabaseType DatabaseType { get; set; } = DatabaseType.Postgres;
    public ConnectionStringSettings ConnectionStrings { get; set; } = new();
}

public class ConnectionStringSettings
{
    public string Postgres { get; set; } = string.Empty;
    public string Sql { get; set; } = string.Empty;
    public string Sqlite { get; set; } = string.Empty;
}

public class JwtSettings
{
    public string Issuer { get; set; } = "ozi-hastane-api";
    public string Audience { get; set; } = "ozi-hastane-panel";

    /// <summary>HS256 imza anahtarı (≥ 32 karakter). Production'da gizli tutulur.</summary>
    public string Key { get; set; } = string.Empty;

    public int ExpiryMinutes { get; set; } = 240;
}

public class HbysSettings
{
    public bool UseMock { get; set; } = true;
    public string AuthBaseUrl { get; set; } = string.Empty;
    public string MenuBaseUrl { get; set; } = string.Empty;
    public string PersonnelBaseUrl { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public int OrganizationId { get; set; }
    public int TimeoutSeconds { get; set; } = 30;
}

public class CorsSettings
{
    public string[] AllowedOrigins { get; set; } = [];
}

public class SeedSettings
{
    public string AdminUsername { get; set; } = "admin";
    public string AdminPassword { get; set; } = "Admin123!";
    public string AdminDisplayName { get; set; } = "Sistem Yöneticisi";
}
