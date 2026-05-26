using System.Text.Json.Serialization;

namespace Buble.Sdk;

/// <summary>
/// Standard envelope returned by Buble media, file, and app endpoints.
/// </summary>
public sealed class Envelope<T>
{
    [JsonPropertyName("data")]
    public T? Data { get; set; }
}
