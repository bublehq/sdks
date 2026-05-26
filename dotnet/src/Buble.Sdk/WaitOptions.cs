namespace Buble.Sdk;

/// <summary>
/// Polling options for asynchronous generation tasks.
/// </summary>
public sealed class WaitOptions
{
    public TimeSpan Interval { get; set; } = TimeSpan.FromSeconds(2);

    public TimeSpan Timeout { get; set; } = TimeSpan.FromMinutes(10);

    public static WaitOptions Default => new();
}
