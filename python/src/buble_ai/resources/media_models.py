from __future__ import annotations

from typing import Optional

from .._http import AsyncBubleHTTPClient, BubleHTTPClient
from ..types.media import MediaModelsEnvelope


class MediaModelsResource:
    def __init__(self, http: BubleHTTPClient) -> None:
        self._http = http

    def list(self, *, media_type: Optional[str] = None, timeout: Optional[float] = None) -> MediaModelsEnvelope:
        params = {"media_type": media_type} if media_type else None
        return self._http.request("GET", "/api/v1/media_models", params=params, timeout=timeout)


class AsyncMediaModelsResource:
    def __init__(self, http: AsyncBubleHTTPClient) -> None:
        self._http = http

    async def list(
        self, *, media_type: Optional[str] = None, timeout: Optional[float] = None
    ) -> MediaModelsEnvelope:
        params = {"media_type": media_type} if media_type else None
        return await self._http.request("GET", "/api/v1/media_models", params=params, timeout=timeout)

