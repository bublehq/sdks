package ai.buble.sdk.streaming;

/**
 * Chat streaming protocol used to extract text deltas from SSE events.
 */
public enum StreamProtocol {
    OPENAI,
    ANTHROPIC,
    GEMINI
}
