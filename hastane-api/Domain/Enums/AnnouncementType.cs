namespace Ozi.Domain.Enums;

/// <summary>
/// Duyuru türü. Mobil uygulamadaki <c>AnnouncementType</c> ile birebir
/// (JSON'da camelCase string: important / info / general).
/// </summary>
public enum AnnouncementType
{
    /// Önemli (kırmızı)
    Important = 0,

    /// Bilgi (mavi)
    Info = 1,

    /// Genel (yeşil)
    General = 2
}
