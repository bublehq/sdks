from __future__ import annotations

from typing import Literal, TypedDict

UploadFileType = Literal["image", "video", "audio"]


class UploadedFile(TypedDict):
    object: str
    provider: str
    url: str
    key: str
    file_type: UploadFileType
    content_type: str
    size: int
    filename: str


class UploadedFileEnvelope(TypedDict):
    data: UploadedFile

