namespace Ozi.Application.Common;

/// <summary>Sayfalanmış liste yanıtı.</summary>
public record PagedResult<T>(IReadOnlyList<T> Items, int Total, int Page, int PageSize);
