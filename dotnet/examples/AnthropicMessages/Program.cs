using Buble.Sdk;

using var client = BubleClient.FromEnv();

var response = await client.Chat.Messages.CreateAsync(new Dictionary<string, object?>
{
    ["model"] = "openai/gpt-5.5",
    ["system"] = "You are concise.",
    ["messages"] = new[]
    {
        new Dictionary<string, object?>
        {
            ["role"] = "user",
            ["content"] = "Summarize this release."
        }
    },
    ["max_tokens"] = 800
});

Console.WriteLine(response?["content"]?[0]?["text"]?.GetValue<string>());
