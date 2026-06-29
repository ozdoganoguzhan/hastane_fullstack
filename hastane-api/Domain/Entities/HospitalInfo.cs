using Ozi.Domain.Shared;

namespace Ozi.Domain.Entities;

/// <summary>
/// Hastane / yemekhane bilgileri (tek satır). Panel'den düzenlenir, mobil "Bilgi"
/// sayfası <c>GET /hospital-info</c> ile okur. Alanlar mobil <c>AppConfig</c> ile eşleşir.
/// </summary>
public class HospitalInfo : EntityBase
{
    public string HospitalName { get; set; } = string.Empty;
    public string Subtitle { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string WorkingHours { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;
    public string Contact { get; set; } = string.Empty;
}
