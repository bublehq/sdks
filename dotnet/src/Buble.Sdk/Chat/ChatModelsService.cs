using Buble.Sdk.Http;

namespace Buble.Sdk.Chat;

public sealed class ChatModelsService
{
    private readonly BubleHttpClient _http;

    internal ChatModelsService(BubleHttpClient http)
    {
        _http = http;
    }

    public Task<ChatModelList?> ListAsync(CancellationToken cancellationToken = default)
    {
        return _http.GetAsync<ChatModelList>("/api/v1/models", cancellationToken: cancellationToken);
    }
}
