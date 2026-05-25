from buble_ai import Buble

client = Buble()

task = client.generations.create(
    model="doubao/seedance-2.0-fast",
    mode="text_to_video",
    prompt="A cinematic wide shot of a futuristic train station at sunrise.",
    duration="8s",
    resolution="720p",
    aspect_ratio="16:9",
)

result = client.generations.wait(task["data"]["id"], interval=2.0, timeout=600.0)
print(result["data"]["result"]["videos"][0]["url"])

