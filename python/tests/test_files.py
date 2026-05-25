import httpx

from buble_ai import Buble


def test_upload_sends_multipart_fields():
    seen = {}

    def handler(request):
        body = request.content.decode("utf-8", errors="replace")
        seen["content_type"] = request.headers.get("content-type")
        seen["body"] = body
        return httpx.Response(
            201,
            json={
                "data": {
                    "object": "file",
                    "provider": "r2",
                    "url": "https://cdn.example/file.png",
                    "key": "api/image/file.png",
                    "file_type": "image",
                    "content_type": "image/png",
                    "size": 4,
                    "filename": "file.png",
                }
            },
            headers={"content-type": "application/json"},
        )

    client = Buble(
        api_key="sk_test",
        base_url="https://example.test",
        http_client=httpx.Client(transport=httpx.MockTransport(handler)),
    )

    result = client.files.upload(
        b"test",
        file_type="image",
        filename="file.png",
        content_type="image/png",
        model="google/nano-banana",
        mode="image_to_image",
    )

    assert "multipart/form-data" in seen["content_type"]
    assert 'name="file_type"' in seen["body"]
    assert "image" in seen["body"]
    assert 'name="model"' in seen["body"]
    assert "google/nano-banana" in seen["body"]
    assert 'filename="file.png"' in seen["body"]
    assert result["data"]["url"] == "https://cdn.example/file.png"

