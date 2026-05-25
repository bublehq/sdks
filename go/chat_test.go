package buble

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"testing"
)

func TestGeminiPreservesSlashModelPath(t *testing.T) {
	var requestedPath string
	client, server := newTestClient(func(w http.ResponseWriter, r *http.Request) {
		requestedPath = r.URL.Path
		writeJSON(t, w, http.StatusOK, map[string]any{"candidates": []any{}})
	})
	defer server.Close()

	_, err := client.Chat.Gemini.GenerateContent(context.Background(), "openai/gpt-5.5", ChatRequest{
		"contents": []any{map[string]any{"role": "user", "parts": []any{map[string]any{"text": "hi"}}}},
	})
	if err != nil {
		t.Fatalf("GenerateContent returned error: %v", err)
	}
	if requestedPath != "/api/v1beta/models/openai/gpt-5.5:generateContent" {
		t.Fatalf("unexpected Gemini path: %s", requestedPath)
	}
}

func TestOpenAIStreamText(t *testing.T) {
	streamTextTest(t, StreamProtocolOpenAI, "/api/v1/chat/completions", []string{
		`data: {"choices":[{"delta":{"content":"Hel"}}]}`,
		"",
		`data: {"choices":[{"delta":{"content":"lo"}}]}`,
		"",
		"data: [DONE]",
		"",
	}, "Hello")
}

func TestAnthropicStreamText(t *testing.T) {
	streamTextTest(t, StreamProtocolAnthropic, "/api/v1/messages", []string{
		"event: content_block_delta",
		`data: {"delta":{"text":"Hel"}}`,
		"",
		"event: content_block_delta",
		`data: {"delta":{"text":"lo"}}`,
		"",
	}, "Hello")
}

func TestGeminiStreamText(t *testing.T) {
	streamTextTest(t, StreamProtocolGemini, "/api/v1beta/models/openai/gpt-5.5:streamGenerateContent", []string{
		`data: {"candidates":[{"content":{"parts":[{"text":"Hel"}]}}]}`,
		"",
		`data: {"candidates":[{"content":{"parts":[{"text":"lo"}]}}]}`,
		"",
	}, "Hello")
}

func streamTextTest(t *testing.T, protocol StreamProtocol, path string, lines []string, want string) {
	t.Helper()
	client, server := newTestClient(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != path {
			t.Fatalf("unexpected path: %s", r.URL.Path)
		}
		w.Header().Set("Content-Type", "text/event-stream")
		for _, line := range lines {
			_, _ = fmt.Fprintln(w, line)
		}
	})
	defer server.Close()

	var stream *Stream
	var err error
	switch protocol {
	case StreamProtocolOpenAI:
		stream, err = client.Chat.Completions.Stream(context.Background(), ChatRequest{
			"model":    "openai/gpt-5.5",
			"messages": []any{},
		})
	case StreamProtocolAnthropic:
		stream, err = client.Chat.Messages.Stream(context.Background(), ChatRequest{
			"model":    "openai/gpt-5.5",
			"messages": []any{},
		})
	case StreamProtocolGemini:
		stream, err = client.Chat.Gemini.StreamGenerateContent(context.Background(), "openai/gpt-5.5", ChatRequest{
			"contents": []any{},
		})
	}
	if err != nil {
		t.Fatalf("stream returned error: %v", err)
	}
	defer stream.Close()

	var got string
	for stream.Next() {
		got += stream.Text()
	}
	if err := stream.Err(); err != nil && err != io.EOF {
		t.Fatalf("stream error: %v", err)
	}
	if got != want {
		t.Fatalf("text = %q, want %q", got, want)
	}
}
