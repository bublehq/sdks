using Buble.Sdk.Generations;
using System.Text.Json.Nodes;

namespace Buble.Sdk;

public class BubleException : Exception
{
    public BubleException(string message)
        : base(message)
    {
    }

    public BubleException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}

public sealed class BubleApiException : BubleException
{
    public BubleApiException(int statusCode, string? code, string message, JsonNode? details, string? responseBody)
        : base(message)
    {
        StatusCode = statusCode;
        Code = code;
        Details = details;
        ResponseBody = responseBody;
    }

    public int StatusCode { get; }

    public string? Code { get; }

    public JsonNode? Details { get; }

    public string? ResponseBody { get; }
}

public sealed class BubleTimeoutException : BubleException
{
    public BubleTimeoutException(string message, TimeSpan timeout, Exception? innerException = null)
        : base(message, innerException ?? new TimeoutException(message))
    {
        Timeout = timeout;
    }

    public TimeSpan Timeout { get; }
}

public sealed class UnsupportedGenerationFieldException : BubleException
{
    public UnsupportedGenerationFieldException(string field)
        : base($"'{field}' is an internal Buble workflow field and cannot be sent to the public generation API.")
    {
        Field = field;
    }

    public string Field { get; }
}

public class GenerationFailedException : BubleException
{
    public GenerationFailedException(GenerationTask task)
        : base($"Buble generation '{task.Id}' failed.")
    {
        Task = task;
    }

    public GenerationTask Task { get; }
}

public sealed class GenerationCanceledException : BubleException
{
    public GenerationCanceledException(GenerationTask task)
        : base($"Buble generation '{task.Id}' was canceled.")
    {
        Task = task;
    }

    public GenerationTask Task { get; }
}
