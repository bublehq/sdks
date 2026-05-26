using System.Text.Json.Nodes;

namespace Buble.Sdk.Streaming;

internal static class StreamText
{
    internal static async IAsyncEnumerable<string> FromEventsAsync(
        IAsyncEnumerable<ServerSentEvent> events,
        StreamProtocol protocol,
        [System.Runtime.CompilerServices.EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        await foreach (var item in events.WithCancellation(cancellationToken).ConfigureAwait(false))
        {
            if (string.Equals(item.Data, "[DONE]", StringComparison.Ordinal))
            {
                yield break;
            }

            JsonNode? node;
            try
            {
                node = JsonNode.Parse(item.Data);
            }
            catch
            {
                continue;
            }

            foreach (var text in ExtractText(node, protocol))
            {
                if (!string.IsNullOrEmpty(text))
                {
                    yield return text!;
                }
            }
        }
    }

    private static IEnumerable<string?> ExtractText(JsonNode? node, StreamProtocol protocol)
    {
        return protocol switch
        {
            StreamProtocol.OpenAI => ExtractOpenAI(node),
            StreamProtocol.Anthropic => ExtractAnthropic(node),
            StreamProtocol.Gemini => ExtractGemini(node),
            _ => Enumerable.Empty<string?>()
        };
    }

    private static IEnumerable<string?> ExtractOpenAI(JsonNode? node)
    {
        var choices = node?["choices"]?.AsArray();
        if (choices is null)
        {
            yield break;
        }

        foreach (var choice in choices)
        {
            var text = choice?["delta"]?["content"]?.GetValue<string>()
                ?? choice?["message"]?["content"]?.GetValue<string>()
                ?? choice?["text"]?.GetValue<string>();
            yield return text;
        }
    }

    private static IEnumerable<string?> ExtractAnthropic(JsonNode? node)
    {
        yield return node?["delta"]?["text"]?.GetValue<string>();
        yield return node?["content_block"]?["text"]?.GetValue<string>();
    }

    private static IEnumerable<string?> ExtractGemini(JsonNode? node)
    {
        var candidates = node?["candidates"]?.AsArray();
        if (candidates is null)
        {
            yield break;
        }

        foreach (var candidate in candidates)
        {
            var parts = candidate?["content"]?["parts"]?.AsArray();
            if (parts is null)
            {
                continue;
            }

            foreach (var part in parts)
            {
                yield return part?["text"]?.GetValue<string>();
            }
        }
    }
}
