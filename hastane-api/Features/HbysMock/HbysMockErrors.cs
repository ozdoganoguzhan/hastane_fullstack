using System.Text.Json.Nodes;

namespace Ozi.Features.HbysMock;

/// <summary>
/// Turkcell HBYS dokümanındaki hata zarfını birebir üretir:
/// <c>{ "httpStatus": 555, "exception": { errorCode, errorMessage, errorService, trace } }</c>
/// </summary>
public static class HbysMockErrors
{
    public static IResult Envelope(
        string errorCode,
        string errorMessage,
        string errorService = "legacy",
        int httpStatus = 555)
    {
        var body = new JsonObject
        {
            ["httpStatus"] = httpStatus,
            ["exception"] = new JsonObject
            {
                ["errorCode"] = errorCode,
                ["errorMessage"] = errorMessage,
                ["errorService"] = errorService,
                ["trace"] = new JsonArray(),
            },
        };

        return Results.Json(body, statusCode: httpStatus);
    }
}
