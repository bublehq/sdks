using System.Text.Json;
using System.Text.Json.Serialization;

namespace Buble.Sdk.Media;

public sealed class MediaModel
{
    [JsonPropertyName("model")]
    public string? Model { get; set; }

    [JsonPropertyName("name")]
    public string? Name { get; set; }

    [JsonPropertyName("media_type")]
    public string? MediaType { get; set; }

    [JsonPropertyName("operations")]
    public IReadOnlyList<MediaModelOperation>? Operations { get; set; }

    [JsonExtensionData]
    public Dictionary<string, JsonElement>? AdditionalProperties { get; set; }
}
