using Buble.Sdk.Http;

namespace Buble.Sdk.Media;

public sealed class MediaModelsService
{
    private readonly BubleHttpClient _http;

    internal MediaModelsService(BubleHttpClient http)
    {
        _http = http;
    }

    public Task<Envelope<IReadOnlyList<MediaModel>>?> ListAsync(
        string? mediaType = null,
        CancellationToken cancellationToken = default)
    {
        var options = new RequestOptions();
        if (!string.IsNullOrWhiteSpace(mediaType))
        {
            options.Query["media_type"] = mediaType!;
        }

        return _http.GetAsync<Envelope<IReadOnlyList<MediaModel>>>("/api/v1/media_models", options, cancellationToken);
    }
}
