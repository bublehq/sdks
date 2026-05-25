from buble_ai import Buble

client = Buble()

completion = client.chat.completions.create(
    model="openai/gpt-5.5",
    messages=[{"role": "user", "content": "Write a short launch summary."}],
    reasoning=True,
    max_completion_tokens=800,
)

print(completion["choices"][0]["message"]["content"])

