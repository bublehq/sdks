package buble

import (
	"context"
	"encoding/json"
	"net/http"
	"testing"
	"time"
)

func TestAppsListAndRetrieve(t *testing.T) {
	client, server := newTestClient(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/api/v1/apps":
			if r.URL.Query().Get("limit") != "10" {
				t.Fatalf("missing limit query: %s", r.URL.RawQuery)
			}
			writeJSON(t, w, http.StatusOK, map[string]any{"data": []any{map[string]any{"id": "video-background-remover", "input_parameters": []any{}}}})
		case "/api/v1/apps/video-background-remover":
			writeJSON(t, w, http.StatusOK, map[string]any{"data": map[string]any{"id": "video-background-remover", "input_parameters": []any{}}})
		default:
			t.Fatalf("unexpected path: %s", r.URL.Path)
		}
	})
	defer server.Close()

	apps, err := client.Apps.List(context.Background(), 0, 10)
	if err != nil {
		t.Fatalf("Apps.List returned error: %v", err)
	}
	if apps.Data[0].ID != "video-background-remover" {
		t.Fatalf("unexpected apps: %#v", apps.Data)
	}
	app, err := client.Apps.Retrieve(context.Background(), "video-background-remover")
	if err != nil {
		t.Fatalf("Apps.Retrieve returned error: %v", err)
	}
	if app.Data.ID != "video-background-remover" {
		t.Fatalf("unexpected app: %#v", app.Data)
	}
}

func TestAppGenerationCreateAndWait(t *testing.T) {
	statuses := []TaskStatus{StatusPending, StatusSuccess}
	var body map[string]any
	client, server := newTestClient(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method + " " + r.URL.Path {
		case "POST /api/v1/apps/video-background-remover/generations":
			if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
				t.Fatalf("decode request: %v", err)
			}
			writeJSON(t, w, http.StatusCreated, map[string]any{"data": map[string]any{"id": "app_task_1", "status": "pending"}})
		case "GET /api/v1/apps/video-background-remover/generations/app_task_1":
			status := statuses[0]
			statuses = statuses[1:]
			writeJSON(t, w, http.StatusOK, map[string]any{"data": map[string]any{"id": "app_task_1", "status": status}})
		default:
			t.Fatalf("unexpected request: %s %s", r.Method, r.URL.Path)
		}
	})
	defer server.Close()

	task, err := client.Apps.Generations.Create(context.Background(), "video-background-remover", map[string]any{
		"source_video": []string{"https://example.com/source.mp4"},
	})
	if err != nil {
		t.Fatalf("Create returned error: %v", err)
	}
	if body["source_video"] == nil || task.Data.ID != "app_task_1" {
		t.Fatalf("unexpected app generation body/task: %#v %#v", body, task.Data)
	}
	result, err := client.Apps.Generations.Wait(
		context.Background(),
		"video-background-remover",
		"app_task_1",
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
