using System.Text.Json;
using System.Text.Json.Serialization;

namespace Buble.Sdk.Chat;

public sealed class ChatModel
{
    [JsonPropertyName("id")]
    public string? Id { get; set; }

    [JsonPropertyName("object")]
    public string? Object { get; set; }

    [JsonExtensionData]
    public Dictionary<string, JsonElement>? AdditionalProperties { get; set; }
}
