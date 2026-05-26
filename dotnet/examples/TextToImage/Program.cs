using Buble.Sdk;
using Buble.Sdk.Generations;

using var client = BubleClient.FromEnv();

var task = await client.Generations.CreateAsync(new CreateGenerationRequest
{
    Model = "google/nano-banana",
    Mode = "text_to_image",
    Prompt = "A cinematic product photo of a matte black espresso cup"
}.WithParam("aspect_ratio", "1:1").WithParam("output_format", "png"));

var result = await client.Generations.WaitAsync(task!.Data!.Id!);
Console.WriteLine(result.Data?.Result?.Images?[0].Url);
