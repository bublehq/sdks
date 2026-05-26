namespace Buble.Sdk;

/// <summary>
/// Optional headers and query string values for a single request.
/// </summary>
public sealed class RequestOptions
{
    public IDictionary<string, string> Headers { get; } = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

    public IDictionary<string, string> Query { get; } = new Dictionary<string, string>(StringComparer.Ordinal);

    public static RequestOptions None => new();
}
