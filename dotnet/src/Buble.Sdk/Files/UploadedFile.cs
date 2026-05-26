using System.Text.Json;
using System.Text.Json.Serialization;

namespace Buble.Sdk.Files;

public sealed class UploadedFile
{
    [JsonPropertyName("id")]
    public string? Id { get; set; }

    [JsonPropertyName("url")]
    public string? Url { get; set; }

    [JsonPropertyName("file_type")]
    public string? FileType { get; set; }

    [JsonExtensionData]
    public Dictionary<string, JsonElement>? AdditionalProperties { get; set; }
}
