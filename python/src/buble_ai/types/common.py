from __future__ import annotations

from typing import Any, Dict, Literal, Optional, TypedDict

JsonDict = Dict[str, Any]
MediaType = Literal["image", "video", "audio"]
TaskStatus = Literal["pending", "processing", "success", "failed", "canceled"]


class APIEnvelope(TypedDict):
    data: Any


class APIErrorBody(TypedDict, total=False):
    code: str
    message: str
    details: Any


class RequestOptions(TypedDict, total=False):
    timeout: float


class WaitOptions(TypedDict, total=False):
    interval: float
    timeout: float
    throw_on_failed: bool
    throw_on_canceled: bool

