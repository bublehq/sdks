import json

import httpx
import pytest

from buble_ai import Buble, BubleAPIError


def json_response(data, status_code=200):
    return httpx.Response(status_code, json=data, headers={"content-type": "application/json"})


def test_adds_bearer_auth_and_preserves_chat_model_shape():
    seen = {}

    def handler(request):
        seen["url"] = str(request.url)
        seen["auth"] = request.headers.get("authorization")
        return json_response({"object": "list", "data": []})

    client = Buble(
        api_key="sk_test",
        base_url="https://example.test",
        http_client=httpx.Client(transport=httpx.MockTransport(handler)),
    )

    result = client.chat.models.list()

    assert result == {"object": "list", "data": []}
    assert seen["url"] == "https://example.test/api/v1/models"
    assert seen["auth"] == "Bearer sk_test"


def test_parses_api_errors():
    def handler(request):
        return json_response({"error": {"code": "invalid_api_key", "message": "Invalid API key."}}, 401)

    client = Buble(api_key="sk_test", http_client=httpx.Client(transport=httpx.MockTransport(handler)))

    with pytest.raises(BubleAPIError) as exc:
        client.media_models.list()

    assert exc.value.status_code == 401
    assert exc.value.code == "invalid_api_key"
    assert exc.value.message == "Invalid API key."


def test_rejects_internal_generation_fields_before_request():
    called = False

    def handler(request):
        nonlocal called
        called = True
        return json_response({})

    client = Buble(api_key="sk_test", http_client=httpx.Client(transport=httpx.MockTransport(handler)))

    with pytest.raises(ValueError, match="options"):
        client.generations.create(
            model="google/nano-banana",
            mode="text_to_image",
            prompt="test",
            options={},
        )

    assert called is False

