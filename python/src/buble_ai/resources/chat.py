from __future__ import annotations

from typing import Any, AsyncIterator, Dict, Iterator, Optional
from urllib.parse import quote

from .._http import AsyncBubleHTTPClient, BubleHTTPClient
from .._streaming import parse_async_sse_lines, parse_sse_lines, text_from_event
from ..types.chat import ChatModelList, SSEEvent


def _encode_model_path(model: str) -> str:
    return "/".join(quote(part, safe="") for part in model.split("/"))


class ChatModelsResource:
    def __init__(self, http: BubleHTTPClient) -> None:
        self._http = http

    def list(self, *, timeout: Optional[float] = None) -> ChatModelList:
        return self._http.request("GET", "/api/v1/models", timeout=timeout)


class ChatCompletionsResource:
    def __init__(self, http: BubleHTTPClient) -> None:
        self._http = http

    def create(self, body: Optional[Dict[str, Any]] = None, *, timeout: Optional[float] = None, **params: Any) -> Dict[str, Any]:
        payload = body.copy() if body else {}
        payload.update(params)
        payload["stream"] = False
        return self._http.request("POST", "/api/v1/chat/completions", json=payload, timeout=timeout)

    def stream(self, body: Optional[Dict[str, Any]] = None, *, timeout: Optional[float] = None, **params: Any) -> Iterator[SSEEvent]:
        payload = body.copy() if body else {}
        payload.update(params)
        payload["stream"] = True
        return parse_sse_lines(self._http.stream("POST", "/api/v1/chat/completions", json=payload, timeout=timeout))

    def stream_text(self, body: Optional[Dict[str, Any]] = None, *, timeout: Optional[float] = None, **params: Any) -> Iterator[str]:
        for event in self.stream(body, timeout=timeout, **params):
            text = text_from_event(event, "openai")
            if text:
                yield text


class MessagesResource:
    def __init__(self, http: BubleHTTPClient) -> None:
        self._http = http

    def create(self, body: Optional[Dict[str, Any]] = None, *, timeout: Optional[float] = None, **params: Any) -> Dict[str, Any]:
        payload = body.copy() if body else {}
        payload.update(params)
        payload["stream"] = False
        return self._http.request("POST", "/api/v1/messages", json=payload, timeout=timeout)

    def stream(self, body: Optional[Dict[str, Any]] = None, *, timeout: Optional[float] = None, **params: Any) -> Iterator[SSEEvent]:
        payload = body.copy() if body else {}
        payload.update(params)
        payload["stream"] = True
        return parse_sse_lines(self._http.stream("POST", "/api/v1/messages", json=payload, timeout=timeout))

    def stream_text(self, body: Optional[Dict[str, Any]] = None, *, timeout: Optional[float] = None, **params: Any) -> Iterator[str]:
        for event in self.stream(body, timeout=timeout, **params):
            text = text_from_event(event, "anthropic")
            if text:
                yield text


class GeminiResource:
    def __init__(self, http: BubleHTTPClient) -> None:
        self._http = http

    def generate_content(
        self, model: str, body: Optional[Dict[str, Any]] = None, *, timeout: Optional[float] = None, **params: Any
    ) -> Dict[str, Any]:
        payload = body.copy() if body else {}
        payload.update(params)
        return self._http.request(
            "POST",
            f"/api/v1beta/models/{_encode_model_path(model)}:generateContent",
            json=payload,
            timeout=timeout,
        )

    def stream_generate_content(
        self, model: str, body: Optional[Dict[str, Any]] = None, *, timeout: Optional[float] = None, **params: Any
    ) -> Iterator[SSEEvent]:
        payload = body.copy() if body else {}
        payload.update(params)
        return parse_sse_lines(
            self._http.stream(
                "POST",
                f"/api/v1beta/models/{_encode_model_path(model)}:streamGenerateContent",
                json=payload,
                timeout=timeout,
            )
        )

    def stream_text(
        self, model: str, body: Optional[Dict[str, Any]] = None, *, timeout: Optional[float] = None, **params: Any
    ) -> Iterator[str]:
        for event in self.stream_generate_content(model, body, timeout=timeout, **params):
            text = text_from_event(event, "gemini")
            if text:
                yield text


class ChatResource:
    def __init__(self, http: BubleHTTPClient) -> None:
        self.models = ChatModelsResource(http)
        self.completions = ChatCompletionsResource(http)
        self.messages = MessagesResource(http)
        self.gemini = GeminiResource(http)


