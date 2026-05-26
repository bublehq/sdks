using Buble.Sdk.Generations;
using Xunit;

namespace Buble.Sdk.Tests;

public sealed class GenerationsTests
{
    [Fact]
    public async Task CreatesFlatGenerationBody()
    {
        var handler = new FakeHttpMessageHandler();
        handler.EnqueueJson("""{"data":{"id":"task_1","status":"pending"}}""");
        using var client = Client(handler);

        await client.Generations.CreateAsync(new CreateGenerationRequest
        {
            Model = "google/nano-banana",
            Mode = "text_to_image",
            Prompt = "hello"
        }.WithParam("aspect_ratio", "1:1").WithParam("output_format", "png"));

        var body = handler.Requests[0].Body;
        Assert.Contains("\"model\":\"google/nano-banana\"", body);
        Assert.Contains("\"aspect_ratio\":\"1:1\"", body);
        Assert.DoesNotContain("\"params\"", body);
    }

    [Fact]
    public void RejectsInternalGenerationFields()
    {
        var request = new CreateGenerationRequest();
        Assert.Throws<UnsupportedGenerationFieldException>(() => request.WithParam("input", new { prompt = "x" }));
    }

    [Fact]
    public async Task WaitsForSuccess()
    {
        var handler = new FakeHttpMessageHandler();
        handler.EnqueueJson("""{"data":{"id":"task_1","status":"processing"}}""");
        handler.EnqueueJson("""{"data":{"id":"task_1","status":"success","result":{"images":[{"url":"https://example.test/out.png"}]}}}""");
        using var client = Client(handler);

        var result = await client.Generations.WaitAsync(
            "task_1",
            new WaitOptions { Interval = TimeSpan.FromMilliseconds(1), Timeout = TimeSpan.FromSeconds(1) });

        Assert.Equal("https://example.test/out.png", result.Data!.Result!.Images![0].Url);
        Assert.Equal("/api/v1/generations/task_1", handler.Requests[0].Uri.AbsolutePath);
    }

    private static BubleClient Client(FakeHttpMessageHandler handler) => new(new BubleClientOptions
    {
        ApiKey = "sk_test",
        BaseUrl = "https://example.test",
        HttpClient = new HttpClient(handler)
    });
}
