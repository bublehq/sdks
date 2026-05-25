from __future__ import annotations

from typing import Optional

from .._files import FileInput, prepare_upload
from .._http import AsyncBubleHTTPClient, BubleHTTPClient
from ..types.files import UploadedFileEnvelope


class FilesResource:
    def __init__(self, http: BubleHTTPClient) -> None:
        self._http = http

    def upload(
        self,
        file: FileInput,
        *,
        file_type: Optional[str] = None,
        model: Optional[str] = None,
        mode: Optional[str] = None,
        filename: Optional[str] = None,
        content_type: Optional[str] = None,
        timeout: Optional[float] = None,
    ) -> UploadedFileEnvelope:
        upload = prepare_upload(file, filename=filename, content_type=content_type)
        data = {
            key: value
            for key, value in {
                "file_type": file_type,
                "model": model,
                "mode": mode,
            }.items()
            if value is not None
        }
        try:
            return self._http.request("POST", "/api/v1/files", data=data, files=upload.files, timeout=timeout)
        finally:
            upload.close()


class AsyncFilesResource:
    def __init__(self, http: AsyncBubleHTTPClient) -> None:
        self._http = http

    async def upload(
        self,
        file: FileInput,
        *,
        file_type: Optional[str] = None,
        model: Optional[str] = None,
        mode: Optional[str] = None,
        filename: Optional[str] = None,
        content_type: Optional[str] = None,
        timeout: Optional[float] = None,
    ) -> UploadedFileEnvelope:
        upload = prepare_upload(file, filename=filename, content_type=content_type)
        data = {
            key: value
            for key, value in {
                "file_type": file_type,
                "model": model,
                "mode": mode,
            }.items()
            if value is not None
        }
        try:
            return await self._http.request("POST", "/api/v1/files", data=data, files=upload.files, timeout=timeout)
        finally:
            upload.close()

