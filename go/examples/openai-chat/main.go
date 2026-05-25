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

	completion, err := client.Chat.Completions.Create(ctx, buble.ChatRequest{
		"model": "openai/gpt-5.5",
		"messages": []any{
			map[string]any{"role": "user", "content": "Write a short launch summary."},
		},
		"reasoning":             true,
		"max_completion_tokens": 800,
	})
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(completion)
}
