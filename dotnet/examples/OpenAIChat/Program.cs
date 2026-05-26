using Buble.Sdk;

using var client = BubleClient.FromEnv();

var response = await client.Chat.Completions.CreateAsync(new Dictionary<string, object?>
{
    ["model"] = "openai/gpt-5.5",
    ["messages"] = new[]
    {
        new Dictionary<string, object?>
        {
            ["role"] = "user",
            ["content"] = "Write a short launch summary."
        }
    },
    ["max_completion_tokens"] = 800
});

Console.WriteLine(response?["choices"]?[0]?["message"]?["content"]?.GetValue<string>());
