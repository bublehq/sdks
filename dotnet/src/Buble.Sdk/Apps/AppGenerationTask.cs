using Buble.Sdk.Generations;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Buble.Sdk.Apps;

public sealed class AppGenerationTask
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

    internal GenerationTask ToGenerationTask()
    {
        return new GenerationTask
        {
            Id = Id,
            Status = Status,
            Result = Result,
            Error = Error
        };
    }
}
