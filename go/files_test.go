package buble

import (
	"context"
	"net/http"
	"testing"
)

func TestUploadSendsMultipartFields(t *testing.T) {
	client, server := newTestClient(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/v1/files" {
			t.Fatalf("unexpected path: %s", r.URL.Path)
		}
		if err := r.ParseMultipartForm(1 << 20); err != nil {
			t.Fatalf("ParseMultipartForm: %v", err)
		}
		if got := r.FormValue("file_type"); got != "image" {
			t.Fatalf("file_type = %q", got)
		}
		if got := r.FormValue("model"); got != "google/nano-banana" {
			t.Fatalf("model = %q", got)
		}
		if got := r.FormValue("mode"); got != "image_to_image" {
			t.Fatalf("mode = %q", got)
		}
		file, header, err := r.FormFile("file")
		if err != nil {
			t.Fatalf("FormFile: %v", err)
		}
		defer file.Close()
		if header.Filename != "file.png" {
			t.Fatalf("filename = %q", header.Filename)
		}
		writeJSON(t, w, http.StatusCreated, map[string]any{
			"data": map[string]any{
				"object":       "file",
				"provider":     "r2",
				"url":          "https://cdn.example/file.png",
				"key":          "api/image/file.png",
				"file_type":    "image",
				"content_type": "image/png",
				"size":         4,
				"filename":     "file.png",
			},
		})
	})
	defer server.Close()

	result, err := client.Files.Upload(
		context.Background(),
		FileFromBytes([]byte("test"), "file.png"),
		WithFileType("image"),
		WithUploadModel("google/nano-banana"),
		WithUploadMode("image_to_image"),
		WithContentType("image/png"),
	)
	if err != nil {
		t.Fatalf("Upload returned error: %v", err)
	}
	if result.Data.URL != "https://cdn.example/file.png" {
		t.Fatalf("unexpected upload result: %#v", result.Data)
	}
}
