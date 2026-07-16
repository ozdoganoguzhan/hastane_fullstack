using System.Collections.Concurrent;
using System.Security.Cryptography;

namespace Ozi.Features.HbysMock;

/// <summary>
/// Mock HBYS Bearer token'larını bellekte tutar (veritabanına gitmez).
/// Doküman: token varsayılan 60 dakika geçerlidir.
/// </summary>
public sealed class HbysMockTokenStore
{
    private const int LifetimeMinutes = 60;

    private readonly ConcurrentDictionary<string, long> _tokens = new();

    /// <summary>Yeni token üretir. Dönen <c>ExpiresAtUnixMs</c> doküman'daki <c>expires_in</c> alanıdır (epoch-ms).</summary>
    public (string Token, long ExpiresAtUnixMs) Issue()
    {
        var token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(48))
            .Replace('+', '-')
            .Replace('/', '_')
            .TrimEnd('=');

        var expiresAt = DateTimeOffset.UtcNow.AddMinutes(LifetimeMinutes).ToUnixTimeMilliseconds();

        _tokens[token] = expiresAt;
        Prune();

        return (token, expiresAt);
    }

    public bool IsValid(string? token) =>
        token is not null
        && _tokens.TryGetValue(token, out var expiresAt)
        && DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() < expiresAt;

    private void Prune()
    {
        var now = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

        foreach (var pair in _tokens)
        {
            if (pair.Value <= now) _tokens.TryRemove(pair.Key, out _);
        }
    }
}
