from __future__ import annotations

from typing import Any, List, Optional, TypedDict


class MediaModelParameter(TypedDict, total=False):
    name: str
    type: str
    label: str
    default: Any
    values: List[Any]
    min: float
    max: float
    step: float
    required: bool


class MediaModelOperation(TypedDict, total=False):
    mode: str
    input: dict
    parameters: List[MediaModelParameter]


class MediaModel(TypedDict, total=False):
    model: str
    name: str
    media_type: str
    operations: List[MediaModelOperation]


class MediaModelsEnvelope(TypedDict):
    data: List[MediaModel]

