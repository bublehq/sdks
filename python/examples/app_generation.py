from buble_ai import Buble

client = Buble()

task = client.apps.generations.create(
    "asmr-crushing-frozen-fruits",
    fruit="Strawberries",
    video_ratio="16:9",
    video_resolution="720p",
)

result = client.apps.generations.wait("asmr-crushing-frozen-fruits", task["data"]["id"])
print(result["data"]["result"]["videos"][0]["url"])

