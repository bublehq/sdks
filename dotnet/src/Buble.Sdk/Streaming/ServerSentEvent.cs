namespace Buble.Sdk.Streaming;

public sealed class ServerSentEvent
{
    public string? Id { get; set; }

    public string? Event { get; set; }

    public string Data { get; set; } = string.Empty;
}
