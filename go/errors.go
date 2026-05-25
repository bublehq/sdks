package buble

import (
	"fmt"
	"net/http"
	"time"
)

// Error is the base error type for the Buble Go SDK.
type Error struct {
	Message string
}

// Error returns the error message.
func (e *Error) Error() string {
	return e.Message
}

// APIError is returned for non-2xx responses from the Buble API.
type APIError struct {
	StatusCode int
	Code       string
	Message    string
	Details    any
	Response   *http.Response
}

// Error returns a human-readable API error message.
func (e *APIError) Error() string {
	if e.Code != "" {
		return fmt.Sprintf("buble: API error %d %s: %s", e.StatusCode, e.Code, e.Message)
	}
	return fmt.Sprintf("buble: API error %d: %s", e.StatusCode, e.Message)
}

// TimeoutError is returned when an SDK polling operation exceeds its timeout.
type TimeoutError struct {
	Message string
	Timeout time.Duration
}

// Error returns a human-readable timeout error message.
func (e *TimeoutError) Error() string {
	return e.Message
}

// UnsupportedFieldError is returned when a request contains a known internal
// Buble field that is not accepted by the public generation API.
type UnsupportedFieldError struct {
	Field string
}

// Error returns a human-readable unsupported field error message.
func (e *UnsupportedFieldError) Error() string {
	return fmt.Sprintf("buble: field %q is an internal Buble field and is not supported by the public generation API", e.Field)
}

// GenerationFailedError is returned when a media or app generation reaches
// failed status while using a wait helper.
type GenerationFailedError struct {
	Message string
	Task    any
}

// Error returns a human-readable generation failure message.
func (e *GenerationFailedError) Error() string {
	if e.Message != "" {
		return e.Message
	}
	return "buble: generation failed"
}

// GenerationCanceledError is returned when a media or app generation reaches
// canceled status while using a wait helper.
type GenerationCanceledError struct {
	Message string
	Task    any
}

// Error returns a human-readable generation cancellation message.
func (e *GenerationCanceledError) Error() string {
	if e.Message != "" {
		return e.Message
	}
	return "buble: generation was canceled"
}
