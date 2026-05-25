from buble_ai import Buble

client = Buble()

uploaded = client.files.upload(
    "reference.png",
    file_type="image",
    model="google/nano-banana",
    mode="image_to_image",
)

task = client.generations.create(
    model="google/nano-banana",
    mode="image_to_image",
    prompt="Turn this reference into a polished ecommerce hero image.",
    image_urls=[uploaded["data"]["url"]],
)

result = client.generations.wait(task["data"]["id"])
print(result["data"]["result"]["images"][0]["url"])

