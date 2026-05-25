package buble

import "encoding/json"

// Envelope is the common response shape for Buble media, file, and app endpoints.
type Envelope[T any] struct {
	Data T `json:"data"`
}

// TaskStatus is the lifecycle status of an asynchronous generation task.
type TaskStatus string

const (
	// StatusPending means a task has been accepted and is waiting to run.
	StatusPending TaskStatus = "pending"
	// StatusProcessing means a provider is generating output.
	StatusProcessing TaskStatus = "processing"
	// StatusSuccess means generation completed successfully.
	StatusSuccess TaskStatus = "success"
	// StatusFailed means generation failed.
	StatusFailed TaskStatus = "failed"
	// StatusCanceled means generation was canceled.
	StatusCanceled TaskStatus = "canceled"
)

// MediaModel describes one API-ready media model returned by model discovery.
type MediaModel struct {
	Model      string                `json:"model"`
	Name       string                `json:"name,omitempty"`
	MediaType  string                `json:"media_type,omitempty"`
	Operations []MediaModelOperation `json:"operations,omitempty"`
}

// MediaModelOperation describes one public operation mode for a media model.
type MediaModelOperation struct {
	Mode        string                `json:"mode"`
	Description string                `json:"description,omitempty"`
	Input       map[string]any        `json:"input,omitempty"`
	Parameters  []MediaModelParameter `json:"parameters,omitempty"`
}

// MediaModelParameter describes one request parameter accepted by a model mode.
type MediaModelParameter struct {
	Name     string `json:"name"`
	Type     string `json:"type,omitempty"`
	Label    string `json:"label,omitempty"`
	Default  any    `json:"default,omitempty"`
	Enum     []any  `json:"enum,omitempty"`
	Values   []any  `json:"values,omitempty"`
	Min      any    `json:"min,omitempty"`
	Max      any    `json:"max,omitempty"`
	Step     any    `json:"step,omitempty"`
	Required bool   `json:"required,omitempty"`
}

// UploadedFile describes an uploaded source asset.
type UploadedFile struct {
	Object      string `json:"object"`
	Provider    string `json:"provider"`
	URL         string `json:"url"`
	Key         string `json:"key"`
	FileType    string `json:"file_type"`
	ContentType string `json:"content_type"`
	Size        int64  `json:"size"`
	Filename    string `json:"filename"`
}

// MediaResultImage describes one generated image asset.
type MediaResultImage struct {
	URL string `json:"url"`
}

// MediaResultVideo describes one generated video asset.
type MediaResultVideo struct {
	URL          string `json:"url"`
	PreviewURL   string `json:"preview_url,omitempty"`
	ThumbnailURL string `json:"thumbnail_url,omitempty"`
	Duration     any    `json:"duration,omitempty"`
}

// MediaResultAudio describes one generated audio asset.
type MediaResultAudio struct {
	URL      string `json:"url"`
	ImageURL string `json:"image_url,omitempty"`
	Title    string `json:"title,omitempty"`
	Duration any    `json:"duration,omitempty"`
}

// GenerationResult contains generated media assets.
type GenerationResult struct {
	Images []MediaResultImage `json:"images,omitempty"`
	Videos []MediaResultVideo `json:"videos,omitempty"`
	Audios []MediaResultAudio `json:"audios,omitempty"`
}

// GenerationTaskError describes a task-level generation error.
type GenerationTaskError struct {
	Code    string `json:"code,omitempty"`
	Message string `json:"message,omitempty"`
}

// GenerationTask describes a direct media generation task.
type GenerationTask struct {
	ID          string               `json:"id"`
	Status      TaskStatus           `json:"status"`
	Model       string               `json:"model,omitempty"`
	MediaType   string               `json:"media_type,omitempty"`
	Mode        string               `json:"mode,omitempty"`
	CostCredits int                  `json:"cost_credits,omitempty"`
	CreatedAt   string               `json:"created_at,omitempty"`
	UpdatedAt   string               `json:"updated_at,omitempty"`
	Result      *GenerationResult    `json:"result,omitempty"`
	Error       *GenerationTaskError `json:"error,omitempty"`
}

