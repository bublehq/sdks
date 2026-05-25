package buble

import (
	"context"
	"net/http"
)

// ChatRequest is a flexible chat request body.
type ChatRequest map[string]any

// ChatResponse is a protocol-native chat response body.
type ChatResponse map[string]any

// ChatService provides chat model discovery and protocol-compatible chat methods.
type ChatService struct {
	// Models provides chat model discovery.
	Models *ChatModelsService
	// Completions provides OpenAI-compatible chat completion methods.
	Completions *ChatCompletionsService
	// Messages provides Anthropic Messages-compatible methods.
	Messages *MessagesService
	// Gemini provides Gemini-compatible content generation methods.
	Gemini *GeminiService
}

// ChatModelsService provides chat model discovery methods.
type ChatModelsService struct {
	client *Client
}

// List returns active chat models in an OpenAI-style model list response.
func (s *ChatModelsService) List(ctx context.Context, options ...RequestOption) (*ChatModelList, error) {
	var out ChatModelList
	if err := s.client.do(ctx, http.MethodGet, "/api/v1/models", nil, &out, options...); err != nil {
		return nil, err
	}
	return &out, nil
}

// ChatCompletionsService provides OpenAI-compatible chat completion methods.
type ChatCompletionsService struct {
	client *Client
}

// Create calls the OpenAI-compatible chat completions endpoint.
func (s *ChatCompletionsService) Create(ctx context.Context, body ChatRequest, options ...RequestOption) (ChatResponse, error) {
	payload := copyMap(body)
	payload["stream"] = false
	var out ChatResponse
	if err := s.client.do(ctx, http.MethodPost, "/api/v1/chat/completions", payload, &out, options...); err != nil {
		return nil, err
	}
	return out, nil
}

// Stream calls the OpenAI-compatible chat completions endpoint with stream enabled.
func (s *ChatCompletionsService) Stream(ctx context.Context, body ChatRequest, options ...RequestOption) (*Stream, error) {
	payload := copyMap(body)
	payload["stream"] = true
	resp, err := s.client.doStream(ctx, http.MethodPost, "/api/v1/chat/completions", payload, options...)
	if err != nil {
		return nil, err
	}
	return NewStream(resp.Body, StreamProtocolOpenAI), nil
}

// MessagesService provides Anthropic Messages-compatible methods.
type MessagesService struct {
	client *Client
}

// Create calls the Anthropic Messages-compatible endpoint.
func (s *MessagesService) Create(ctx context.Context, body ChatRequest, options ...RequestOption) (ChatResponse, error) {
	payload := copyMap(body)
	payload["stream"] = false
	var out ChatResponse
	if err := s.client.do(ctx, http.MethodPost, "/api/v1/messages", payload, &out, options...); err != nil {
		return nil, err
	}
	return out, nil
}

// Stream calls the Anthropic Messages-compatible endpoint with stream enabled.
func (s *MessagesService) Stream(ctx context.Context, body ChatRequest, options ...RequestOption) (*Stream, error) {
	payload := copyMap(body)
	payload["stream"] = true
	resp, err := s.client.doStream(ctx, http.MethodPost, "/api/v1/messages", payload, options...)
	if err != nil {
		return nil, err
	}
	return NewStream(resp.Body, StreamProtocolAnthropic), nil
}

// GeminiService provides Gemini-compatible content generation methods.
type GeminiService struct {
	client *Client
}

// GenerateContent calls the Gemini-compatible non-streaming endpoint.
func (s *GeminiService) GenerateContent(ctx context.Context, model string, body ChatRequest, options ...RequestOption) (ChatResponse, error) {
	path := "/api/v1beta/models/" + encodeModelPath(model) + ":generateContent"
	var out ChatResponse
	if err := s.client.do(ctx, http.MethodPost, path, copyMap(body), &out, options...); err != nil {
		return nil, err
	}
	return out, nil
}

// StreamGenerateContent calls the Gemini-compatible streaming endpoint.
func (s *GeminiService) StreamGenerateContent(ctx context.Context, model string, body ChatRequest, options ...RequestOption) (*Stream, error) {
	path := "/api/v1beta/models/" + encodeModelPath(model) + ":streamGenerateContent"
	resp, err := s.client.doStream(ctx, http.MethodPost, path, copyMap(body), options...)
	if err != nil {
		return nil, err
	}
	return NewStream(resp.Body, StreamProtocolGemini), nil
}

func copyMap(input map[string]any) map[string]any {
	output := make(map[string]any, len(input))
	for key, value := range input {
		output[key] = value
	}
	return output
}
