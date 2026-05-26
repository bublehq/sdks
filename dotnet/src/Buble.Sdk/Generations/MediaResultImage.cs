using System.Text.Json;
using System.Text.Json.Serialization;

namespace Buble.Sdk.Generations;

public sealed class MediaResultImage
{
    [JsonPropertyName("url")]
    public string? Url { get; set; }

    [JsonExtensionData]
    public Dictionary<string, JsonElement>? AdditionalProperties { get; set; }
}
