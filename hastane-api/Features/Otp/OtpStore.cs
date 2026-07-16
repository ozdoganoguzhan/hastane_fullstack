using System.Collections.Concurrent;
using System.Security.Cryptography;
using Ozi.Application.Infrastructure.Config;

namespace Ozi.Features.Otp;

public enum OtpVerifyResult
{
    Success,
    NotFound,
    Expired,
    TooManyAttempts,
    Invalid,
}

/// <summary>
/// Telefon → doğrulama kodu eşlemesini **bellekte** tutar (veritabanına gitmez).
/// Süre aşımı, hatalı deneme limiti ve tekrar gönderim bekleme süresi uygular.
/// </summary>
public sealed class OtpStore(SmsSettings settings)
{
    private readonly ConcurrentDictionary<string, Entry> _entries = new();

    public TimeSpan Lifetime => TimeSpan.FromSeconds(settings.CodeLifetimeSeconds);

    /// <summary>Yeni kod üretir (öncekini geçersiz kılar).</summary>
    public string Issue(string phone)
    {
        var code = RandomNumberGenerator.GetInt32(100_000, 1_000_000).ToString();

        _entries[phone] = new Entry(code, DateTimeOffset.UtcNow.Add(Lifetime), DateTimeOffset.UtcNow);
        Prune();

        return code;
    }

    /// <summary>Tekrar gönderim için beklenmesi gereken süre (yoksa <c>null</c>).</summary>
    public TimeSpan? CooldownRemaining(string phone)
    {
        if (!_entries.TryGetValue(phone, out var entry)) return null;

        var elapsed = DateTimeOffset.UtcNow - entry.IssuedAt;
        var cooldown = TimeSpan.FromSeconds(settings.ResendCooldownSeconds);

        return elapsed < cooldown ? cooldown - elapsed : null;
    }

    public OtpVerifyResult Verify(string phone, string code)
    {
        if (!_entries.TryGetValue(phone, out var entry))
            return OtpVerifyResult.NotFound;

        if (DateTimeOffset.UtcNow > entry.ExpiresAt)
        {
            _entries.TryRemove(phone, out _);
            return OtpVerifyResult.Expired;
        }

        if (entry.Attempts >= settings.MaxAttempts)
        {
            _entries.TryRemove(phone, out _);
            return OtpVerifyResult.TooManyAttempts;
        }

        if (!CryptographicOperations.FixedTimeEquals(
                System.Text.Encoding.UTF8.GetBytes(entry.Code),
                System.Text.Encoding.UTF8.GetBytes(code)))
        {
            entry.Attempts++;
            return OtpVerifyResult.Invalid;
        }

        _entries.TryRemove(phone, out _); // tek kullanımlık
        return OtpVerifyResult.Success;
    }

    private void Prune()
    {
        var now = DateTimeOffset.UtcNow;

        foreach (var pair in _entries)
        {
            if (now > pair.Value.ExpiresAt) _entries.TryRemove(pair.Key, out _);
        }
    }

    private sealed class Entry(string code, DateTimeOffset expiresAt, DateTimeOffset issuedAt)
    {
        public string Code { get; } = code;
        public DateTimeOffset ExpiresAt { get; } = expiresAt;
        public DateTimeOffset IssuedAt { get; } = issuedAt;
        public int Attempts { get; set; }
    }
}
