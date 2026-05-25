package buble

import (
	"context"
	"fmt"
	"net/http"
	"time"
)

var forbiddenGenerationFields = map[string]struct{}{
	"input":       {},
	"options":     {},
	"scene":       {},
	"sub_mode_id": {},
	"subModeId":   {},
	"provider":    {},
	"mediaType":   {},
	"media_type":  {},
	"images":      {},
	"image_input": {},
	"video_input": {},
	"audio_input": {},
}

// GenerationsService provides direct media generation methods.
type GenerationsService struct {
	client *Client
}

// Create creates an asynchronous image, video, or audio generation task.
func (s *GenerationsService) Create(ctx context.Context, req *CreateGenerationRequest, options ...RequestOption) (*Envelope[GenerationTask], error) {
	body, err := generationRequestBody(req)
	if err != nil {
		return nil, err
	}
	var out Envelope[GenerationTask]
	if err := s.client.do(ctx, http.MethodPost, "/api/v1/generations", body, &out, options...); err != nil {
		return nil, err
	}
	return &out, nil
}

// Retrieve returns the current status and result for a media generation task.
func (s *GenerationsService) Retrieve(ctx context.Context, id string, options ...RequestOption) (*Envelope[GenerationTask], error) {
	var out Envelope[GenerationTask]
	path := "/api/v1/generations/" + encodePathSegment(id)
	if err := s.client.do(ctx, http.MethodGet, path, nil, &out, options...); err != nil {
		return nil, err
	}
	return &out, nil
}

// Wait polls a media generation task until it reaches a terminal status.
func (s *GenerationsService) Wait(ctx context.Context, id string, options ...WaitOption) (*Envelope[GenerationTask], error) {
	config := defaultWaitConfig()
	for _, option := range options {
		option(&config)
	}
	ctx, cancel := context.WithTimeout(ctx, config.timeout)
	defer cancel()

	ticker := time.NewTicker(config.interval)
	defer ticker.Stop()

	for {
		envelope, err := s.Retrieve(ctx, id)
		if err != nil {
			return nil, err
		}
		task := envelope.Data
		if isTerminalStatus(task.Status) {
			if task.Status == StatusFailed && config.throwOnFailed {
				return nil, failedGenerationError("Generation failed.", &task)
			}
			if task.Status == StatusCanceled && config.throwOnCanceled {
				return nil, &GenerationCanceledError{
					Message: fmt.Sprintf("Generation %s was canceled.", id),
					Task:    &task,
				}
			}
			return envelope, nil
		}

		select {
		case <-ctx.Done():
			return nil, &TimeoutError{
				Message: fmt.Sprintf("Generation %s did not finish within %s.", id, config.timeout),
				Timeout: config.timeout,
			}
		case <-ticker.C:
		}
	}
}

func isForbiddenGenerationField(field string) bool {
	_, ok := forbiddenGenerationFields[field]
	return ok
}

func isTerminalStatus(status TaskStatus) bool {
	return status == StatusSuccess || status == StatusFailed || status == StatusCanceled
}

func failedGenerationError(defaultMessage string, task *GenerationTask) error {
	message := defaultMessage
	if task != nil && task.Error != nil && task.Error.Message != "" {
		message = task.Error.Message
	}
	return &GenerationFailedError{Message: message, Task: task}
}
