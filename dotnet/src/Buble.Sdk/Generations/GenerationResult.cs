using System.Text.Json;
using System.Text.Json.Serialization;

namespace Buble.Sdk.Generations;

public sealed class GenerationResult
{
    [JsonPropertyName("images")]
    public IReadOnlyList<MediaResultImage>? Images { get; set; }

    [JsonPropertyName("videos")]
    public IReadOnlyList<MediaResultVideo>? Videos { get; set; }

    [JsonPropertyName("audios")]
    public IReadOnlyList<MediaResultAudio>? Audios { get; set; }

    [JsonExtensionData]
    public Dictionary<string, JsonElement>? AdditionalProperties { get; set; }
}
