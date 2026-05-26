using System.Text.Json;
using System.Text.Json.Serialization;

namespace Buble.Sdk.Media;

public sealed class MediaModelParameter
{
    [JsonPropertyName("name")]
    public string? Name { get; set; }

    [JsonPropertyName("type")]
    public string? Type { get; set; }

    [JsonPropertyName("required")]
    public bool? Required { get; set; }

    [JsonPropertyName("default")]
    public JsonElement? Default { get; set; }

    [JsonExtensionData]
    public Dictionary<string, JsonElement>? AdditionalProperties { get; set; }
}
