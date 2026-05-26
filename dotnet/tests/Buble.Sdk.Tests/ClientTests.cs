using Xunit;

namespace Buble.Sdk.Tests;

public sealed class ClientTests
{
    [Fact]
    public void RequiresApiKey()
    {
        Assert.Throws<BubleException>(() => new BubleClient(new BubleClientOptions { ApiKey = "" }));
    }

    [Fact]
    public async Task SendsBearerAuthAndTrimsBaseUrl()
    {
        var handler = new FakeHttpMessageHandler();
        handler.EnqueueJson("""{"data":[]}""");
        using var client = new BubleClient(new BubleClientOptions
        {
            ApiKey = "sk_test",
            BaseUrl = "https://example.test/",
            HttpClient = new HttpClient(handler)
        });

        await client.MediaModels.ListAsync("video");

        Assert.Equal("Bearer sk_test", handler.Requests[0].Authorization);
        Assert.Equal("https://example.test/api/v1/media_models?media_type=video", handler.Requests[0].Uri.ToString());
    }
}
