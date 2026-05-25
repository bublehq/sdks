from __future__ import annotations

from typing import Any, List, TypedDict

from .generations import GenerationResult
from .common import TaskStatus


class AppInputParameter(TypedDict, total=False):
    name: str
    type: str
    values: List[Any]


class PublicApp(TypedDict):
    id: str
    input_parameters: List[AppInputParameter]


class PublicAppsEnvelope(TypedDict):
    data: List[PublicApp]


class PublicAppEnvelope(TypedDict):
    data: PublicApp


class AppGenerationTask(TypedDict, total=False):
    id: str
    status: TaskStatus
    result: GenerationResult
    error: dict


class AppGenerationTaskEnvelope(TypedDict):
    data: AppGenerationTask

