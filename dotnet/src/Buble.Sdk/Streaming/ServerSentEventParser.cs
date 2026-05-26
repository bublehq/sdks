namespace Buble.Sdk.Streaming;

internal static class ServerSentEventParser
{
    internal static async IAsyncEnumerable<ServerSentEvent> ParseAsync(
        IAsyncEnumerable<string> lines,
        [System.Runtime.CompilerServices.EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        string? id = null;
        string? eventName = null;
        var data = new List<string>();

        await foreach (var rawLine in lines.WithCancellation(cancellationToken).ConfigureAwait(false))
        {
            var line = rawLine;
            if (line.Length == 0)
            {
                if (data.Count > 0)
                {
                    yield return new ServerSentEvent
                    {
                        Id = id,
                        Event = eventName,
                        Data = string.Join("\n", data)
                    };
                }

                id = null;
                eventName = null;
                data.Clear();
                continue;
            }

            if (line.StartsWith(":", StringComparison.Ordinal))
            {
                continue;
            }

            var separator = line.IndexOf(':');
            var field = separator < 0 ? line : line.Substring(0, separator);
            var value = separator < 0 ? string.Empty : line.Substring(separator + 1).TrimStart(' ');

            switch (field)
            {
                case "id":
                    id = value;
                    break;
                case "event":
                    eventName = value;
                    break;
                case "data":
                    data.Add(value);
                    break;
            }
        }

        if (data.Count > 0)
        {
            yield return new ServerSentEvent
            {
                Id = id,
                Event = eventName,
                Data = string.Join("\n", data)
            };
        }
    }
}
