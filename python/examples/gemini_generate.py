from buble_ai import Buble

client = Buble()

response = client.chat.gemini.generate_content(
    "openai/gpt-5.5",
    contents=[
        {
            "role": "user",
            "parts": [{"text": "Write a short launch summary."}],
        }
    ],
)

print(response["candidates"][0]["content"]["parts"][0]["text"])

