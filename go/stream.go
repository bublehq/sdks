package buble

import (
	"bufio"
	"encoding/json"
	"io"
	"strings"
)

// StreamProtocol identifies the protocol shape used by an SSE stream.
type StreamProtocol string

const (
	// StreamProtocolOpenAI extracts text from OpenAI-compatible chunks.
	StreamProtocolOpenAI StreamProtocol = "openai"
	// StreamProtocolAnthropic extracts text from Anthropic-compatible events.
	StreamProtocolAnthropic StreamProtocol = "anthropic"
	// StreamProtocolGemini extracts text from Gemini-compatible chunks.
	StreamProtocolGemini StreamProtocol = "gemini"
)

// Stream reads server-sent events from a streaming chat response.
type Stream struct {
	reader   io.ReadCloser
	scanner  *bufio.Scanner
	protocol StreamProtocol
	event    SSEEvent
	err      error
	closed   bool
	buffer   []string
}

// NewStream creates a Stream from a response body and protocol.
func NewStream(reader io.ReadCloser, protocol StreamProtocol) *Stream {
	scanner := bufio.NewScanner(reader)
	scanner.Buffer(make([]byte, 0, 64*1024), 1024*1024)
	return &Stream{
		reader:   reader,
		scanner:  scanner,
		protocol: protocol,
	}
}

// Next advances the stream to the next event. It returns false when the stream
// ends, the server sends [DONE], or an error occurs.
func (s *Stream) Next() bool {
	for s.scanner.Scan() {
		line := strings.TrimSuffix(s.scanner.Text(), "\r")
		if line == "" {
			if event, ok := parseSSEBlock(s.buffer); ok {
				s.buffer = nil
				if event.Data == "[DONE]" {
					_ = s.Close()
					return false
				}
				s.event = event
				return true
			}
			s.buffer = nil
			continue
		}
		s.buffer = append(s.buffer, line)
	}
	if err := s.scanner.Err(); err != nil {
		s.err = err
		_ = s.Close()
		return false
	}
	if event, ok := parseSSEBlock(s.buffer); ok {
		s.buffer = nil
		if event.Data == "[DONE]" {
			_ = s.Close()
			return false
		}
		s.event = event
		return true
	}
	_ = s.Close()
	return false
}

// Event returns the current SSE event after a successful call to Next.
func (s *Stream) Event() SSEEvent {
	return s.event
}

// Text returns the text delta from the current event, when available.
func (s *Stream) Text() string {
	return textFromEvent(s.event, s.protocol)
}

// Err returns the stream read error, if any.
func (s *Stream) Err() error {
	return s.err
}

// Close closes the underlying response body.
func (s *Stream) Close() error {
	if s.closed {
		return nil
	}
	s.closed = true
	return s.reader.Close()
}

func parseSSEBlock(lines []string) (SSEEvent, bool) {
	var event SSEEvent
	var dataLines []string
	for _, raw := range lines {
		line := strings.TrimRight(raw, "\r")
		if line == "" || strings.HasPrefix(line, ":") {
			continue
		}
		field, value, found := strings.Cut(line, ":")
		if found {
			value = strings.TrimPrefix(value, " ")
		}
		switch field {
		case "event":
			event.Event = value
		case "data":
			dataLines = append(dataLines, value)
		}
	}
	if event.Event == "" && len(dataLines) == 0 {
		return SSEEvent{}, false
	}
	event.Data = strings.Join(dataLines, "\n")
	if event.Data != "" && event.Data != "[DONE]" {
		var parsed any
		if err := json.Unmarshal([]byte(event.Data), &parsed); err == nil {
			event.JSON = parsed
		}
	}
	return event, true
}

func textFromEvent(event SSEEvent, protocol StreamProtocol) string {
	payload, ok := event.JSON.(map[string]any)
	if !ok {
		return ""
	}
	switch protocol {
	case StreamProtocolOpenAI:
		return textFromOpenAI(payload)
	case StreamProtocolAnthropic:
		if event.Event != "content_block_delta" {
			return ""
		}
		return textFromAnthropic(payload)
	case StreamProtocolGemini:
		return textFromGemini(payload)
	default:
		return ""
	}
}

func textFromOpenAI(payload map[string]any) string {
	choices, ok := payload["choices"].([]any)
	if !ok || len(choices) == 0 {
		return ""
	}
	choice, ok := choices[0].(map[string]any)
	if !ok {
		return ""
	}
	delta, ok := choice["delta"].(map[string]any)
	if !ok {
		return ""
	}
	text, _ := delta["content"].(string)
	return text
}

func textFromAnthropic(payload map[string]any) string {
	delta, ok := payload["delta"].(map[string]any)
	if !ok {
		return ""
	}
	text, _ := delta["text"].(string)
	return text
}

func textFromGemini(payload map[string]any) string {
	choices, ok := payload["candidates"].([]any)
	if !ok || len(choices) == 0 {
		return ""
	}
	choice, ok := choices[0].(map[string]any)
	if !ok {
		return ""
	}
	content, ok := choice["content"].(map[string]any)
	if !ok {
		return ""
	}
	parts, ok := content["parts"].([]any)
	if !ok {
		return ""
	}
	var out strings.Builder
	for _, partValue := range parts {
		part, ok := partValue.(map[string]any)
		if !ok {
			continue
		}
		text, ok := part["text"].(string)
		if ok {
			out.WriteString(text)
		}
	}
	return out.String()
}
