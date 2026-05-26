using Buble.Sdk.Http;
using Buble.Sdk.Streaming;
using System.Text.Json.Nodes;

namespace Buble.Sdk.Chat;

public sealed class GeminiService
{
    private readonly BubleHttpClient _http;

    internal GeminiService(BubleHttpClient http)
    {
        _http = http;
    }

    public Task<JsonObject?> GenerateContentAsync(
        string model,
        JsonObject body,
        CancellationToken cancellationToken = default)
    {
        return _http.PostAsync<JsonObject>(
            "/api/v1beta/models/" + BubleHttpClient.EncodeModelPath(model) + ":generateContent",
            body,
            cancellationToken: cancellationToken);
    }

    public Task<JsonObject?> GenerateContentAsync(
        string model,
        IDictionary<string, object?> body,
        CancellationToken cancellationToken = default)
    {
        return GenerateContentAsync(model, JsonPayload.FromDictionary(body), cancellationToken);
    }

    public IAsyncEnumerable<ServerSentEvent> StreamGenerateContentAsync(
        string model,
        JsonObject body,
        CancellationToken cancellationToken = default)
    {
        return ServerSentEventParser.ParseAsync(
            _http.StreamLinesAsync(
                "/api/v1beta/models/" + BubleHttpClient.EncodeModelPath(model) + ":streamGenerateContent",
                body,
                cancellationToken: cancellationToken),
            cancellationToken);
    }

    public IAsyncEnumerable<string> StreamTextAsync(
        string model,
        JsonObject body,
        CancellationToken cancellationToken = default)
    {
        return StreamText.FromEventsAsync(StreamGenerateContentAsync(model, body, cancellationToken), StreamProtocol.Gemini, cancellationToken);
    }

    public IAsyncEnumerable<ServerSentEvent> StreamGenerateContentAsync(
        string model,
        IDictionary<string, object?> body,
        CancellationToken cancellationToken = default)
    {
        return StreamGenerateContentAsync(model, JsonPayload.FromDictionary(body), cancellationToken);
    }

    public IAsyncEnumerable<string> StreamTextAsync(
        string model,
        IDictionary<string, object?> body,
        CancellationToken cancellationToken = default)
    {
        return StreamTextAsync(model, JsonPayload.FromDictionary(body), cancellationToken);
    }
}
