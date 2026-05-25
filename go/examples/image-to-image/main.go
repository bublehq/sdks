package main

import (
	"context"
	"fmt"
	"log"

	buble "github.com/bublehq/sdks/go"
)

func main() {
	ctx := context.Background()
	client := buble.NewClient()

	uploaded, err := client.Files.Upload(
		ctx,
		buble.FileFromPath("./reference.png"),
		buble.WithFileType("image"),
		buble.WithUploadModel("google/nano-banana"),
		buble.WithUploadMode("image_to_image"),
	)
	if err != nil {
		log.Fatal(err)
	}

	task, err := client.Generations.Create(ctx, &buble.CreateGenerationRequest{
		Model:     "google/nano-banana",
		Mode:      "image_to_image",
		Prompt:    "Turn this reference into a polished ecommerce hero image.",
		ImageURLs: []string{uploaded.Data.URL},
		Params: map[string]any{
			"aspect_ratio": "1:1",
		},
	})
	if err != nil {
		log.Fatal(err)
	}

	result, err := client.Generations.Wait(ctx, task.Data.ID)
	if err != nil {
		log.Fatal(err)
	}
	if result.Data.Result != nil && len(result.Data.Result.Images) > 0 {
		fmt.Println(result.Data.Result.Images[0].URL)
	}
}
