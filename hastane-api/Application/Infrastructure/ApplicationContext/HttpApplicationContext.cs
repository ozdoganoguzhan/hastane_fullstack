using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.IdentityModel.JsonWebTokens;

namespace Ozi.Application.Infrastructure.ApplicationContext;

/// <summary>HTTP isteğindeki JWT'den <see cref="IUserContext"/> üretir.</summary>
public sealed class HttpApplicationContext : IApplicationContext
{
    public HttpApplicationContext(IHttpContextAccessor accessor)
    {
        var principal = accessor.HttpContext?.User;
        if (principal?.Identity?.IsAuthenticated != true)
            return;

        var user = new CurrentUser
        {
            Id = Guid.TryParse(principal.FindFirstValue(JwtRegisteredClaimNames.Sub), out var id) ? id : null,
            Username = principal.FindFirstValue(JwtRegisteredClaimNames.UniqueName),
            Role = principal.FindFirstValue(ClaimTypes.Role)
        };

        UserContext = new HttpUserContext(user);
    }

    public IUserContext? UserContext { get; }

    private sealed class HttpUserContext(CurrentUser user) : IUserContext
    {
        public CurrentUser User { get; } = user;
    }
}
