namespace Ozi.Domain.Enums;

/// <summary>Desteklenen veritabanı sağlayıcıları. Aktif olan <c>OziAppSettings.Database.DatabaseType</c> ile seçilir.</summary>
public enum DatabaseType
{
    Postgres,
    SqlServer,
    Sqlite,
    MySql
}
