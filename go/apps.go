package buble

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"time"
)

// AppsService provides Buble app workflow discovery and generation methods.
type AppsService struct {
	client *Client

	// Generations provides app generation methods.
	Generations *AppGenerationsService
}

// List returns callable app workflows and their input parameters.
func (s *AppsService) List(ctx context.Context, page, limit int, options ...RequestOption) (*Envelope[[]PublicApp], error) {
	if page > 0 {
		options = append(options, WithQuery("page", strconv.Itoa(page)))
	}
	if limit > 0 {
		options = append(options, WithQuery("limit", strconv.Itoa(limit)))
	}
	var out Envelope[[]PublicApp]
	if err := s.client.do(ctx, http.MethodGet, "/api/v1/apps", nil, &out, options...); err != nil {
		return nil, err
	}
	return &out, nil
}

// Retrieve returns one app's public input parameters.
func (s *AppsService) Retrieve(ctx context.Context, app string, options ...RequestOption) (*Envelope[PublicApp], error) {
	var out Envelope[PublicApp]
	path := "/api/v1/apps/" + encodePathSegment(app)
	if err := s.client.do(ctx, http.MethodGet, path, nil, &out, options...); err != nil {
		return nil, err
	}
	return &out, nil
}

// AppGenerationsService provides app generation task methods.
type AppGenerationsService struct {
	client *Client
}

// Create creates an asynchronous generation task for a preconfigured app.
func (s *AppGenerationsService) Create(ctx context.Context, app string, body map[string]any, options ...RequestOption) (*Envelope[AppGenerationTask], error) {
	if body == nil {
		body = map[string]any{}
	}
	var out Envelope[AppGenerationTask]
	path := "/api/v1/apps/" + encodePathSegment(app) + "/generations"
	if err := s.client.do(ctx, http.MethodPost, path, body, &out, options...); err != nil {
		return nil, err
	}
	return &out, nil
}

// Retrieve returns the current status and result for an app generation task.
func (s *AppGenerationsService) Retrieve(ctx context.Context, app, id string, options ...RequestOption) (*Envelope[AppGenerationTask], error) {
	var out Envelope[AppGenerationTask]
	path := "/api/v1/apps/" + encodePathSegment(app) + "/generations/" + encodePathSegment(id)
	if err := s.client.do(ctx, http.MethodGet, path, nil, &out, options...); err != nil {
		return nil, err
	}
	return &out, nil
}

// Wait polls an app generation task until it reaches a terminal status.
func (s *AppGenerationsService) Wait(ctx context.Context, app, id string, options ...WaitOption) (*Envelope[AppGenerationTask], error) {
	config := defaultWaitConfig()
	for _, option := range options {
		option(&config)
	}
	ctx, cancel := context.WithTimeout(ctx, config.timeout)
	defer cancel()

	ticker := time.NewTicker(config.interval)
	defer ticker.Stop()

	for {
		envelope, err := s.Retrieve(ctx, app, id)
		if err != nil {
			return nil, err
		}
		task := envelope.Data
		if isTerminalStatus(task.Status) {
			if task.Status == StatusFailed && config.throwOnFailed {
				return nil, failedAppGenerationError("App generation failed.", &task)
			}
			if task.Status == StatusCanceled && config.throwOnCanceled {
				return nil, &GenerationCanceledError{
					Message: fmt.Sprintf("App generation %s was canceled.", id),
					Task:    &task,
				}
			}
			return envelope, nil
		}

		select {
		case <-ctx.Done():
			return nil, &TimeoutError{
				Message: fmt.Sprintf("App generation %s did not finish within %s.", id, config.timeout),
				Timeout: config.timeout,
			}
		case <-ticker.C:
		}
	}
}

func failedAppGenerationError(defaultMessage string, task *AppGenerationTask) error {
	message := defaultMessage
	if task != nil && task.Error != nil && task.Error.Message != "" {
		message = task.Error.Message
	}
	return &GenerationFailedError{Message: message, Task: task}
}
