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

	message, err := client.Chat.Messages.Create(ctx, buble.ChatRequest{
		"model":  "openai/gpt-5.5",
		"system": "You are concise.",
		"messages": []any{
			map[string]any{"role": "user", "content": "Summarize this release in three bullets."},
		},
		"max_tokens": 800,
	})
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(message)
}
