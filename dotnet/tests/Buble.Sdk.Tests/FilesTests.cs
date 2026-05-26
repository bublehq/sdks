using Buble.Sdk.Files;
using Xunit;

namespace Buble.Sdk.Tests;

public sealed class FilesTests
{
    [Fact]
    public async Task UploadsMultipartFileAndFields()
    {
        var handler = new FakeHttpMessageHandler();
        handler.EnqueueJson("""{"data":{"id":"file_1","url":"https://example.test/file.png"}}""");
        using var client = new BubleClient(new BubleClientOptions
        {
            ApiKey = "sk_test",
            BaseUrl = "https://example.test",
            HttpClient = new HttpClient(handler)
        });

        await client.Files.UploadAsync(
            FileUpload.FromBytes(new byte[] { 1, 2, 3 }, "reference.png", "image/png"),
            new UploadOptions
            {
                FileType = "image",
                Model = "google/nano-banana",
                Mode = "image_to_image"
            });

        var body = handler.Requests[0].Body;
        Assert.Equal("/api/v1/files", handler.Requests[0].Uri.AbsolutePath);
        Assert.Contains("file_type", body);
        Assert.Contains("image_to_image", body);
        Assert.Contains("reference.png", body);
    }
}
