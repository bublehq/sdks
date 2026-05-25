from __future__ import annotations

import asyncio
import time
from typing import Any, Dict, Optional

from .._errors import BubleCanceledError, BubleGenerationError, BubleTimeoutError
from .._http import AsyncBubleHTTPClient, BubleHTTPClient
from ..types.apps import AppGenerationTaskEnvelope, PublicAppEnvelope, PublicAppsEnvelope

TERMINAL_STATUSES = {"success", "failed", "canceled"}


class AppGenerationsResource:
    def __init__(self, http: BubleHTTPClient) -> None:
        self._http = http

    def create(self, app: str, body: Optional[Dict[str, Any]] = None, *, timeout: Optional[float] = None, **params: Any) -> AppGenerationTaskEnvelope:
        payload = body.copy() if body else {}
        payload.update(params)
        return self._http.request("POST", f"/api/v1/apps/{app}/generations", json=payload, timeout=timeout)

    def retrieve(self, app: str, task_id: str, *, timeout: Optional[float] = None) -> AppGenerationTaskEnvelope:
        return self._http.request("GET", f"/api/v1/apps/{app}/generations/{task_id}", timeout=timeout)

    def wait(
        self,
        app: str,
        task_id: str,
        *,
        interval: float = 2.0,
        timeout: float = 600.0,
        throw_on_failed: bool = True,
        throw_on_canceled: bool = True,
    ) -> AppGenerationTaskEnvelope:
        start = time.monotonic()
        while True:
            if time.monotonic() - start > timeout:
                raise BubleTimeoutError(f"App generation {task_id} did not finish within {timeout}s.", timeout=timeout)

            envelope = self.retrieve(app, task_id)
            task = envelope["data"]
            status = task.get("status")
            if status in TERMINAL_STATUSES:
                if status == "failed" and throw_on_failed:
                    error = task.get("error") or {}
                    raise BubleGenerationError(error.get("message") or "App generation failed.", task=task)
                if status == "canceled" and throw_on_canceled:
                    raise BubleCanceledError(f"App generation {task_id} was canceled.", task=task)
                return envelope

            time.sleep(interval)


class AppsResource:
    def __init__(self, http: BubleHTTPClient) -> None:
        self._http = http
        self.generations = AppGenerationsResource(http)

    def list(
        self, *, page: Optional[int] = None, limit: Optional[int] = None, timeout: Optional[float] = None
    ) -> PublicAppsEnvelope:
        params = {key: value for key, value in {"page": page, "limit": limit}.items() if value is not None}
        return self._http.request("GET", "/api/v1/apps", params=params or None, timeout=timeout)

    def retrieve(self, app: str, *, timeout: Optional[float] = None) -> PublicAppEnvelope:
        return self._http.request("GET", f"/api/v1/apps/{app}", timeout=timeout)


class AsyncAppGenerationsResource:
    def __init__(self, http: AsyncBubleHTTPClient) -> None:
        self._http = http

    async def create(
        self, app: str, body: Optional[Dict[str, Any]] = None, *, timeout: Optional[float] = None, **params: Any
    ) -> AppGenerationTaskEnvelope:
        payload = body.copy() if body else {}
        payload.update(params)
        return await self._http.request("POST", f"/api/v1/apps/{app}/generations", json=payload, timeout=timeout)

    async def retrieve(self, app: str, task_id: str, *, timeout: Optional[float] = None) -> AppGenerationTaskEnvelope:
        return await self._http.request("GET", f"/api/v1/apps/{app}/generations/{task_id}", timeout=timeout)

    async def wait(
        self,
        app: str,
        task_id: str,
        *,
        interval: float = 2.0,
        timeout: float = 600.0,
        throw_on_failed: bool = True,
        throw_on_canceled: bool = True,
    ) -> AppGenerationTaskEnvelope:
        start = time.monotonic()
        while True:
            if time.monotonic() - start > timeout:
                raise BubleTimeoutError(f"App generation {task_id} did not finish within {timeout}s.", timeout=timeout)

            envelope = await self.retrieve(app, task_id)
            task = envelope["data"]
            status = task.get("status")
            if status in TERMINAL_STATUSES:
                if status == "failed" and throw_on_failed:
                    error = task.get("error") or {}
                    raise BubleGenerationError(error.get("message") or "App generation failed.", task=task)
                if status == "canceled" and throw_on_canceled:
                    raise BubleCanceledError(f"App generation {task_id} was canceled.", task=task)
                return envelope

            await asyncio.sleep(interval)


class AsyncAppsResource:
    def __init__(self, http: AsyncBubleHTTPClient) -> None:
        self._http = http
        self.generations = AsyncAppGenerationsResource(http)

    async def list(
        self, *, page: Optional[int] = None, limit: Optional[int] = None, timeout: Optional[float] = None
    ) -> PublicAppsEnvelope:
        params = {key: value for key, value in {"page": page, "limit": limit}.items() if value is not None}
        return await self._http.request("GET", "/api/v1/apps", params=params or None, timeout=timeout)

    async def retrieve(self, app: str, *, timeout: Optional[float] = None) -> PublicAppEnvelope:
        return await self._http.request("GET", f"/api/v1/apps/{app}", timeout=timeout)

