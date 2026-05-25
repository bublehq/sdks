from __future__ import annotations

import json
from typing import Any, AsyncIterable, AsyncIterator, Iterable, Iterator, List, Optional

from .types.chat import SSEEvent


def _parse_json(data: str) -> Any:
    if not data or data == "[DONE]":
        return None
    try:
        return json.loads(data)
    except json.JSONDecodeError:
        return None


def _event_from_lines(lines: List[str]) -> Optional[SSEEvent]:
    event_name = None
    data_lines: List[str] = []

    for raw in lines:
        line = raw.rstrip("\r")
        if not line or line.startswith(":"):
            continue
        if ":" in line:
            field, value = line.split(":", 1)
            value = value[1:] if value.startswith(" ") else value
        else:
            field, value = line, ""

        if field == "event":
            event_name = value
        elif field == "data":
            data_lines.append(value)

    if not event_name and not data_lines:
        return None

    data = "\n".join(data_lines)
    event: SSEEvent = {"data": data}
    if event_name:
        event["event"] = event_name
    parsed = _parse_json(data)
    if parsed is not None:
        event["json"] = parsed
    return event


def parse_sse_lines(lines: Iterable[str]) -> Iterator[SSEEvent]:
    block: List[str] = []
    for line in lines:
        if line == "":
            event = _event_from_lines(block)
            block = []
            if event:
                yield event
            continue
        block.append(line)

    event = _event_from_lines(block)
    if event:
        yield event


async def parse_async_sse_lines(lines: AsyncIterable[str]) -> AsyncIterator[SSEEvent]:
    block: List[str] = []
    async for line in lines:
        if line == "":
            event = _event_from_lines(block)
            block = []
            if event:
                yield event
            continue
        block.append(line)

    event = _event_from_lines(block)
    if event:
        yield event


def text_from_event(event: SSEEvent, protocol: str) -> Optional[str]:
    if event.get("data") == "[DONE]":
        return None
    payload = event.get("json")
    if not isinstance(payload, dict):
        return None

    if protocol == "openai":
        choices = payload.get("choices")
        if isinstance(choices, list) and choices:
            delta = choices[0].get("delta") if isinstance(choices[0], dict) else None
            if isinstance(delta, dict) and isinstance(delta.get("content"), str):
                return delta["content"]

    if protocol == "anthropic" and event.get("event") == "content_block_delta":
        delta = payload.get("delta")
        if isinstance(delta, dict) and isinstance(delta.get("text"), str):
            return delta["text"]

    if protocol == "gemini":
        chunks: List[str] = []
        candidates = payload.get("candidates")
        if isinstance(candidates, list) and candidates:
            content = candidates[0].get("content") if isinstance(candidates[0], dict) else None
            parts = content.get("parts") if isinstance(content, dict) else None
            if isinstance(parts, list):
                for part in parts:
                    if isinstance(part, dict) and isinstance(part.get("text"), str):
                        chunks.append(part["text"])
        return "".join(chunks) if chunks else None

    return None

