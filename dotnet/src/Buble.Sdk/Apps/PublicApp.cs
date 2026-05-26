using System.Text.Json;
using System.Text.Json.Serialization;

namespace Buble.Sdk.Apps;

public sealed class PublicApp
{
    [JsonPropertyName("id")]
    public string? Id { get; set; }

    [JsonPropertyName("slug")]
    public string? Slug { get; set; }

    [JsonPropertyName("name")]
    public string? Name { get; set; }

    [JsonPropertyName("description")]
    public string? Description { get; set; }

    [JsonPropertyName("input_parameters")]
    public IReadOnlyList<AppInputParameter>? InputParameters { get; set; }

    [JsonExtensionData]
    public Dictionary<string, JsonElement>? AdditionalProperties { get; set; }
}
