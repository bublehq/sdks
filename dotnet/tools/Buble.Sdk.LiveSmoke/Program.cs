using Buble.Sdk;

using var client = BubleClient.FromEnv();

var mediaModels = await client.MediaModels.ListAsync();
Console.WriteLine($"media models: {mediaModels?.Data?.Count ?? 0}");

var apps = await client.Apps.ListAsync();
Console.WriteLine($"apps: {apps?.Data?.Count ?? 0}");

var chatModels = await client.Chat.Models.ListAsync();
Console.WriteLine($"chat models: {chatModels?.Data?.Count ?? 0}");
