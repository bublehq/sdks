package buble

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"testing"
	"time"
)

func TestCreatesFlatGenerationBody(t *testing.T) {
	var body map[string]any
	client, server := newTestClient(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/v1/generations" {
			t.Fatalf("unexpected path: %s", r.URL.Path)
		}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			t.Fatalf("decode request: %v", err)
		}
		writeJSON(t, w, http.StatusCreated, map[string]any{"data": map[string]any{"id": "task_1", "status": "pending"}})
	})
	defer server.Close()

	result, err := client.Generations.Create(context.Background(), &CreateGenerationRequest{
		Model:  "google/nano-banana",
		Mode:   "text_to_image",
		Prompt: "A test image",
		Params: map[string]any{
			"aspect_ratio":  "1:1",
			"output_format": "png",
		},
	})
	if err != nil {
		t.Fatalf("Create returned error: %v", err)
	}
	if result.Data.ID != "task_1" {
		t.Fatalf("unexpected task: %#v", result.Data)
	}
	if body["model"] != "google/nano-banana" || body["mode"] != "text_to_image" || body["aspect_ratio"] != "1:1" {
		t.Fatalf("request body was not flat public JSON: %#v", body)
	}
	if _, ok := body["params"]; ok {
		t.Fatalf("request body leaked Params field: %#v", body)
	}
}

func TestWaitUntilSuccess(t *testing.T) {
	statuses := []TaskStatus{StatusPending, StatusProcessing, StatusSuccess}
	client, server := newTestClient(func(w http.ResponseWriter, r *http.Request) {
		status := statuses[0]
		statuses = statuses[1:]
		writeJSON(t, w, http.StatusOK, map[string]any{"data": map[string]any{"id": "task_1", "status": status}})
	})
	defer server.Close()

	result, err := client.Generations.Wait(
		context.Background(),
		"task_1",
		WithWaitInterval(time.Millisecond),
		WithWaitTimeout(time.Second),
	)
	if err != nil {
		t.Fatalf("Wait returned error: %v", err)
	}
	if result.Data.Status != StatusSuccess {
		t.Fatalf("unexpected status: %s", result.Data.Status)
	}
}

func TestWaitFailedRaisesGenerationFailedError(t *testing.T) {
	client, server := newTestClient(func(w http.ResponseWriter, r *http.Request) {
		writeJSON(t, w, http.StatusOK, map[string]any{
			"data": map[string]any{
				"id":     "task_1",
				"status": "failed",
				"error":  map[string]any{"message": "Generation failed."},
			},
		})
	})
	defer server.Close()

	_, err := client.Generations.Wait(context.Background(), "task_1", WithWaitTimeout(time.Second))
	genErr := &GenerationFailedError{}
	if !errors.As(err, &genErr) {
		t.Fatalf("expected GenerationFailedError, got %T: %v", err, err)
	}
}
