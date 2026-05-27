import Buble

let client = try BubleClient.fromEnvironment()

let response = try await client.chat.gemini.generateContent(
    "openai/gpt-5.4",
    body: [
        "contents": [
            [
                "role": "user",
                "parts": [
                    ["text": "Write a short launch summary."]
                ]
            ]
        ]
    ]
)

print(response)
