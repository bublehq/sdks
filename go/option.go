package buble

import (
	"net/http"
	"os"
	"time"
)

const (
	defaultBaseURL      = "https://buble.ai"
	defaultWaitTimeout  = 10 * time.Minute
	defaultWaitInterval = 2 * time.Second
)

// ClientOption configures a Buble client.
type ClientOption func(*clientConfig)

type clientConfig struct {
	apiKey     string
	baseURL    string
	httpClient *http.Client
	headers    http.Header
}

func defaultClientConfig() clientConfig {
	return clientConfig{
		apiKey:     os.Getenv("BUBLE_API_KEY"),
		baseURL:    firstNonEmpty(os.Getenv("BUBLE_BASE_URL"), defaultBaseURL),
		httpClient: http.DefaultClient,
		headers:    make(http.Header),
	}
}

// WithAPIKey sets the API key used for Authorization: Bearer authentication.
func WithAPIKey(apiKey string) ClientOption {
	return func(config *clientConfig) {
		config.apiKey = apiKey
	}
}

// WithBaseURL sets the API base URL. The default is https://buble.ai.
func WithBaseURL(baseURL string) ClientOption {
	return func(config *clientConfig) {
		config.baseURL = baseURL
	}
}

// WithHTTPClient sets the HTTP client used to make API requests.
func WithHTTPClient(client *http.Client) ClientOption {
	return func(config *clientConfig) {
		if client != nil {
			config.httpClient = client
		}
	}
}

// WithHeader adds a default header to every request.
func WithHeader(key, value string) ClientOption {
	return func(config *clientConfig) {
		config.headers.Set(key, value)
	}
}

// RequestOption configures one API request.
type RequestOption func(*requestConfig)

type requestConfig struct {
	query   map[string]string
	headers http.Header
}

func defaultRequestConfig() requestConfig {
	return requestConfig{
		query:   make(map[string]string),
		headers: make(http.Header),
	}
}

// WithQuery adds a query parameter to an API request.
func WithQuery(key, value string) RequestOption {
	return func(config *requestConfig) {
		config.query[key] = value
	}
}

// WithRequestHeader adds a header to one API request.
func WithRequestHeader(key, value string) RequestOption {
	return func(config *requestConfig) {
		config.headers.Set(key, value)
	}
}

// WaitOption configures polling behavior for generation wait helpers.
type WaitOption func(*waitConfig)

type waitConfig struct {
	interval        time.Duration
	timeout         time.Duration
	throwOnFailed   bool
	throwOnCanceled bool
}

func defaultWaitConfig() waitConfig {
	return waitConfig{
		interval:        defaultWaitInterval,
		timeout:         defaultWaitTimeout,
		throwOnFailed:   true,
		throwOnCanceled: true,
	}
}

// WithWaitInterval sets the delay between polling requests.
func WithWaitInterval(interval time.Duration) WaitOption {
	return func(config *waitConfig) {
		if interval > 0 {
			config.interval = interval
		}
	}
}

// WithWaitTimeout sets the maximum time spent polling.
func WithWaitTimeout(timeout time.Duration) WaitOption {
	return func(config *waitConfig) {
		if timeout > 0 {
			config.timeout = timeout
		}
	}
}

// WithWaitFailedResult returns failed tasks instead of raising GenerationFailedError.
func WithWaitFailedResult() WaitOption {
	return func(config *waitConfig) {
		config.throwOnFailed = false
	}
}

// WithWaitCanceledResult returns canceled tasks instead of raising GenerationCanceledError.
func WithWaitCanceledResult() WaitOption {
	return func(config *waitConfig) {
		config.throwOnCanceled = false
	}
}

// UploadOption configures a file upload request.
type UploadOption func(*uploadConfig)

type uploadConfig struct {
	fileType    string
	model       string
	mode        string
	filename    string
	contentType string
}

// WithFileType sets the public file type: image, video, or audio.
func WithFileType(fileType string) UploadOption {
	return func(config *uploadConfig) {
		config.fileType = fileType
	}
}

// WithUploadModel sets the optional model key used for upload validation.
func WithUploadModel(model string) UploadOption {
	return func(config *uploadConfig) {
		config.model = model
	}
}

// WithUploadMode sets the optional public mode used for upload validation.
func WithUploadMode(mode string) UploadOption {
	return func(config *uploadConfig) {
		config.mode = mode
	}
}

// WithFilename sets the multipart filename for reader or byte uploads.
func WithFilename(filename string) UploadOption {
	return func(config *uploadConfig) {
		config.filename = filename
	}
}

// WithContentType sets the uploaded file content type.
func WithContentType(contentType string) UploadOption {
	return func(config *uploadConfig) {
		config.contentType = contentType
	}
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if value != "" {
			return value
		}
	}
	return ""
}
