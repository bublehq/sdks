from __future__ import annotations

from typing import Any, Dict, List, Optional, TypedDict


class ChatModel(TypedDict, total=False):
    id: str
    object: str
    created: int
    owned_by: str
    name: str
    description: str
    capabilities: Dict[str, Any]
    tags: List[str]


class ChatModelList(TypedDict):
    object: str
    data: List[ChatModel]


class SSEEvent(TypedDict, total=False):
    event: str
    data: str
    json: Any

