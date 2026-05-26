using System.Text.Json;
using System.Text.Json.Serialization;

namespace Buble.Sdk.Chat;

public sealed class ChatModelList
{
    [JsonPropertyName("object")]
    public string? Object { get; set; }

    [JsonPropertyName("data")]
    public IReadOnlyList<ChatModel>? Data { get; set; }

    [JsonExtensionData]
    public Dictionary<string, JsonElement>? AdditionalProperties { get; set; }
}
