import Buble

let client = try BubleClient.fromEnvironment()

let message = try await client.chat.messages.create([
    "model": "openai/gpt-5.4",
    "system": "You are concise.",
    "messages": [
        ["role": "user", "content": "Summarize this release."]
    ],
    "max_tokens": 800
])

print(message)
