namespace Buble.Sdk.Files;

public sealed class FileUpload
{
    private readonly Func<Stream> _openRead;

    private FileUpload(Func<Stream> openRead, string filename, string contentType)
    {
        _openRead = openRead;
        Filename = filename;
        ContentType = contentType;
    }

    public string Filename { get; }

    public string ContentType { get; }

    internal Stream OpenRead() => _openRead();

    public static FileUpload FromPath(string path, string? contentType = null)
    {
        if (string.IsNullOrWhiteSpace(path))
        {
            throw new ArgumentException("File path is required.", nameof(path));
        }

        return new FileUpload(
            () => File.OpenRead(path),
            Path.GetFileName(path),
            contentType ?? "application/octet-stream");
    }

    public static FileUpload FromBytes(byte[] bytes, string filename, string? contentType = null)
    {
        if (bytes is null)
        {
            throw new ArgumentNullException(nameof(bytes));
        }
        if (string.IsNullOrWhiteSpace(filename))
        {
            throw new ArgumentException("Filename is required.", nameof(filename));
        }

        return new FileUpload(
            () => new MemoryStream(bytes, writable: false),
            filename,
            contentType ?? "application/octet-stream");
    }

    public static FileUpload FromStream(Func<Stream> openRead, string filename, string? contentType = null)
    {
        if (openRead is null)
        {
            throw new ArgumentNullException(nameof(openRead));
        }
        if (string.IsNullOrWhiteSpace(filename))
        {
            throw new ArgumentException("Filename is required.", nameof(filename));
        }

        return new FileUpload(openRead, filename, contentType ?? "application/octet-stream");
    }
}
