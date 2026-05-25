package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"os"
	"time"

	buble "github.com/bublehq/sdks/go"
)

func main() {
	if os.Getenv("BUBLE_API_KEY") == "" {
		log.Fatal("Missing BUBLE_API_KEY. Run with BUBLE_API_KEY=sk_...")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	client := buble.NewClient()
	fmt.Printf("INFO Base URL: %s\n", client.BaseURL())

	mediaModels, err := client.MediaModels.List(ctx, "")
	must(err)
	require(len(mediaModels.Data) > 0, "media model list returned no models")
	fmt.Printf("PASS MediaModels.List(): %d models\n", len(mediaModels.Data))

	imageModels, err := client.MediaModels.List(ctx, "image")
	must(err)
	fmt.Printf("PASS MediaModels.List(\"image\"): %d models\n", len(imageModels.Data))

	apps, err := client.Apps.List(ctx, 0, 10)
	must(err)
	fmt.Printf("PASS Apps.List(): %d apps\n", len(apps.Data))

	if len(apps.Data) > 0 {
		app, err := client.Apps.Retrieve(ctx, apps.Data[0].ID)
		must(err)
		require(app.Data.ID == apps.Data[0].ID, "retrieved app id mismatch")
		fmt.Printf("PASS Apps.Retrieve(%s)\n", app.Data.ID)
	}

	chatModels, err := client.Chat.Models.List(ctx)
	must(err)
	require(chatModels.Object == "list", "chat model list should preserve object=list")
	fmt.Printf("PASS Chat.Models.List(): %d models\n", len(chatModels.Data))

	_, err = client.Generations.Retrieve(ctx, "sdk-smoke-non-existent-task")
	var apiErr *buble.APIError
	if !errors.As(err, &apiErr) {
		log.Fatalf("expected APIError for non-existent task, got %T: %v", err, err)
	}
	require(apiErr.StatusCode >= 400, "expected API error status")
	fmt.Printf("PASS APIError parsing: %d %s\n", apiErr.StatusCode, apiErr.Code)
	fmt.Println("PASS live smoke test completed without creating billable generation tasks")
}

func must(err error) {
	if err != nil {
		log.Fatal(err)
	}
}

func require(condition bool, message string) {
	if !condition {
		log.Fatal(message)
	}
}
