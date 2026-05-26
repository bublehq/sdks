using System.Text.Json.Serialization;

namespace Buble.Sdk.Generations;

public sealed class CreateGenerationRequest
{
    private static readonly ISet<string> ForbiddenFields = new HashSet<string>(StringComparer.Ordinal)
    {
        "input",
        "options",
        "scene",
        "sub_mode_id",
        "subModeId",
        "provider",
        "mediaType",
        "media_type",
        "images",
        "image_input",
        "video_input",
        "audio_input"
    };

    public string? Model { get; set; }

    public string? Mode { get; set; }

    public string? Prompt { get; set; }

    public IReadOnlyList<string>? ImageUrls { get; set; }

    public string? StartFrame { get; set; }

    public string? EndFrame { get; set; }

    public IReadOnlyList<string>? VideoUrls { get; set; }

    public IReadOnlyList<string>? AudioUrls { get; set; }

    public bool? IsPublic { get; set; }

    public bool? CopyProtected { get; set; }

    [JsonIgnore]
    public IDictionary<string, object?> Params { get; } = new Dictionary<string, object?>(StringComparer.Ordinal);

    public IDictionary<string, object?> ToRequestBody()
    {
        var body = new Dictionary<string, object?>(StringComparer.Ordinal);
        Put(body, "model", Model);
        Put(body, "mode", Mode);
        Put(body, "prompt", Prompt);
        Put(body, "image_urls", ImageUrls);
        Put(body, "start_frame", StartFrame);
        Put(body, "end_frame", EndFrame);
        Put(body, "video_urls", VideoUrls);
        Put(body, "audio_urls", AudioUrls);
        Put(body, "is_public", IsPublic);
        Put(body, "copy_protected", CopyProtected);

        foreach (var entry in Params)
        {
            if (entry.Value is null)
            {
                continue;
            }

            if (ForbiddenFields.Contains(entry.Key))
            {
                throw new UnsupportedGenerationFieldException(entry.Key);
            }

            body[entry.Key] = entry.Value;
        }

        foreach (var key in body.Keys)
        {
            if (ForbiddenFields.Contains(key))
            {
                throw new UnsupportedGenerationFieldException(key);
            }
        }

        return body;
    }

    public CreateGenerationRequest WithParam(string key, object? value)
    {
        if (ForbiddenFields.Contains(key))
        {
            throw new UnsupportedGenerationFieldException(key);
        }

        Params[key] = value;
        return this;
    }

    private static void Put(IDictionary<string, object?> body, string key, object? value)
    {
        switch (value)
        {
            case null:
                return;
            case string text when string.IsNullOrEmpty(text):
                return;
            case System.Collections.ICollection collection when collection.Count == 0:
                return;
            default:
                body[key] = value;
                return;
        }
    }
}
