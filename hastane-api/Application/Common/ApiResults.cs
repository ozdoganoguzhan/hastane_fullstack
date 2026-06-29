namespace Ozi.Application.Common;

/// <summary>Tutarlı hata gövdesi: <c>{ "message": "..." }</c>.</summary>
public record ErrorResponse(string Message);

public static class ApiResults
{
    public static IResult Error(int status, string message) =>
        Results.Json(new ErrorResponse(message), statusCode: status);
}
