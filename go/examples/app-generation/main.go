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

	task, err := client.Apps.Generations.Create(ctx, "asmr-crushing-frozen-fruits", map[string]any{
		"fruit":            "Strawberries",
		"video_ratio":      "16:9",
		"video_resolution": "720p",
	})
	if err != nil {
		log.Fatal(err)
	}

	result, err := client.Apps.Generations.Wait(ctx, "asmr-crushing-frozen-fruits", task.Data.ID)
	if err != nil {
		log.Fatal(err)
	}
	if result.Data.Result != nil && len(result.Data.Result.Videos) > 0 {
		fmt.Println(result.Data.Result.Videos[0].URL)
	}
}
