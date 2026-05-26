using Buble.Sdk.Apps;
using Buble.Sdk.Chat;
using Buble.Sdk.Files;
using Buble.Sdk.Generations;
using Buble.Sdk.Http;
using Buble.Sdk.Media;

namespace Buble.Sdk;

/// <summary>
/// Server-side client for the Buble public API.
/// </summary>
public sealed class BubleClient : IDisposable
{
    public const string DefaultBaseUrl = "https://buble.ai";
    public static readonly TimeSpan DefaultTimeout = TimeSpan.FromSeconds(60);

    private readonly BubleHttpClient _http;
    private readonly bool _disposeHttpClient;

    public BubleClient()
        : this(new BubleClientOptions())
    {
    }

    public BubleClient(string apiKey)
        : this(new BubleClientOptions { ApiKey = apiKey })
    {
    }

    public BubleClient(BubleClientOptions options)
    {
        if (options is null)
        {
            throw new ArgumentNullException(nameof(options));
        }

        var apiKey = FirstNonEmpty(options.ApiKey, Environment.GetEnvironmentVariable("BUBLE_API_KEY"));
        if (string.IsNullOrEmpty(apiKey))
        {
            throw new BubleException("Missing Buble API key. Pass ApiKey or set BUBLE_API_KEY.");
        }

        var baseUrl = FirstNonEmpty(options.BaseUrl, Environment.GetEnvironmentVariable("BUBLE_BASE_URL"), DefaultBaseUrl)!;
        var httpClient = options.HttpClient ?? new HttpClient();
        _disposeHttpClient = options.HttpClient is null;

        _http = new BubleHttpClient(
            apiKey!,
            baseUrl,
            options.Timeout ?? DefaultTimeout,
            httpClient,
            options.Headers);

        MediaModels = new MediaModelsService(_http);
        Files = new FilesService(_http);
        Generations = new GenerationsService(_http);
        Apps = new AppsService(_http);
        Chat = new ChatService(_http);
    }

    public string BaseUrl => _http.BaseUrl;

    public MediaModelsService MediaModels { get; }

    public FilesService Files { get; }

    public GenerationsService Generations { get; }

    public AppsService Apps { get; }

    public ChatService Chat { get; }

    public static BubleClient FromEnv() => new(new BubleClientOptions());

    public void Dispose()
    {
        if (_disposeHttpClient)
        {
            _http.Dispose();
        }
    }

    private static string? FirstNonEmpty(params string?[] values)
    {
        foreach (var value in values)
        {
            if (!string.IsNullOrWhiteSpace(value))
            {
                return value;
            }
        }

        return null;
    }
}
