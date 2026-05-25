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

	response, err := client.Chat.Gemini.GenerateContent(ctx, "openai/gpt-5.5", buble.ChatRequest{
		"contents": []any{
			map[string]any{
				"role": "user",
				"parts": []any{
					map[string]any{"text": "Write a short launch summary."},
				},
			},
		},
	})
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(response)
}
