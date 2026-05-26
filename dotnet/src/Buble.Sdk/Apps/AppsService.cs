using Buble.Sdk.Http;

namespace Buble.Sdk.Apps;

public sealed class AppsService
{
    private readonly BubleHttpClient _http;

    internal AppsService(BubleHttpClient http)
    {
        _http = http;
        Generations = new AppGenerationsService(http);
    }

    public AppGenerationsService Generations { get; }

    public Task<Envelope<IReadOnlyList<PublicApp>>?> ListAsync(CancellationToken cancellationToken = default)
    {
        return _http.GetAsync<Envelope<IReadOnlyList<PublicApp>>>("/api/v1/apps", cancellationToken: cancellationToken);
    }

    public Task<Envelope<PublicApp>?> RetrieveAsync(string appId, CancellationToken cancellationToken = default)
    {
        return _http.GetAsync<Envelope<PublicApp>>(
            "/api/v1/apps/" + BubleHttpClient.EncodePathSegment(appId),
            cancellationToken: cancellationToken);
    }
}
