using System.Text.Json;
using System.Text.Json.Nodes;

namespace Buble.Sdk.Chat;

internal static class JsonPayload
{
    internal static JsonObject FromDictionary(IDictionary<string, object?> body)
    {
        var node = JsonSerializer.SerializeToNode(body, BubleJson.Options) as JsonObject;
        return node ?? new JsonObject();
    }

    internal static JsonObject Copy(JsonObject body)
    {
        return JsonNode.Parse(body.ToJsonString(BubleJson.Options))?.AsObject() ?? new JsonObject();
    }
}
