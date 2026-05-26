using System.Text.Json;

namespace Buble.Sdk;

internal static class BubleJson
{
    internal static readonly JsonSerializerOptions Options = new(JsonSerializerDefaults.Web)
    {
        DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull,
        PropertyNameCaseInsensitive = true
    };
}