// CreateGenerationRequest creates an asynchronous media generation task.
type CreateGenerationRequest struct {
	Model         string         `json:"model"`
	Mode          string         `json:"mode,omitempty"`
	Prompt        string         `json:"prompt,omitempty"`
	ImageURLs     []string       `json:"image_urls,omitempty"`
	StartFrame    string         `json:"start_frame,omitempty"`
	EndFrame      string         `json:"end_frame,omitempty"`
	VideoURLs     []string       `json:"video_urls,omitempty"`
	AudioURLs     []string       `json:"audio_urls,omitempty"`
	IsPublic      *bool          `json:"is_public,omitempty"`
	CopyProtected *bool          `json:"copy_protected,omitempty"`
	Params        map[string]any `json:"-"`
}

// PublicApp describes a callable Buble app workflow.
type PublicApp struct {
	ID              string              `json:"id"`
	InputParameters []AppInputParameter `json:"input_parameters"`
}

// AppInputParameter describes one flat input accepted by an app workflow.
type AppInputParameter struct {
	Name   string `json:"name"`
	Type   string `json:"type"`
	Values []any  `json:"values,omitempty"`
}

// AppGenerationTask describes an app generation task.
type AppGenerationTask struct {
	ID     string               `json:"id"`
	Status TaskStatus           `json:"status"`
	Result *GenerationResult    `json:"result,omitempty"`
	Error  *GenerationTaskError `json:"error,omitempty"`
}

// ChatModel describes one callable chat model.
type ChatModel struct {
	ID           string         `json:"id"`
	Object       string         `json:"object"`
	Created      int64          `json:"created,omitempty"`
	OwnedBy      string         `json:"owned_by,omitempty"`
	Name         string         `json:"name,omitempty"`
	Description  string         `json:"description,omitempty"`
	Capabilities map[string]any `json:"capabilities,omitempty"`
	Tags         []string       `json:"tags,omitempty"`
}

// ChatModelList is the OpenAI-style model list returned by chat model discovery.
type ChatModelList struct {
	Object string      `json:"object"`
	Data   []ChatModel `json:"data"`
}

// SSEEvent is one parsed server-sent event from a streaming chat endpoint.
type SSEEvent struct {
	Event string
	Data  string
	JSON  any
}

func generationRequestBody(req *CreateGenerationRequest) (map[string]any, error) {
	if req == nil {
		return nil, &Error{Message: "buble: generation request is nil"}
	}
	body := make(map[string]any)
	setString(body, "model", req.Model)
	setString(body, "mode", req.Mode)
	setString(body, "prompt", req.Prompt)
	setStrings(body, "image_urls", req.ImageURLs)
	setString(body, "start_frame", req.StartFrame)
	setString(body, "end_frame", req.EndFrame)
	setStrings(body, "video_urls", req.VideoURLs)
	setStrings(body, "audio_urls", req.AudioURLs)
	if req.IsPublic != nil {
		body["is_public"] = *req.IsPublic
	}
	if req.CopyProtected != nil {
		body["copy_protected"] = *req.CopyProtected
	}
	for key, value := range req.Params {
		if value == nil {
			continue
		}
		if isForbiddenGenerationField(key) {
			return nil, &UnsupportedFieldError{Field: key}
		}
		body[key] = value
	}
	for key := range body {
		if isForbiddenGenerationField(key) {
			return nil, &UnsupportedFieldError{Field: key}
		}
	}
	return body, nil
}

func setString(body map[string]any, key, value string) {
	if value != "" {
		body[key] = value
	}
}

func setStrings(body map[string]any, key string, value []string) {
	if len(value) > 0 {
		body[key] = value
	}
}

func decodeMap(data []byte) map[string]any {
	out := map[string]any{}
	_ = json.Unmarshal(data, &out)
	return out
}
