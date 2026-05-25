from __future__ import annotations

import os
from typing import Any, Dict, Iterator, Optional

import httpx

from ._errors import BubleAPIError, BubleTimeoutError

DEFAULT_BASE_URL = "https://buble.ai"
DEFAULT_TIMEOUT = 60.0


def _normalize_base_url(base_url: Optional[str]) -> str:
    return (base_url or DEFAULT_BASE_URL).rstrip("/")


def _api_error_from_response(response: httpx.Response) -> BubleAPIError:
    code = None
    message = response.reason_phrase or "Buble API request failed."
    details = None

    try:
      body = response.json()
    except ValueError:
      body = None

    if isinstance(body, dict) and isinstance(body.get("error"), dict):
        error = body["error"]
        code = error.get("code")
        message = error.get("message") or message
        details = error.get("details")
    elif response.text:
        message = response.text

    return BubleAPIError(
        message,
        status_code=response.status_code,
        code=code,
        details=details,
        response=response,
    )


class _BaseHTTP:
    def __init__(
        self,
        *,
        api_key: Optional[str] = None,
        base_url: Optional[str] = None,
        timeout: float = DEFAULT_TIMEOUT,
        headers: Optional[Dict[str, str]] = None,
    ) -> None:
        resolved_api_key = api_key or os.environ.get("BUBLE_API_KEY")
        if not resolved_api_key:
            raise ValueError("Missing Buble API key. Pass api_key or set BUBLE_API_KEY.")

        self.api_key = resolved_api_key
        self.base_url = _normalize_base_url(base_url or os.environ.get("BUBLE_BASE_URL"))
        self.timeout = timeout
        self.headers = headers or {}

    def url(self, path: str) -> str:
        return f"{self.base_url}{path if path.startswith('/') else '/' + path}"

    def request_headers(self, extra: Optional[Dict[str, str]] = None) -> Dict[str, str]:
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Accept": "application/json",
            **self.headers,
        }
        if extra:
            headers.update(extra)
        return headers


class BubleHTTPClient(_BaseHTTP):
    def __init__(
        self,
        *,
        api_key: Optional[str] = None,
        base_url: Optional[str] = None,
        timeout: float = DEFAULT_TIMEOUT,
        headers: Optional[Dict[str, str]] = None,
        client: Optional[httpx.Client] = None,
    ) -> None:
        super().__init__(api_key=api_key, base_url=base_url, timeout=timeout, headers=headers)
        self.client = client or httpx.Client(timeout=timeout)
        self._owns_client = client is None

    def close(self) -> None:
        if self._owns_client:
            self.client.close()

    def request(
        self,
        method: str,
        path: str,
        *,
        params: Optional[Dict[str, Any]] = None,
        json: Any = None,
        data: Any = None,
        files: Any = None,
        headers: Optional[Dict[str, str]] = None,
        timeout: Optional[float] = None,
    ) -> Any:
        try:
            response = self.client.request(
                method,
                self.url(path),
                params=params,
                json=json,
                data=data,
                files=files,
                headers=self.request_headers(headers),
                timeout=timeout or self.timeout,
            )
        except httpx.TimeoutException as exc:
            raise BubleTimeoutError(
                f"Buble API request timed out after {timeout or self.timeout}s.",
                timeout=timeout or self.timeout,
            ) from exc

        if response.status_code >= 400:
            raise _api_error_from_response(response)

        if response.status_code == 204:
            return None
        content_type = response.headers.get("content-type", "")
        if "application/json" in content_type:
            return response.json()
        return response.text

    def stream(
        self,
        method: str,
        path: str,
        *,
        json: Any = None,
        headers: Optional[Dict[str, str]] = None,
        timeout: Optional[float] = None,
    ) -> Iterator[str]:
        try:
            with self.client.stream(
                method,
                self.url(path),
                json=json,
                headers=self.request_headers({"Accept": "text/event-stream", **(headers or {})}),
                timeout=timeout or self.timeout,
            ) as response:
                if response.status_code >= 400:
                    response.read()
                    raise _api_error_from_response(response)
                for line in response.iter_lines():
                    yield line
        except httpx.TimeoutException as exc:
            raise BubleTimeoutError(
                f"Buble API stream timed out after {timeout or self.timeout}s.",
                timeout=timeout or self.timeout,
            ) from exc


class AsyncBubleHTTPClient(_BaseHTTP):
    def __init__(
        self,
        *,
        api_key: Optional[str] = None,
        base_url: Optional[str] = None,
        timeout: float = DEFAULT_TIMEOUT,
        headers: Optional[Dict[str, str]] = None,
        client: Optional[httpx.AsyncClient] = None,
    ) -> None:
        super().__init__(api_key=api_key, base_url=base_url, timeout=timeout, headers=headers)
        self.client = client or httpx.AsyncClient(timeout=timeout)
        self._owns_client = client is None

    async def close(self) -> None:
        if self._owns_client:
            await self.client.aclose()

    async def request(
        self,
        method: str,
        path: str,
        *,
        params: Optional[Dict[str, Any]] = None,
        json: Any = None,
        data: Any = None,
        files: Any = None,
        headers: Optional[Dict[str, str]] = None,
        timeout: Optional[float] = None,
    ) -> Any:
        try:
            response = await self.client.request(
                method,
                self.url(path),
                params=params,
                json=json,
                data=data,
                files=files,
                headers=self.request_headers(headers),
                timeout=timeout or self.timeout,
            )
        except httpx.TimeoutException as exc:
            raise BubleTimeoutError(
                f"Buble API request timed out after {timeout or self.timeout}s.",
                timeout=timeout or self.timeout,
            ) from exc

        if response.status_code >= 400:
            raise _api_error_from_response(response)

        if response.status_code == 204:
            return None
        content_type = response.headers.get("content-type", "")
        if "application/json" in content_type:
            return response.json()
        return response.text

    async def stream(
        self,
        method: str,
        path: str,
        *,
        json: Any = None,
        headers: Optional[Dict[str, str]] = None,
        timeout: Optional[float] = None,
    ):
        try:
            async with self.client.stream(
                method,
                self.url(path),
                json=json,
                headers=self.request_headers({"Accept": "text/event-stream", **(headers or {})}),
                timeout=timeout or self.timeout,
            ) as response:
                if response.status_code >= 400:
                    await response.aread()
                    raise _api_error_from_response(response)
                async for line in response.aiter_lines():
                    yield line
        except httpx.TimeoutException as exc:
            raise BubleTimeoutError(
                f"Buble API stream timed out after {timeout or self.timeout}s.",
                timeout=timeout or self.timeout,
            ) from exc

