using Buble.Sdk;
using Buble.Sdk.Files;
using Buble.Sdk.Generations;

using var client = BubleClient.FromEnv();

var uploaded = await client.Files.UploadAsync(
    FileUpload.FromPath("reference.png", "image/png"),
    new UploadOptions
    {
        FileType = "image",
        Model = "google/nano-banana",
        Mode = "image_to_image"
    });

var task = await client.Generations.CreateAsync(new CreateGenerationRequest
{
    Model = "google/nano-banana",
    Mode = "image_to_image",
    Prompt = "Turn this reference into a polished ecommerce hero image.",
    ImageUrls = new[] { uploaded!.Data!.Url! }
});

var result = await client.Generations.WaitAsync(task!.Data!.Id!);
Console.WriteLine(result.Data?.Result?.Images?[0].Url);
