import json

import httpx
import pytest

from buble_ai import AsyncBuble, Buble


def test_gemini_preserves_slash_model_path():
    seen = {}

    def handler(request):
        seen["url"] = str(request.url)
        return httpx.Response(200, json={"candidates": []}, headers={"content-type": "application/json"})

    client = Buble(
        api_key="sk_test",
        base_url="https://example.test",
        http_client=httpx.Client(transport=httpx.MockTransport(handler)),
    )

    client.chat.gemini.generate_content(
        "openai/gpt-5.5",
        contents=[{"role": "user", "parts": [{"text": "hi"}]}],
    )

    assert seen["url"] == "https://example.test/api/v1beta/models/openai/gpt-5.5:generateContent"


def test_openai_stream_text():
    def handler(request):
        body = "\n".join(
            [
                'data: {"choices":[{"delta":{"content":"Hel"}}]}',
                "",
                'data: {"choices":[{"delta":{"content":"lo"}}]}',
                "",
                "data: [DONE]",
                "",
                "",
            ]
        )
        return httpx.Response(200, content=body, headers={"content-type": "text/event-stream"})

    client = Buble(api_key="sk_test", http_client=httpx.Client(transport=httpx.MockTransport(handler)))

    assert "".join(client.chat.completions.stream_text(model="openai/gpt-5.5", messages=[])) == "Hello"


@pytest.mark.asyncio
async def test_async_chat_models():
    async def handler(request):
        return httpx.Response(200, json={"object": "list", "data": []}, headers={"content-type": "application/json"})

    async with AsyncBuble(
        api_key="sk_test",
        base_url="https://example.test",
        http_client=httpx.AsyncClient(transport=httpx.MockTransport(handler)),
    ) as client:
        result = await client.chat.models.list()

    assert result == {"object": "list", "data": []}

