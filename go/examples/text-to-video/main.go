package main

import (
	"context"
	"fmt"
	"log"
	"time"

	buble "github.com/bublehq/sdks/go"
)

func main() {
	ctx := context.Background()
	client := buble.NewClient()

	task, err := client.Generations.Create(ctx, &buble.CreateGenerationRequest{
		Model:  "doubao/seedance-2.0-fast",
		Mode:   "text_to_video",
		Prompt: "A slow cinematic shot of a futuristic train station at sunrise.",
		Params: map[string]any{
			"duration":     "8s",
			"resolution":   "720p",
			"aspect_ratio": "16:9",
		},
	})
	if err != nil {
		log.Fatal(err)
	}

	result, err := client.Generations.Wait(
		ctx,
		task.Data.ID,
		buble.WithWaitInterval(2*time.Second),
		buble.WithWaitTimeout(10*time.Minute),
	)
	if err != nil {
		log.Fatal(err)
	}
	if result.Data.Result != nil && len(result.Data.Result.Videos) > 0 {
		fmt.Println(result.Data.Result.Videos[0].URL)
	}
}
