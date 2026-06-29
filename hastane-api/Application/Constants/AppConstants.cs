using Ozi.Domain.Shared;

namespace Ozi.Application.Constants;

/// <summary>DbContext konvansiyonlarının (varlık keşfi, tablo adlandırma) kullandığı sabitler.</summary>
public static class AppConstants
{
    public static readonly Type BaseEntityType = typeof(EntityBase);
    public const string BaseEntityTypeName = nameof(EntityBase);
    public static readonly Type EntityIdType = typeof(Guid);
    public static readonly Type BaseValueObjectType = typeof(BaseValueObject);
    public const string BaseValueObjectName = nameof(BaseValueObject);
}

public static class ConfigurationConstants
{
    /// <summary>MaxLength belirtilmeyen string sütunlar için varsayılan uzunluk.</summary>
    public const int DefaultStringMaxLength = 256;
}
