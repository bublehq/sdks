import Buble

let client = try BubleClient.fromEnvironment()

let completion = try await client.chat.completions.create([
    "model": "openai/gpt-5.4",
    "messages": [
        ["role": "user", "content": "Write a short launch summary."]
    ],
    "max_completion_tokens": 800
])

print(completion)
