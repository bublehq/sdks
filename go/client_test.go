package buble

import (
	"context"
	"encoding/json"
	"errors"
	"net"
	"net/http"
	"testing"
)

type testServer struct {
	URL      string
	listener net.Listener
	server   *http.Server
}

func (s *testServer) Close() {
	_ = s.server.Close()
	_ = s.listener.Close()
}

func newTestClient(handler http.HandlerFunc) (*Client, *testServer) {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		panic(err)
	}
	server := &http.Server{Handler: handler}
	go func() {
		_ = server.Serve(listener)
	}()
	testServer := &testServer{
		URL:      "http://" + listener.Addr().String(),
		listener: listener,
		server:   server,
	}
	client := NewClient(
		WithAPIKey("sk_test"),
		WithBaseURL(testServer.URL),
		WithHTTPClient(http.DefaultClient),
	)
	return client, testServer
}

func writeJSON(t *testing.T, w http.ResponseWriter, status int, value any) {
	t.Helper()
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(value); err != nil {
		t.Fatalf("encode response: %v", err)
	}
}

func TestClientAddsBearerAuthAndPreservesChatModelShape(t *testing.T) {
	var auth string
	client, server := newTestClient(func(w http.ResponseWriter, r *http.Request) {
		auth = r.Header.Get("Authorization")
		if r.URL.Path != "/api/v1/models" {
			t.Fatalf("unexpected path: %s", r.URL.Path)
		}
		writeJSON(t, w, http.StatusOK, map[string]any{"object": "list", "data": []any{}})
	})
	defer server.Close()

	result, err := client.Chat.Models.List(context.Background())
	if err != nil {
		t.Fatalf("Chat.Models.List returned error: %v", err)
	}
	if auth != "Bearer sk_test" {
		t.Fatalf("auth header = %q", auth)
	}
	if result.Object != "list" || len(result.Data) != 0 {
		t.Fatalf("unexpected model list: %#v", result)
	}
}

func TestParsesAPIError(t *testing.T) {
	client, server := newTestClient(func(w http.ResponseWriter, r *http.Request) {
		writeJSON(t, w, http.StatusUnauthorized, map[string]any{
			"error": map[string]any{
				"code":    "invalid_api_key",
				"message": "Invalid API key.",
				"details": map[string]any{"reason": "test"},
			},
		})
	})
	defer server.Close()

	_, err := client.MediaModels.List(context.Background(), "")
	apiErr := &APIError{}
	if !errors.As(err, &apiErr) {
		t.Fatalf("expected APIError, got %T: %v", err, err)
	}
	if apiErr.StatusCode != http.StatusUnauthorized || apiErr.Code != "invalid_api_key" || apiErr.Message != "Invalid API key." {
		t.Fatalf("unexpected APIError: %#v", apiErr)
	}
}

func TestRejectsInternalGenerationFieldsBeforeRequest(t *testing.T) {
	called := false
	client, server := newTestClient(func(w http.ResponseWriter, r *http.Request) {
		called = true
		writeJSON(t, w, http.StatusOK, map[string]any{})
	})
	defer server.Close()

	_, err := client.Generations.Create(context.Background(), &CreateGenerationRequest{
		Model: "google/nano-banana",
		Mode:  "text_to_image",
		Params: map[string]any{
			"options": map[string]any{},
		},
	})
	fieldErr := &UnsupportedFieldError{}
	if !errors.As(err, &fieldErr) || fieldErr.Field != "options" {
		t.Fatalf("expected UnsupportedFieldError for options, got %T: %v", err, err)
	}
	if called {
		t.Fatal("request was sent despite local validation error")
	}
}
