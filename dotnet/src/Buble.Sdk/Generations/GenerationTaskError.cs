using System.Text.Json;
using System.Text.Json.Serialization;

namespace Buble.Sdk.Generations;

public sealed class GenerationTaskError
{
    [JsonPropertyName("code")]
    public string? Code { get; set; }

    [JsonPropertyName("message")]
    public string? Message { get; set; }

    [JsonExtensionData]
    public Dictionary<string, JsonElement>? AdditionalProperties { get; set; }
}
