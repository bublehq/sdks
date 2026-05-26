using Buble.Sdk.Http;
using Buble.Sdk.Streaming;
using System.Text.Json.Nodes;

namespace Buble.Sdk.Chat;

public sealed class ChatCompletionsService
{
    private readonly BubleHttpClient _http;

    internal ChatCompletionsService(BubleHttpClient http)
    {
        _http = http;
    }

    public Task<JsonObject?> CreateAsync(
        JsonObject body,
        CancellationToken cancellationToken = default)
    {
        var payload = JsonPayload.Copy(body);
        payload["stream"] = false;
        return _http.PostAsync<JsonObject>("/api/v1/chat/completions", payload, cancellationToken: cancellationToken);
    }

    public Task<JsonObject?> CreateAsync(
        IDictionary<string, object?> body,
        CancellationToken cancellationToken = default)
    {
        return CreateAsync(JsonPayload.FromDictionary(body), cancellationToken);
    }

    public IAsyncEnumerable<ServerSentEvent> StreamAsync(
        JsonObject body,
        CancellationToken cancellationToken = default)
    {
        var payload = JsonPayload.Copy(body);
        payload["stream"] = true;
        return ServerSentEventParser.ParseAsync(
            _http.StreamLinesAsync("/api/v1/chat/completions", payload, cancellationToken: cancellationToken),
            cancellationToken);
    }

    public IAsyncEnumerable<ServerSentEvent> StreamAsync(
        IDictionary<string, object?> body,
        CancellationToken cancellationToken = default)
    {
        return StreamAsync(JsonPayload.FromDictionary(body), cancellationToken);
    }

    public IAsyncEnumerable<string> StreamTextAsync(
        JsonObject body,
        CancellationToken cancellationToken = default)
    {
        return StreamText.FromEventsAsync(StreamAsync(body, cancellationToken), StreamProtocol.OpenAI, cancellationToken);
    }

    public IAsyncEnumerable<string> StreamTextAsync(
        IDictionary<string, object?> body,
        CancellationToken cancellationToken = default)
    {
        return StreamTextAsync(JsonPayload.FromDictionary(body), cancellationToken);
    }
}
