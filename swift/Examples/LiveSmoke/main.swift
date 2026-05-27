import Buble

let client = try BubleClient.fromEnvironment()

let models = try await client.mediaModels.list(mediaType: "image")
print(#"{"step":"media_models","count":\#(models.data.count)}"#)

let completion = try await client.chat.completions.create([
    "model": "openai/gpt-5.4",
    "messages": [
        [
            "role": "user",
            "content": "Reply with exactly: Buble Swift SDK live smoke OK"
        ]
    ],
    "max_completion_tokens": 32
])

let message = completion.value(at: ["choices", "0", "message", "content"])?.stringValue ?? ""
print(#"{"step":"chat","message":"\#(message)"}"#)
