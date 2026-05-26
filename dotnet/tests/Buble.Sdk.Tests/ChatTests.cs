using System.Text.Json.Nodes;
using Xunit;

namespace Buble.Sdk.Tests;

public sealed class ChatTests
{
    [Fact]
    public async Task CreatesOpenAICompatibleChatWithoutWrappingResponse()
    {
        var handler = new FakeHttpMessageHandler();
        handler.EnqueueJson("""{"id":"chatcmpl_1","choices":[{"message":{"content":"hello"}}]}""");
        using var client = Client(handler);

        var response = await client.Chat.Completions.CreateAsync(new Dictionary<string, object?>
        {
            ["model"] = "openai/gpt-5.5",
            ["messages"] = new[] { new Dictionary<string, object?> { ["role"] = "user", ["content"] = "hi" } }
        });

        Assert.Equal("hello", response!["choices"]![0]!["message"]!["content"]!.GetValue<string>());
        Assert.Equal("/api/v1/chat/completions", handler.Requests[0].Uri.AbsolutePath);
        Assert.Contains("\"stream\":false", handler.Requests[0].Body);
    }

    [Fact]
    public async Task StreamsOpenAIText()
    {
        var handler = new FakeHttpMessageHandler();
        handler.EnqueueSse("""
data: {"choices":[{"delta":{"content":"hel"}}]}

data: {"choices":[{"delta":{"content":"lo"}}]}

data: [DONE]

""");
        using var client = Client(handler);

        var parts = new List<string>();
        await foreach (var text in client.Chat.Completions.StreamTextAsync(new JsonObject
        {
            ["model"] = "openai/gpt-5.5",
            ["messages"] = new JsonArray(new JsonObject { ["role"] = "user", ["content"] = "hi" })
        }))
        {
            parts.Add(text);
        }

        Assert.Equal(new[] { "hel", "lo" }, parts);
    }

    [Fact]
    public async Task UsesGeminiStreamGenerateContentPath()
    {
        var handler = new FakeHttpMessageHandler();
        handler.EnqueueJson("""{"candidates":[]}""");
        using var client = Client(handler);

        await client.Chat.Gemini.GenerateContentAsync("openai/gpt-5.5", new JsonObject
        {
            ["contents"] = new JsonArray()
        });

        Assert.Equal("/api/v1beta/models/openai/gpt-5.5:generateContent", handler.Requests[0].Uri.AbsolutePath);
    }

    private static BubleClient Client(FakeHttpMessageHandler handler) => new(new BubleClientOptions
    {
        ApiKey = "sk_test",
        BaseUrl = "https://example.test",
        HttpClient = new HttpClient(handler)
    });
}
