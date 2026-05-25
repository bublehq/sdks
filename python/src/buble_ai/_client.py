from __future__ import annotations

from typing import Dict, Optional

import httpx

from ._http import AsyncBubleHTTPClient, BubleHTTPClient, DEFAULT_TIMEOUT
from .resources.apps import AppsResource, AsyncAppsResource
from .resources.chat import AsyncChatResource, ChatResource
from .resources.files import AsyncFilesResource, FilesResource
from .resources.generations import AsyncGenerationsResource, GenerationsResource
from .resources.media_models import AsyncMediaModelsResource, MediaModelsResource


class Buble:
    """Synchronous client for the Buble public API."""

    def __init__(
        self,
        *,
        api_key: Optional[str] = None,
        base_url: Optional[str] = None,
        timeout: float = DEFAULT_TIMEOUT,
        headers: Optional[Dict[str, str]] = None,
        http_client: Optional[httpx.Client] = None,
    ) -> None:
        self._http = BubleHTTPClient(
            api_key=api_key,
            base_url=base_url,
            timeout=timeout,
            headers=headers,
            client=http_client,
        )
        self.media_models = MediaModelsResource(self._http)
        self.files = FilesResource(self._http)
        self.generations = GenerationsResource(self._http)
        self.apps = AppsResource(self._http)
        self.chat = ChatResource(self._http)

    def close(self) -> None:
        self._http.close()

    def __enter__(self) -> "Buble":
        return self

    def __exit__(self, exc_type, exc, traceback) -> None:
        self.close()


class AsyncBuble:
    """Asynchronous client for the Buble public API."""

    def __init__(
        self,
        *,
        api_key: Optional[str] = None,
        base_url: Optional[str] = None,
        timeout: float = DEFAULT_TIMEOUT,
        headers: Optional[Dict[str, str]] = None,
        http_client: Optional[httpx.AsyncClient] = None,
    ) -> None:
        self._http = AsyncBubleHTTPClient(
            api_key=api_key,
            base_url=base_url,
            timeout=timeout,
            headers=headers,
            client=http_client,
        )
        self.media_models = AsyncMediaModelsResource(self._http)
        self.files = AsyncFilesResource(self._http)
        self.generations = AsyncGenerationsResource(self._http)
        self.apps = AsyncAppsResource(self._http)
        self.chat = AsyncChatResource(self._http)

    async def close(self) -> None:
        await self._http.close()

    async def __aenter__(self) -> "AsyncBuble":
        return self

    async def __aexit__(self, exc_type, exc, traceback) -> None:
        await self.close()

