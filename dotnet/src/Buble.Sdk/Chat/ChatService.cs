using Buble.Sdk.Http;

namespace Buble.Sdk.Chat;

public sealed class ChatService
{
    internal ChatService(BubleHttpClient http)
    {
        Models = new ChatModelsService(http);
        Completions = new ChatCompletionsService(http);
        Messages = new MessagesService(http);
        Gemini = new GeminiService(http);
    }

    public ChatModelsService Models { get; }

    public ChatCompletionsService Completions { get; }

    public MessagesService Messages { get; }

    public GeminiService Gemini { get; }
}
