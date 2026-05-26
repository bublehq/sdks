using Buble.Sdk.Generations;
using Buble.Sdk.Http;

namespace Buble.Sdk.Apps;

public sealed class AppGenerationsService
{
    private readonly BubleHttpClient _http;

    internal AppGenerationsService(BubleHttpClient http)
    {
        _http = http;
    }

    public Task<Envelope<AppGenerationTask>?> CreateAsync(
        string appId,
        IDictionary<string, object?> parameters,
        CancellationToken cancellationToken = default)
    {
        if (parameters is null)
        {
            throw new ArgumentNullException(nameof(parameters));
        }

        return _http.PostAsync<Envelope<AppGenerationTask>>(
            "/api/v1/apps/" + BubleHttpClient.EncodePathSegment(appId) + "/generations",
            parameters,
            cancellationToken: cancellationToken);
    }

    public Task<Envelope<AppGenerationTask>?> RetrieveAsync(
        string appId,
        string generationId,
        CancellationToken cancellationToken = default)
    {
        return _http.GetAsync<Envelope<AppGenerationTask>>(
            "/api/v1/apps/" + BubleHttpClient.EncodePathSegment(appId) + "/generations/" + BubleHttpClient.EncodePathSegment(generationId),
            cancellationToken: cancellationToken);
    }

    public async Task<Envelope<AppGenerationTask>> WaitAsync(
        string appId,
        string generationId,
        WaitOptions? options = null,
        CancellationToken cancellationToken = default)
    {
        var resolved = options ?? new WaitOptions();
        var deadline = DateTimeOffset.UtcNow.Add(resolved.Timeout);

        while (true)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var envelope = await RetrieveAsync(appId, generationId, cancellationToken).ConfigureAwait(false);
            var task = envelope?.Data;
            if (task is null)
            {
                throw new BubleException("Buble API returned an empty app generation response.");
            }

            if (string.Equals(task.Status, "success", StringComparison.OrdinalIgnoreCase))
            {
                return envelope!;
            }

            if (string.Equals(task.Status, "failed", StringComparison.OrdinalIgnoreCase))
            {
                throw new GenerationFailedException(task.ToGenerationTask());
            }

            if (string.Equals(task.Status, "canceled", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(task.Status, "cancelled", StringComparison.OrdinalIgnoreCase))
            {
                throw new GenerationCanceledException(task.ToGenerationTask());
            }

            if (DateTimeOffset.UtcNow >= deadline)
            {
                throw new BubleTimeoutException($"Timed out waiting for Buble app generation '{generationId}'.", resolved.Timeout);
            }

            await Task.Delay(resolved.Interval, cancellationToken).ConfigureAwait(false);
        }
    }
}
