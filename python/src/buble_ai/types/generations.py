from __future__ import annotations

from typing import List, Optional, TypedDict

from .common import TaskStatus


class MediaResultImage(TypedDict):
    url: str


class MediaResultVideo(TypedDict, total=False):
    url: str
    preview_url: str
    thumbnail_url: str
    duration: object


class MediaResultAudio(TypedDict, total=False):
    url: str
    image_url: str
    title: str
    duration: object


class GenerationResult(TypedDict, total=False):
    images: List[MediaResultImage]
    videos: List[MediaResultVideo]
    audios: List[MediaResultAudio]


class GenerationError(TypedDict, total=False):
    code: str
    message: str


class GenerationTask(TypedDict, total=False):
    id: str
    status: TaskStatus
    model: str
    media_type: str
    mode: str
    cost_credits: int
    created_at: object
    updated_at: object
    result: Optional[GenerationResult]
    error: GenerationError


class GenerationTaskEnvelope(TypedDict):
    data: GenerationTask

