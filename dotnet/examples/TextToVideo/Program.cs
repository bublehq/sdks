using Buble.Sdk;
using Buble.Sdk.Generations;

using var client = BubleClient.FromEnv();

var task = await client.Generations.CreateAsync(new CreateGenerationRequest
{
    Model = "doubao/seedance-2.0-fast",
    Mode = "text_to_video",
    Prompt = "A slow cinematic shot of a futuristic train station at sunrise."
}.WithParam("duration", "8s").WithParam("resolution", "720p").WithParam("aspect_ratio", "16:9"));

var result = await client.Generations.WaitAsync(
    task!.Data!.Id!,
    new WaitOptions { Interval = TimeSpan.FromSeconds(2), Timeout = TimeSpan.FromMinutes(10) });

Console.WriteLine(result.Data?.Result?.Videos?[0].Url);
