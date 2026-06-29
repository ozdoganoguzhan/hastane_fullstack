using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

namespace Ozi.Infrastructure.Data.Converters;

/// <summary>
/// Tüm DateTime sütunlarını UTC olarak saklar ve UTC olarak okur. PostgreSQL
/// <c>timestamptz</c> tipinin UTC zorunluluğunu karşılar (Npgsql uyumu).
/// </summary>
public sealed class UtcDateTimeConverter() : ValueConverter<DateTime, DateTime>(
    toProvider => toProvider.Kind == DateTimeKind.Utc ? toProvider : toProvider.ToUniversalTime(),
    fromProvider => DateTime.SpecifyKind(fromProvider, DateTimeKind.Utc));
