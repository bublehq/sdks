from __future__ import annotations

import asyncio
import time
from typing import Any, Dict, List, Optional

from .._errors import BubleCanceledError, BubleGenerationError, BubleTimeoutError
from .._http import AsyncBubleHTTPClient, BubleHTTPClient
from ..types.generations import GenerationTaskEnvelope

FORBIDDEN_GENERATION_FIELDS = {
    "input",
    "options",
    "scene",
    "sub_mode_id",
    "provider",
    "mediaType",
    "media_type",
    "images",
    "image_input",
    "video_input",
    "audio_input",
}

TERMINAL_STATUSES = {"success", "failed", "canceled"}


def _compact_body(body: Dict[str, Any]) -> Dict[str, Any]:
    return {key: value for key, value in body.items() if value is not None}


def _assert_public_generation_body(body: Dict[str, Any]) -> None:
    forbidden = FORBIDDEN_GENERATION_FIELDS.intersection(body.keys())
    if forbidden:
        field = sorted(forbidden)[0]
        raise ValueError(f'Field "{field}" is an internal Buble field and is not supported by the public API.')


class GenerationsResource:
    def __init__(self, http: BubleHTTPClient) -> None:
        self._http = http

    def create(
        self,
        *,
        model: str,
        mode: Optional[str] = None,
        prompt: Optional[str] = None,
        image_urls: Optional[List[str]] = None,
        start_frame: Optional[str] = None,
        end_frame: Optional[str] = None,
        video_urls: Optional[List[str]] = None,
        audio_urls: Optional[List[str]] = None,
        is_public: Optional[bool] = None,
        copy_protected: Optional[bool] = None,
        timeout: Optional[float] = None,
        **params: Any,
    ) -> GenerationTaskEnvelope:
        body = _compact_body(
            {
                "model": model,
                "mode": mode,
                "prompt": prompt,
                "image_urls": image_urls,
                "start_frame": start_frame,
                "end_frame": end_frame,
                "video_urls": video_urls,
                "audio_urls": audio_urls,
                "is_public": is_public,
                "copy_protected": copy_protected,
                **params,
            }
        )
        _assert_public_generation_body(body)
        return self._http.request("POST", "/api/v1/generations", json=body, timeout=timeout)

    def retrieve(self, task_id: str, *, timeout: Optional[float] = None) -> GenerationTaskEnvelope:
        return self._http.request("GET", f"/api/v1/generations/{task_id}", timeout=timeout)

    def wait(
        self,
        task_id: str,
        *,
        interval: float = 2.0,
        timeout: float = 600.0,
        throw_on_failed: bool = True,
        throw_on_canceled: bool = True,
    ) -> GenerationTaskEnvelope:
        start = time.monotonic()
        while True:
            if time.monotonic() - start > timeout:
                raise BubleTimeoutError(f"Generation {task_id} did not finish within {timeout}s.", timeout=timeout)

            envelope = self.retrieve(task_id)
            task = envelope["data"]
            status = task.get("status")
            if status in TERMINAL_STATUSES:
                if status == "failed" and throw_on_failed:
                    error = task.get("error") or {}
                    raise BubleGenerationError(error.get("message") or "Generation failed.", task=task)
                if status == "canceled" and throw_on_canceled:
                    raise BubleCanceledError(f"Generation {task_id} was canceled.", task=task)
                return envelope

            time.sleep(interval)


class AsyncGenerationsResource:
    def __init__(self, http: AsyncBubleHTTPClient) -> None:
        self._http = http

    async def create(
        self,
        *,
        model: str,
        mode: Optional[str] = None,
        prompt: Optional[str] = None,
        image_urls: Optional[List[str]] = None,
        start_frame: Optional[str] = None,
        end_frame: Optional[str] = None,
        video_urls: Optional[List[str]] = None,
        audio_urls: Optional[List[str]] = None,
        is_public: Optional[bool] = None,
        copy_protected: Optional[bool] = None,
        timeout: Optional[float] = None,
        **params: Any,
    ) -> GenerationTaskEnvelope:
        body = _compact_body(
            {
                "model": model,
                "mode": mode,
                "prompt": prompt,
                "image_urls": image_urls,
                "start_frame": start_frame,
                "end_frame": end_frame,
                "video_urls": video_urls,
                "audio_urls": audio_urls,
                "is_public": is_public,
                "copy_protected": copy_protected,
                **params,
            }
        )
        _assert_public_generation_body(body)
        return await self._http.request("POST", "/api/v1/generations", json=body, timeout=timeout)

    async def retrieve(self, task_id: str, *, timeout: Optional[float] = None) -> GenerationTaskEnvelope:
        return await self._http.request("GET", f"/api/v1/generations/{task_id}", timeout=timeout)

    async def wait(
        self,
        task_id: str,
        *,
        interval: float = 2.0,
        timeout: float = 600.0,
        throw_on_failed: bool = True,
        throw_on_canceled: bool = True,
    ) -> GenerationTaskEnvelope:
        start = time.monotonic()
        while True:
            if time.monotonic() - start > timeout:
                raise BubleTimeoutError(f"Generation {task_id} did not finish within {timeout}s.", timeout=timeout)

            envelope = await self.retrieve(task_id)
            task = envelope["data"]
            status = task.get("status")
            if status in TERMINAL_STATUSES:
                if status == "failed" and throw_on_failed:
                    error = task.get("error") or {}
                    raise BubleGenerationError(error.get("message") or "Generation failed.", task=task)
                if status == "canceled" and throw_on_canceled:
                    raise BubleCanceledError(f"Generation {task_id} was canceled.", task=task)
                return envelope

            await asyncio.sleep(interval)

