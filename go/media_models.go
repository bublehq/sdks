package buble

import (
	"context"
	"net/http"
)

// MediaModelsService provides media model discovery methods.
type MediaModelsService struct {
	client *Client
}

// List returns API-ready media models, modes, inputs, and parameters.
func (s *MediaModelsService) List(ctx context.Context, mediaType string, options ...RequestOption) (*Envelope[[]MediaModel], error) {
	if mediaType != "" {
		options = append(options, WithQuery("media_type", mediaType))
	}
	var out Envelope[[]MediaModel]
	if err := s.client.do(ctx, http.MethodGet, "/api/v1/media_models", nil, &out, options...); err != nil {
		return nil, err
	}
	return &out, nil
}