class AsyncChatModelsResource:
    def __init__(self, http: AsyncBubleHTTPClient) -> None:
        self._http = http

    async def list(self, *, timeout: Optional[float] = None) -> ChatModelList:
        return await self._http.request("GET", "/api/v1/models", timeout=timeout)


class AsyncChatCompletionsResource:
    def __init__(self, http: AsyncBubleHTTPClient) -> None:
        self._http = http

    async def create(self, body: Optional[Dict[str, Any]] = None, *, timeout: Optional[float] = None, **params: Any) -> Dict[str, Any]:
        payload = body.copy() if body else {}
        payload.update(params)
        payload["stream"] = False
        return await self._http.request("POST", "/api/v1/chat/completions", json=payload, timeout=timeout)

    async def stream(
        self, body: Optional[Dict[str, Any]] = None, *, timeout: Optional[float] = None, **params: Any
    ) -> AsyncIterator[SSEEvent]:
        payload = body.copy() if body else {}
        payload.update(params)
        payload["stream"] = True
        async for event in parse_async_sse_lines(
            self._http.stream("POST", "/api/v1/chat/completions", json=payload, timeout=timeout)
        ):
            yield event

    async def stream_text(
        self, body: Optional[Dict[str, Any]] = None, *, timeout: Optional[float] = None, **params: Any
    ) -> AsyncIterator[str]:
        async for event in self.stream(body, timeout=timeout, **params):
            text = text_from_event(event, "openai")
            if text:
                yield text


class AsyncMessagesResource:
    def __init__(self, http: AsyncBubleHTTPClient) -> None:
        self._http = http

    async def create(self, body: Optional[Dict[str, Any]] = None, *, timeout: Optional[float] = None, **params: Any) -> Dict[str, Any]:
        payload = body.copy() if body else {}
        payload.update(params)
        payload["stream"] = False
        return await self._http.request("POST", "/api/v1/messages", json=payload, timeout=timeout)

    async def stream(
        self, body: Optional[Dict[str, Any]] = None, *, timeout: Optional[float] = None, **params: Any
    ) -> AsyncIterator[SSEEvent]:
        payload = body.copy() if body else {}
        payload.update(params)
        payload["stream"] = True
        async for event in parse_async_sse_lines(
            self._http.stream("POST", "/api/v1/messages", json=payload, timeout=timeout)
        ):
            yield event

    async def stream_text(
        self, body: Optional[Dict[str, Any]] = None, *, timeout: Optional[float] = None, **params: Any
    ) -> AsyncIterator[str]:
        async for event in self.stream(body, timeout=timeout, **params):
            text = text_from_event(event, "anthropic")
            if text:
                yield text


class AsyncGeminiResource:
    def __init__(self, http: AsyncBubleHTTPClient) -> None:
        self._http = http

    async def generate_content(
        self, model: str, body: Optional[Dict[str, Any]] = None, *, timeout: Optional[float] = None, **params: Any
    ) -> Dict[str, Any]:
        payload = body.copy() if body else {}
        payload.update(params)
        return await self._http.request(
            "POST",
            f"/api/v1beta/models/{_encode_model_path(model)}:generateContent",
            json=payload,
            timeout=timeout,
        )

    async def stream_generate_content(
        self, model: str, body: Optional[Dict[str, Any]] = None, *, timeout: Optional[float] = None, **params: Any
    ) -> AsyncIterator[SSEEvent]:
        payload = body.copy() if body else {}
        payload.update(params)
        async for event in parse_async_sse_lines(
            self._http.stream(
                "POST",
                f"/api/v1beta/models/{_encode_model_path(model)}:streamGenerateContent",
                json=payload,
                timeout=timeout,
            )
        ):
            yield event

    async def stream_text(
        self, model: str, body: Optional[Dict[str, Any]] = None, *, timeout: Optional[float] = None, **params: Any
    ) -> AsyncIterator[str]:
        async for event in self.stream_generate_content(model, body, timeout=timeout, **params):
            text = text_from_event(event, "gemini")
            if text:
                yield text


class AsyncChatResource:
    def __init__(self, http: AsyncBubleHTTPClient) -> None:
        self.models = AsyncChatModelsResource(http)
        self.completions = AsyncChatCompletionsResource(http)
        self.messages = AsyncMessagesResource(http)
        self.gemini = AsyncGeminiResource(http)

