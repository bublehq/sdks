using System.Text.Json;
using System.Text.Json.Serialization;

namespace Buble.Sdk.Generations;

public sealed class GenerationTask
{
    [JsonPropertyName("id")]
    public string? Id { get; set; }

    [JsonPropertyName("status")]
    public string? Status { get; set; }

    [JsonPropertyName("result")]
    public GenerationResult? Result { get; set; }

    [JsonPropertyName("error")]
    public GenerationTaskError? Error { get; set; }

    [JsonExtensionData]
    public Dictionary<string, JsonElement>? AdditionalProperties { get; set; }
}
