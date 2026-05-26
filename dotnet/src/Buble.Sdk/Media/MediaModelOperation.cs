using System.Text.Json;
using System.Text.Json.Serialization;

namespace Buble.Sdk.Media;

public sealed class MediaModelOperation
{
    [JsonPropertyName("mode")]
    public string? Mode { get; set; }

    [JsonPropertyName("input_requirements")]
    public JsonElement? InputRequirements { get; set; }

    [JsonPropertyName("parameters")]
    public IReadOnlyList<MediaModelParameter>? Parameters { get; set; }

    [JsonExtensionData]
    public Dictionary<string, JsonElement>? AdditionalProperties { get; set; }
}
