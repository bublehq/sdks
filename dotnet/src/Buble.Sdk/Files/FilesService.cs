using Buble.Sdk.Http;
using System.Net.Http.Headers;

namespace Buble.Sdk.Files;

public sealed class FilesService
{
    private readonly BubleHttpClient _http;

    internal FilesService(BubleHttpClient http)
    {
        _http = http;
    }

    public Task<Envelope<UploadedFile>?> UploadAsync(
        FileUpload file,
        UploadOptions? options = null,
        CancellationToken cancellationToken = default)
    {
        if (file is null)
        {
            throw new ArgumentNullException(nameof(file));
        }

        var resolved = options ?? new UploadOptions();
        var content = new MultipartFormDataContent();
        AddField(content, "file_type", resolved.FileType);
        AddField(content, "model", resolved.Model);
        AddField(content, "mode", resolved.Mode);

        var streamContent = new StreamContent(file.OpenRead());
        streamContent.Headers.ContentType = new MediaTypeHeaderValue(
            string.IsNullOrWhiteSpace(resolved.ContentType) ? file.ContentType : resolved.ContentType!);
        content.Add(
            streamContent,
            "file",
            string.IsNullOrWhiteSpace(resolved.Filename) ? file.Filename : resolved.Filename!);

        return _http.MultipartAsync<Envelope<UploadedFile>>("/api/v1/files", content, cancellationToken: cancellationToken);
    }

    private static void AddField(MultipartFormDataContent content, string name, string? value)
    {
        if (!string.IsNullOrWhiteSpace(value))
        {
            content.Add(new StringContent(value!), name);
        }
    }
}
