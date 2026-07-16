namespace Ozi.Infrastructure.Integration.Sms;

/// <summary>SMS gönderim sonucu.</summary>
public record SmsResult(bool Success, string Message)
{
    public static SmsResult Ok(string message) => new(true, message);
    public static SmsResult Fail(string message) => new(false, message);
}

public interface ISmsSender
{
    Task<SmsResult> SendAsync(string phoneNumber, string content, CancellationToken ct = default);
}
