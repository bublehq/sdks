using Buble.Sdk.Http;

namespace Buble.Sdk.Generations;

public sealed class GenerationsService
{
    private readonly BubleHttpClient _http;

    internal GenerationsService(BubleHttpClient http)
    {
        _http = http;
    }

    public Task<Envelope<GenerationTask>?> CreateAsync(
        CreateGenerationRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request is null)
        {
            throw new ArgumentNullException(nameof(request));
        }

        return _http.PostAsync<Envelope<GenerationTask>>("/api/v1/generations", request.ToRequestBody(), cancellationToken: cancellationToken);
    }

    public Task<Envelope<GenerationTask>?> RetrieveAsync(
        string generationId,
        CancellationToken cancellationToken = default)
    {
        return _http.GetAsync<Envelope<GenerationTask>>(
            "/api/v1/generations/" + BubleHttpClient.EncodePathSegment(generationId),
            cancellationToken: cancellationToken);
    }

    public async Task<Envelope<GenerationTask>> WaitAsync(
        string generationId,
        WaitOptions? options = null,
        CancellationToken cancellationToken = default)
    {
        var resolved = options ?? new WaitOptions();
        var deadline = DateTimeOffset.UtcNow.Add(resolved.Timeout);

        while (true)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var envelope = await RetrieveAsync(generationId, cancellationToken).ConfigureAwait(false);
            var task = envelope?.Data;
            if (task is null)
            {
                throw new BubleException("Buble API returned an empty generation response.");
            }

            if (IsStatus(task.Status, "success"))
            {
                return envelope!;
            }

            if (IsStatus(task.Status, "failed"))
            {
                throw new GenerationFailedException(task);
            }

            if (IsStatus(task.Status, "canceled") || IsStatus(task.Status, "cancelled"))
            {
                throw new GenerationCanceledException(task);
            }

            if (DateTimeOffset.UtcNow >= deadline)
            {
                throw new BubleTimeoutException($"Timed out waiting for Buble generation '{generationId}'.", resolved.Timeout);
            }

            await Task.Delay(resolved.Interval, cancellationToken).ConfigureAwait(false);
        }
    }

    private static bool IsStatus(string? actual, string expected)
    {
        return string.Equals(actual, expected, StringComparison.OrdinalIgnoreCase);
    }
}
