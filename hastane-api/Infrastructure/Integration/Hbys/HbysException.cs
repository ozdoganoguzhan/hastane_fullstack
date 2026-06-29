namespace Ozi.Infrastructure.Integration.Hbys;

/// <summary>HBYS entegrasyonundan dönen hata (auth, "Kayıt bulunamadı", ağ vb.).</summary>
public class HbysException(string message, int upstreamStatus = 502, string? errorCode = null)
    : Exception(message)
{
    public int UpstreamStatus { get; } = upstreamStatus;
    public string? ErrorCode { get; } = errorCode;
}
