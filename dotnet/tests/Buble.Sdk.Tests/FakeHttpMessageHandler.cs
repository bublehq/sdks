using System.Net;

namespace Buble.Sdk.Tests;

internal sealed class FakeHttpMessageHandler : HttpMessageHandler
{
    private readonly Queue<Func<HttpRequestMessage, Task<HttpResponseMessage>>> _responses = new();

    internal IReadOnlyList<CapturedRequest> Requests => _requests;

    private readonly List<CapturedRequest> _requests = new();

    internal void EnqueueJson(string json, HttpStatusCode statusCode = HttpStatusCode.OK)
    {
        _responses.Enqueue(_ => Task.FromResult(new HttpResponseMessage(statusCode)
        {
            Content = new StringContent(json)
        }));
    }

    internal void EnqueueSse(string sse)
    {
        _responses.Enqueue(_ => Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent(sse)
        }));
    }

    protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        var body = request.Content is null ? string.Empty : await request.Content.ReadAsStringAsync(cancellationToken);
        _requests.Add(new CapturedRequest(
            request.Method,
            request.RequestUri!,
            request.Headers.Authorization?.ToString(),
            request.Headers.Accept.Select(h => h.MediaType ?? string.Empty).ToArray(),
            body));

        if (_responses.Count == 0)
        {
            return new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent("{}")
            };
        }

        return await _responses.Dequeue()(request);
    }
}

internal sealed record CapturedRequest(
    HttpMethod Method,
    Uri Uri,
    string? Authorization,
    IReadOnlyList<string> Accept,
    string Body);
