using Buble.Sdk;

using var client = BubleClient.FromEnv();

var app = await client.Apps.RetrieveAsync("video-background-remover");
Console.WriteLine(app?.Data?.Name);

var task = await client.Apps.Generations.CreateAsync(
    "video-background-remover",
    new Dictionary<string, object?>
    {
        ["source_video"] = new[] { "https://example.com/source.mp4" },
        ["refine_foreground_edges"] = true,
        ["subject_is_person"] = true
    });

var result = await client.Apps.Generations.WaitAsync("video-background-remover", task!.Data!.Id!);
Console.WriteLine(result.Data?.Result?.Videos?[0].Url);
