using System.Security.Claims;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.JsonWebTokens;
using Ozi.Application.Common;
using Ozi.Domain.Entities;
using Ozi.Infrastructure.Data.Context;
using Ozi.Infrastructure.Security;

namespace Ozi.Features.Auth;

public static class AuthEndpoints
{
    public static void MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/auth").WithTags("Auth");

        group.MapPost("/login", async (
            LoginRequest request,
            AppDbContext db,
            IPasswordHasher<AdminUser> hasher,
            JwtTokenService jwt,
            CancellationToken ct) =>
        {
            if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
                return ApiResults.Error(StatusCodes.Status400BadRequest, "Kullanıcı adı ve şifre zorunludur.");

            var user = await db.AdminUsers.FirstOrDefaultAsync(u => u.Username == request.Username, ct);

            var verification = user is null
                ? PasswordVerificationResult.Failed
                : hasher.VerifyHashedPassword(user, user.PasswordHash, request.Password);

            if (user is null || verification == PasswordVerificationResult.Failed)
                return ApiResults.Error(StatusCodes.Status401Unauthorized, "Kullanıcı adı veya şifre hatalı.");

            if (verification == PasswordVerificationResult.SuccessRehashNeeded)
                user.PasswordHash = hasher.HashPassword(user, request.Password);

            user.LastLoginAt = DateTime.Now;
            await db.SaveChangesAsync(ct);

            var (token, expiresAt) = jwt.Create(user);
            return Results.Ok(new LoginResponse(
                token, expiresAt, new UserDto(user.Username, user.DisplayName, user.Role)));
        });

        group.MapGet("/me", (ClaimsPrincipal principal) =>
        {
            var username = principal.FindFirstValue(JwtRegisteredClaimNames.UniqueName) ?? string.Empty;
            var displayName = principal.FindFirstValue("displayName") ?? string.Empty;
            var role = principal.FindFirstValue(ClaimTypes.Role) ?? "admin";
            return Results.Ok(new UserDto(username, displayName, role));
        })
        .RequireAuthorization();
    }
}
