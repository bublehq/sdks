using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace Buble.Sdk.Http;

internal sealed class BubleHttpClient : IDisposable
{
    private readonly string _apiKey;
    private readonly TimeSpan _timeout;
    private readonly HttpClient _httpClient;
    private readonly IReadOnlyDictionary<string, string> _headers;

    internal BubleHttpClient(
        string apiKey,
        string baseUrl,
        TimeSpan timeout,
        HttpClient httpClient,
        IDictionary<string, string> headers)
    {
        _apiKey = apiKey;
        BaseUrl = TrimTrailingSlash(baseUrl);
        _timeout = timeout;
        _httpClient = httpClient;
        _headers = new Dictionary<string, string>(headers, StringComparer.OrdinalIgnoreCase);
    }

    internal string BaseUrl { get; }

    internal Task<T?> GetAsync<T>(string path, RequestOptions? options = null, CancellationToken cancellationToken = default)
    {
        return SendJsonAsync<T>(HttpMethod.Get, path, null, options, cancellationToken);
    }

    internal Task<T?> PostAsync<T>(string path, object? body, RequestOptions? options = null, CancellationToken cancellationToken = default)
    {
        return SendJsonAsync<T>(HttpMethod.Post, path, body, options, cancellationToken);
    }

    internal async Task<T?> MultipartAsync<T>(
        string path,
        MultipartFormDataContent body,
        RequestOptions? options = null,
        CancellationToken cancellationToken = default)
    {
        using var request = CreateRequest(HttpMethod.Post, path, options);
        request.Content = body;
        using var response = await SendAsync(request, HttpCompletionOption.ResponseContentRead, cancellationToken).ConfigureAwait(false);
        return await ParseSuccessfulAsync<T>(response).ConfigureAwait(false);
    }

    internal async IAsyncEnumerable<string> StreamLinesAsync(
        string path,
        object? body,
        RequestOptions? options = null,
        [System.Runtime.CompilerServices.EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        using var request = CreateRequest(HttpMethod.Post, path, options);
        var json = JsonSerializer.Serialize(body ?? new Dictionary<string, object?>(), BubleJson.Options);
        request.Content = new StringContent(json, Encoding.UTF8, "application/json");
        request.Headers.Accept.Clear();
        request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("text/event-stream"));

        using var response = await SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancellationToken).ConfigureAwait(false);
        var stream = await response.Content.ReadAsStreamAsync().ConfigureAwait(false);
        using var reader = new StreamReader(stream, Encoding.UTF8);

        while (!reader.EndOfStream)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var line = await reader.ReadLineAsync().ConfigureAwait(false);
            if (line is not null)
            {
                yield return line;
            }
        }
    }

    internal static string EncodePathSegment(string value) => Uri.EscapeDataString(value);

    internal static string EncodeModelPath(string model)
    {
        return string.Join("/", model.Split('/').Select(Uri.EscapeDataString));
    }

    private async Task<T?> SendJsonAsync<T>(
        HttpMethod method,
        string path,
        object? body,
        RequestOptions? options,
        CancellationToken cancellationToken)
    {
        using var request = CreateRequest(method, path, options);
        if (body is not null)
        {
            var json = JsonSerializer.Serialize(body, BubleJson.Options);
            request.Content = new StringContent(json, Encoding.UTF8, "application/json");
        }

        using var response = await SendAsync(request, HttpCompletionOption.ResponseContentRead, cancellationToken).ConfigureAwait(false);
        return await ParseSuccessfulAsync<T>(response).ConfigureAwait(false);
    }

    private HttpRequestMessage CreateRequest(HttpMethod method, string path, RequestOptions? options)
    {
        var resolved = options ?? RequestOptions.None;
        var request = new HttpRequestMessage(method, Resolve(path, resolved.Query));
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _apiKey);
        request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

        foreach (var header in _headers)
        {
            request.Headers.TryAddWithoutValidation(header.Key, header.Value);
        }

        foreach (var header in resolved.Headers)
        {
            request.Headers.Remove(header.Key);
            request.Headers.TryAddWithoutValidation(header.Key, header.Value);
        }

        return request;
    }

    private async Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        HttpCompletionOption completionOption,
        CancellationToken cancellationToken)
    {
        using var timeoutCts = new CancellationTokenSource(_timeout);
        using var linkedCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, timeoutCts.Token);

        try
        {
            var response = await _httpClient.SendAsync(request, completionOption, linkedCts.Token).ConfigureAwait(false);
            if (!response.IsSuccessStatusCode)
            {
                var body = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                response.Dispose();
                throw CreateApiException((int)response.StatusCode, body);
            }

            return response;
        }
        catch (TaskCanceledException ex) when (!cancellationToken.IsCancellationRequested)
        {
            throw new BubleTimeoutException($"Buble API request timed out after {_timeout}.", _timeout, ex);
        }
    }

    private static async Task<T?> ParseSuccessfulAsync<T>(HttpResponseMessage response)
    {
        if (response.StatusCode == HttpStatusCode.NoContent)
        {
            return default;
        }

        var body = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
        if (string.IsNullOrWhiteSpace(body))
        {
            return default;
        }

        try
        {
            return JsonSerializer.Deserialize<T>(body, BubleJson.Options);
        }
        catch (JsonException ex)
        {
            throw new BubleException("Failed to parse Buble API response.", ex);
        }
    }

    private static BubleApiException CreateApiException(int statusCode, string? responseBody)
    {
        var message = string.IsNullOrWhiteSpace(responseBody)
            ? $"Buble API request failed with status {statusCode}."
            : responseBody!;
        string? code = null;
        JsonNode? details = null;

        try
        {
            var root = JsonNode.Parse(responseBody ?? string.Empty);
            var error = root?["error"];
            if (error is not null)
            {
                message = error["message"]?.GetValue<string>() ?? message;
                code = error["code"]?.GetValue<string>();
                details = error["details"];
            }
        }
        catch (Exception)
        {
            // Use the raw body when the server did not return structured JSON.
        }

        return new BubleApiException(statusCode, code, message, details, responseBody);
    }

    private Uri Resolve(string path, IDictionary<string, string> query)
    {
        var normalizedPath = path.StartsWith("/", StringComparison.Ordinal) ? path : "/" + path;
        var builder = new StringBuilder(BaseUrl).Append(normalizedPath);
        var hasQuery = normalizedPath.IndexOf("?", StringComparison.Ordinal) >= 0;

        foreach (var entry in query)
        {
            builder.Append(hasQuery ? '&' : '?');
            hasQuery = true;
            builder.Append(Uri.EscapeDataString(entry.Key));
            builder.Append('=');
            builder.Append(Uri.EscapeDataString(entry.Value));
        }

        return new Uri(builder.ToString(), UriKind.Absolute);
    }

    private static string TrimTrailingSlash(string? value)
    {
        var output = string.IsNullOrWhiteSpace(value) ? BubleClient.DefaultBaseUrl : value!;
        while (output.EndsWith("/", StringComparison.Ordinal))
        {
            output = output.Substring(0, output.Length - 1);
        }

        return output;
    }

    public void Dispose()
    {
        _httpClient.Dispose();
    }
}
