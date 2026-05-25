import json

import httpx

from buble_ai import Buble


def json_response(data, status_code=200):
    return httpx.Response(status_code, json=data, headers={"content-type": "application/json"})


def test_creates_flat_generation_body():
    seen = {}

    def handler(request):
        seen["body"] = json.loads(request.content.decode("utf-8"))
        return json_response({"data": {"id": "task_1", "status": "pending"}}, 201)

    client = Buble(
        api_key="sk_test",
        base_url="https://example.test",
        http_client=httpx.Client(transport=httpx.MockTransport(handler)),
    )

    result = client.generations.create(
        model="google/nano-banana",
        mode="text_to_image",
        prompt="A test image",
        aspect_ratio="1:1",
    )

    assert seen["body"] == {
        "model": "google/nano-banana",
        "mode": "text_to_image",
        "prompt": "A test image",
        "aspect_ratio": "1:1",
    }
    assert result["data"]["id"] == "task_1"


def test_wait_until_success():
    statuses = iter(["pending", "processing", "success"])

    def handler(request):
        status = next(statuses)
        return json_response({"data": {"id": "task_1", "status": status}})

    client = Buble(api_key="sk_test", http_client=httpx.Client(transport=httpx.MockTransport(handler)))

    result = client.generations.wait("task_1", interval=0.0, timeout=1.0)

    assert result["data"]["status"] == "success"

