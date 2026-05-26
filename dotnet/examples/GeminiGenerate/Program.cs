using Buble.Sdk;
using System.Text.Json.Nodes;

using var client = BubleClient.FromEnv();

var response = await client.Chat.Gemini.GenerateContentAsync("openai/gpt-5.5", new JsonObject
{
    ["contents"] = new JsonArray
    {
        new JsonObject
        {
            ["role"] = "user",
            ["parts"] = new JsonArray(new JsonObject { ["text"] = "Write a short launch summary." })
        }
    }
});

Console.WriteLine(response?["candidates"]?[0]?["content"]?["parts"]?[0]?["text"]?.GetValue<string>());
