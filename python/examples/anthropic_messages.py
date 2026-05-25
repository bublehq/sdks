from buble_ai import Buble

client = Buble()

message = client.chat.messages.create(
    model="openai/gpt-5.5",
    system="You are concise.",
    messages=[{"role": "user", "content": "Summarize this release in three bullets."}],
    max_tokens=800,
)

print(message)

