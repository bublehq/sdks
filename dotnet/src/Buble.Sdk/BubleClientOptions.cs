namespace Buble.Sdk;

/// <summary>
/// Configuration used to create a <see cref="BubleClient"/>.
/// </summary>
public sealed class BubleClientOptions
{
    /// <summary>
    /// Buble API key. When omitted, the client reads BUBLE_API_KEY.
    /// </summary>
    public string? ApiKey { get; set; }

    /// <summary>
    /// API base URL. Defaults to https://buble.ai, or BUBLE_BASE_URL when set.
    /// </summary>
    public string? BaseUrl { get; set; }

    /// <summary>
    /// Request timeout. Defaults to 60 seconds.
    /// </summary>
    public TimeSpan? Timeout { get; set; }

    /// <summary>
    /// Optional externally managed HTTP client.
    /// </summary>
    public HttpClient? HttpClient { get; set; }

    /// <summary>
    /// Extra headers applied to every request. Per-request headers override these.
    /// </summary>
    public IDictionary<string, string> Headers { get; } = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
}
