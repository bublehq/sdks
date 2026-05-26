using Xunit;

namespace Buble.Sdk.Tests;

public sealed class AppsTests
{
    [Fact]
    public async Task CreatesAppGenerationWithFlatParameters()
    {
        var handler = new FakeHttpMessageHandler();
        handler.EnqueueJson("""{"data":{"id":"app_task_1","status":"pending"}}""");
        using var client = new BubleClient(new BubleClientOptions
        {
            ApiKey = "sk_test",
            BaseUrl = "https://example.test",
            HttpClient = new HttpClient(handler)
        });

        await client.Apps.Generations.CreateAsync("video-background-remover", new Dictionary<string, object?>
        {
            ["source_video"] = new[] { "https://example.test/source.mp4" },
            ["subject_is_person"] = true
        });

        Assert.Equal("/api/v1/apps/video-background-remover/generations", handler.Requests[0].Uri.AbsolutePath);
        Assert.Contains("\"source_video\"", handler.Requests[0].Body);
        Assert.Contains("\"subject_is_person\":true", handler.Requests[0].Body);
    }
}
