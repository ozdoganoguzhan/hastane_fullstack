using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Ozi.Application.Common;
using Ozi.Infrastructure.Integration.Hbys;

namespace Ozi.Infrastructure.Web;

/// <summary>İşlenmeyen hataları tutarlı <c>{ message }</c> gövdesine çevirir.</summary>
public sealed class GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext, Exception exception, CancellationToken cancellationToken)
    {
        var (status, message) = exception switch
        {
            HbysException h when h.ErrorCode is null &&
                                 h.Message.Contains("bulunamadı", StringComparison.OrdinalIgnoreCase)
                => (StatusCodes.Status404NotFound, h.Message),
            HbysException h => (StatusCodes.Status502BadGateway, h.Message),
            _ => (StatusCodes.Status500InternalServerError, "Beklenmeyen bir hata oluştu.")
        };

        if (status >= 500)
            logger.LogError(exception, "İşlenmeyen hata: {Message}", exception.Message);
        else
            logger.LogWarning("Ele alınan hata ({Status}): {Message}", status, exception.Message);

        httpContext.Response.StatusCode = status;
        await httpContext.Response.WriteAsJsonAsync(new ErrorResponse(message), cancellationToken);
        return true;
    }
}
