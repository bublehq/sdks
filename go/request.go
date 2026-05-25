package buble

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
)

type apiErrorEnvelope struct {
	Error *struct {
		Code    string `json:"code,omitempty"`
		Message string `json:"message,omitempty"`
		Details any    `json:"details,omitempty"`
	} `json:"error,omitempty"`
}

func (c *Client) do(ctx context.Context, method, path string, body any, out any, options ...RequestOption) error {
	var reader io.Reader
	if body != nil {
		data, err := json.Marshal(body)
		if err != nil {
			return err
		}
		reader = bytes.NewReader(data)
	}

	return c.doBody(ctx, method, path, reader, "application/json", out, options...)
}

func (c *Client) doBody(ctx context.Context, method, path string, body io.Reader, contentType string, out any, options ...RequestOption) error {
	req, err := c.newRequest(ctx, method, path, body, options...)
	if err != nil {
		return err
	}
	if body != nil && contentType != "" {
		req.Header.Set("Content-Type", contentType)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		if errors.Is(err, context.DeadlineExceeded) || errors.Is(ctx.Err(), context.DeadlineExceeded) {
			return &TimeoutError{Message: "buble: API request timed out", Timeout: 0}
		}
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return parseAPIError(resp)
	}
	if out == nil || resp.StatusCode == http.StatusNoContent {
		_, _ = io.Copy(io.Discard, resp.Body)
		return nil
	}
	if err := json.NewDecoder(resp.Body).Decode(out); err != nil {
		return err
	}
	return nil
}

func (c *Client) doStream(ctx context.Context, method, path string, body any, options ...RequestOption) (*http.Response, error) {
	var reader io.Reader
	if body != nil {
		data, err := json.Marshal(body)
		if err != nil {
			return nil, err
		}
		reader = bytes.NewReader(data)
	}

	req, err := c.newRequest(ctx, method, path, reader, options...)
	if err != nil {
		return nil, err
	}
	if reader != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	req.Header.Set("Accept", "text/event-stream")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		defer resp.Body.Close()
		return nil, parseAPIError(resp)
	}
	return resp, nil
}

func (c *Client) newRequest(ctx context.Context, method, path string, body io.Reader, options ...RequestOption) (*http.Request, error) {
	if c.apiKey == "" {
		return nil, fmt.Errorf("buble: missing API key; pass WithAPIKey or set BUBLE_API_KEY")
	}

	config := defaultRequestConfig()
	for _, option := range options {
		option(&config)
	}

	u, err := url.Parse(c.baseURL)
	if err != nil {
		return nil, err
	}
	rel, err := url.Parse(path)
	if err != nil {
		return nil, err
	}
	u = u.ResolveReference(rel)
	query := u.Query()
	for key, value := range config.query {
		if value != "" {
			query.Set(key, value)
		}
	}
	u.RawQuery = query.Encode()

	req, err := http.NewRequestWithContext(ctx, method, u.String(), body)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+c.apiKey)
	req.Header.Set("Accept", "application/json")
	for key, values := range c.headers {
		for _, value := range values {
			req.Header.Add(key, value)
		}
	}
	for key, values := range config.headers {
		req.Header.Del(key)
		for _, value := range values {
			req.Header.Add(key, value)
		}
	}
	return req, nil
}

func parseAPIError(resp *http.Response) error {
	data, _ := io.ReadAll(resp.Body)
	message := resp.Status
	apiError := apiErrorEnvelope{}
	if len(data) > 0 {
		if err := json.Unmarshal(data, &apiError); err == nil && apiError.Error != nil {
			if apiError.Error.Message != "" {
				message = apiError.Error.Message
			}
			return &APIError{
				StatusCode: resp.StatusCode,
				Code:       apiError.Error.Code,
				Message:    message,
				Details:    apiError.Error.Details,
				Response:   resp,
			}
		}
		message = string(data)
	}
	return &APIError{
		StatusCode: resp.StatusCode,
		Message:    message,
		Response:   resp,
	}
}

func encodePathSegment(value string) string {
	return url.PathEscape(value)
}

func encodeModelPath(model string) string {
	parts := strings.Split(model, "/")
	for i, part := range parts {
		parts[i] = url.PathEscape(part)
	}
	return strings.Join(parts, "/")
}
