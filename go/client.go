package buble

import (
	"net/http"
	"strings"
)

// Client is a server-side client for the Buble public API.
type Client struct {
	apiKey     string
	baseURL    string
	httpClient *http.Client
	headers    http.Header

	// MediaModels provides media model discovery methods.
	MediaModels *MediaModelsService
	// Files provides source media upload methods.
	Files *FilesService
	// Generations provides direct media generation methods.
	Generations *GenerationsService
	// Apps provides preconfigured app workflow methods.
	Apps *AppsService
	// Chat provides chat model methods for OpenAI, Anthropic, and Gemini-compatible APIs.
	Chat *ChatService
}

// NewClient creates a Buble API client.
func NewClient(options ...ClientOption) *Client {
	config := defaultClientConfig()
	for _, option := range options {
		option(&config)
	}

	client := &Client{
		apiKey:     config.apiKey,
		baseURL:    strings.TrimRight(config.baseURL, "/"),
		httpClient: config.httpClient,
		headers:    config.headers.Clone(),
	}
	client.MediaModels = &MediaModelsService{client: client}
	client.Files = &FilesService{client: client}
	client.Generations = &GenerationsService{client: client}
	client.Apps = &AppsService{
		client:      client,
		Generations: &AppGenerationsService{client: client},
	}
	client.Chat = &ChatService{
		Models:      &ChatModelsService{client: client},
		Completions: &ChatCompletionsService{client: client},
		Messages:    &MessagesService{client: client},
		Gemini:      &GeminiService{client: client},
	}
	return client
}

// BaseURL returns the configured API base URL.
func (c *Client) BaseURL() string {
	return c.baseURL
}
