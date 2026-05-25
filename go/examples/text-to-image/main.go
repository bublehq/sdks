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

	task, err := client.Generations.Create(ctx, &buble.CreateGenerationRequest{
		Model:  "google/nano-banana",
		Mode:   "text_to_image",
		Prompt: "A cinematic product photo of a ceramic coffee grinder",
		Params: map[string]any{
			"aspect_ratio":  "1:1",
			"output_format": "png",
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
