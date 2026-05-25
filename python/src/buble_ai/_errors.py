from __future__ import annotations

from typing import Any, Optional


class BubleError(Exception):
    """Base exception for the Buble Python SDK."""


class BubleAPIError(BubleError):
    """Raised for non-2xx Buble API responses."""

    def __init__(
        self,
        message: str,
        *,
        status_code: int,
        code: Optional[str] = None,
        details: Any = None,
        response: Any = None,
    ) -> None:
        super().__init__(message)
        self.message = message
        self.status_code = status_code
        self.code = code
        self.details = details
        self.response = response


class BubleTimeoutError(BubleError):
    """Raised when a request or polling operation times out."""

    def __init__(self, message: str, *, timeout: float) -> None:
        super().__init__(message)
        self.timeout = timeout


class BubleGenerationError(BubleError):
    """Raised when a generation task reaches failed status."""

    def __init__(self, message: str, *, task: Any) -> None:
        super().__init__(message)
        self.task = task


class BubleCanceledError(BubleError):
    """Raised when a generation task reaches canceled status."""

    def __init__(self, message: str, *, task: Any) -> None:
        super().__init__(message)
        self.task = task

